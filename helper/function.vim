" ~/.vim/helper/function.vim
"
" Vim Editing Helpers
"
" Function / method / subroutine commenting helpers.
"
" Commands:
"
"   :Cf    Comment the function/method/subroutine containing
"          the current cursor position.
"
"   :Uf    Uncomment the function/method/subroutine containing
"          the current cursor position.
"
" This module depends on GetCommentStyle() from style.vim
" and the line/block commenting functions provided by the
" other helper modules.
"
" IMPORTANT:
"
" Cf and Uf intentionally use separate detection paths.
"
" Cf detects the actual programming-language function.
"
" Uf detects a commented function without treating every
" contiguous comment above or below it as part of the function.
"
" This prevents documentation/comments immediately preceding
" a commented function from being accidentally uncommented.
"
" User-defined Vim commands must begin with an uppercase
" letter.
"


" ============================================================
" FUNCTION DETECTION
"
" Used by Cf.
"
" Returns:
"
"   [start_line, end_line]
"
" for the function surrounding the current cursor position.
"
" The implementation is language-aware.
" ============================================================

function! FindFunctionRange() abort
  let ft = &filetype

  if ft ==# 'python'
    return FindPythonFunction()
  endif

  if index([
        \ 'sh',
        \ 'bash',
        \ 'zsh',
        \ 'ksh'
        \ ], ft) >= 0
    return FindShellFunction()
  endif

  if ft ==# 'perl'
    return FindPerlFunction()
  endif

  if ft ==# 'vim'
    return FindVimFunction()
  endif

  " C-like languages.
  if index([
        \ 'c',
        \ 'cpp',
        \ 'cxx',
        \ 'cc',
        \ 'objc',
        \ 'java',
        \ 'javascript',
        \ 'typescript',
        \ 'css',
        \ 'scss',
        \ 'less',
        \ 'php',
        \ 'go',
        \ 'rust',
        \ 'kotlin',
        \ 'swift',
        \ 'scala'
        \ ], ft) >= 0
    return FindBraceFunction()
  endif

  " Unknown language: attempt brace-based detection.
  return FindBraceFunction()
endfunction


" ============================================================
" PYTHON FUNCTION DETECTION
"
" Python functions are indentation based.
" ============================================================

function! FindPythonFunction() abort
  let current = line('.')
  let start = 0
  let function_indent = -1

  " Search upward for the nearest enclosing def/class.
  for lnum in reverse(range(1, current))
    let text = getline(lnum)

    if text =~# '^\s*\(async\s\+\)\?def\s\+\w\+'
      let start = lnum
      let function_indent = indent(lnum)
      break
    endif

    if text =~# '^\s*class\s\+\w\+'
      if start == 0
        let start = lnum
        let function_indent = indent(lnum)
      endif
      break
    endif
  endfor

  if start == 0
    let text = getline(current)

    if text =~# '^\s*\(async\s\+\)\?def\s\+\w\+'
      let start = current
      let function_indent = indent(current)
    else
      return []
    endif
  endif

  " If we found a class rather than a def, look downward for
  " the method containing the cursor.
  if getline(start) =~# '^\s*class\s\+'
    for lnum in range(start + 1, current)
      if getline(lnum) =~# '^\s*\(async\s\+\)\?def\s\+\w\+'
        let start = lnum
        let function_indent = indent(lnum)
      endif
    endfor
  endif

  let finish = start

  for lnum in range(start + 1, line('$'))
    let text = getline(lnum)

    " Blank lines belong to the function.
    if text =~# '^\s*$'
      let finish = lnum
      continue
    endif

    " A line at the same or lesser indentation ends the function.
    if indent(lnum) <= function_indent
      break
    endif

    let finish = lnum
  endfor

  return [start, finish]
endfunction


" ============================================================
" SHELL FUNCTION DETECTION
"
" Supports:
"
"   function foo() {
"       ...
"   }
"
" and:
"
"   foo() {
"       ...
"   }
"
" Also handles braces appearing on subsequent lines.
" ============================================================

function! FindShellFunction() abort
  let current = line('.')
  let start = 0

  " Find the nearest function declaration above the cursor.
  for lnum in reverse(range(1, current))
    let text = getline(lnum)

    if text =~# '^\s*function\s\+\w\+'
          \ || text =~# '^\s*\w\+\s*()\s*{'
      let start = lnum
      break
    endif
  endfor

  " Current line may be the declaration.
  if start == 0
    let text = getline(current)

    if text =~# '^\s*function\s\+\w\+'
          \ || text =~# '^\s*\w\+\s*()\s*{'
      let start = current
    else
      return []
    endif
  endif

  return FindBraceRange(start)
endfunction


" ============================================================
" PERL FUNCTION DETECTION
"
" Supports:
"
"   sub foo {
"       ...
"   }
" ============================================================

function! FindPerlFunction() abort
  let current = line('.')
  let start = 0

  for lnum in reverse(range(1, current))
    if getline(lnum) =~# '^\s*sub\s\+\w\+'
      let start = lnum
      break
    endif
  endfor

  if start == 0 && getline(current) =~# '^\s*sub\s\+\w\+'
    let start = current
  endif

  if start == 0
    return []
  endif

  return FindBraceRange(start)
endfunction


" ============================================================
" VIM FUNCTION DETECTION
"
" Supports:
"
"   function! Foo()
"       ...
"   endfunction
" ============================================================

function! FindVimFunction() abort
  let current = line('.')
  let start = 0

  for lnum in reverse(range(1, current))
    if getline(lnum) =~# '^\s*fu\%[nction]!\?\>'
      let start = lnum
      break
    endif
  endfor

  if start == 0 && getline(current) =~# '^\s*fu\%[nction]!\?\>'
    let start = current
  endif

  if start == 0
    return []
  endif

  let finish = start

  for lnum in range(start + 1, line('$'))
    if getline(lnum) =~# '^\s*endf\%[unction]\>'
      let finish = lnum
      break
    endif
  endfor

  return [start, finish]
endfunction


" ============================================================
" BRACE-BASED FUNCTION DETECTION
"
" Used for C, C++, Java, JavaScript, CSS, Go, Rust, etc.
"
" The function range is determined by balancing { and }.
" ============================================================

function! FindBraceFunction() abort
  let current = line('.')
  let start = 0

  " Search upward for a line that looks like a function
  " declaration.
  for lnum in reverse(range(1, current))
    let text = getline(lnum)

    if text =~# '\w\+\s*(.*)\s*{'
          \ || text =~# '^\s*\(function\|func\)\>'
          \ || text =~# '^\s*\(public\|private\|protected\|static\|async\)\+.*('
      let start = lnum
      break
    endif
  endfor

  if start == 0
    let text = getline(current)

    if text =~# '\w\+\s*(.*)\s*{'
          \ || text =~# '^\s*\(function\|func\)\>'
          \ || text =~# '^\s*\(public\|private\|protected\|static\|async\)\+.*('
      let start = current
    else
      return []
    endif
  endif

  return FindBraceRange(start)
endfunction


" ============================================================
" FIND BRACE RANGE
"
" Starts at a function declaration and counts braces until
" the matching closing brace is found.
"
" This allows Cf to operate on the ENTIRE function rather
" than merely the declaration line.
" ============================================================

function! FindBraceRange(start) abort
  let depth = 0
  let found_open = 0
  let finish = a:start

  for lnum in range(a:start, line('$'))
    let text = getline(lnum)

    " Remove simple quoted strings before counting braces.
    let clean = substitute(text, '"[^"]*"', '', 'g')
    let clean = substitute(clean, "'[^']*'", '', 'g')

    let opens = strlen(substitute(clean, '[^{]', '', 'g'))
    let closes = strlen(substitute(clean, '[^}]', '', 'g'))

    let depth += opens
    let depth -= closes

    if opens > 0
      let found_open = 1
    endif

    if found_open
      let finish = lnum
    endif

    if found_open && depth <= 0
      break
    endif
  endfor

  if !found_open
    return []
  endif

  return [a:start, finish]
endfunction


" ============================================================
" COMMENT FUNCTION
"
" :Cf
"
" Comments the entire function/method/subroutine containing
" the current cursor position.
"
" Cf continues to use the normal language-aware function
" detector.
" ============================================================

command! Cf call CommentFunction()

function! CommentFunction() abort
  let range = FindFunctionRange()

  if empty(range)
    echoerr 'Unable to determine function at current cursor position.'
    return
  endif

  call CommentLines(range[0], range[1])
endfunction


" ============================================================
" UNCOMMENT FUNCTION
"
" :Uf
"
" IMPORTANT:
"
" Uf does NOT use FindFunctionRange().
"
" Once Cf has commented a function, the original programming
" language structure may no longer be visible.
"
" More importantly, line-commented functions may have other
" comments immediately before them.
"
" Therefore Uf has a separate commented-function detector.
" ============================================================

command! Uf call UncommentFunction()

function! UncommentFunction() abort
  let range = FindCommentedFunctionRange()

  if empty(range)
    echoerr 'Unable to determine commented function at current cursor position.'
    return
  endif

  call UncommentLines(range[0], range[1])
endfunction


" ============================================================
" FIND COMMENTED FUNCTION RANGE
"
" Used exclusively by Uf.
"
" The goal is to recover the function that Cf commented
" without treating unrelated adjacent comments as part of
" that function.
"
" For line-comment languages, the detector looks for the
" function declaration inside the commented lines and then
" determines the function's boundary from indentation,
" braces, or language-specific terminators.
"
" For C-style comments, the comment itself provides the
" boundary.
" ============================================================

function! FindCommentedFunctionRange() abort
  let ft = &filetype

  " ----------------------------------------------------------
  " Vimscript
  " ----------------------------------------------------------

  if ft ==# 'vim'
    return FindCommentedVimFunction()
  endif


  " ----------------------------------------------------------
  " Python
  " ----------------------------------------------------------

  if ft ==# 'python'
    return FindCommentedPythonFunction()
  endif


  " ----------------------------------------------------------
  " Shell
  " ----------------------------------------------------------

  if index([
        \ 'sh',
        \ 'bash',
        \ 'zsh',
        \ 'ksh'
        \ ], ft) >= 0
    return FindCommentedShellFunction()
  endif


  " ----------------------------------------------------------
  " Perl
  " ----------------------------------------------------------

  if ft ==# 'perl'
    return FindCommentedPerlFunction()
  endif


  " ----------------------------------------------------------
  " C-style languages
  " ----------------------------------------------------------

  if index([
        \ 'c',
        \ 'cpp',
        \ 'cxx',
        \ 'cc',
        \ 'objc',
        \ 'java',
        \ 'javascript',
        \ 'typescript',
        \ 'css',
        \ 'scss',
        \ 'less',
        \ 'php',
        \ 'go',
        \ 'rust',
        \ 'kotlin',
        \ 'swift',
        \ 'scala'
        \ ], ft) >= 0
    return FindCommentedCStyleFunction()
  endif

  " Unknown language.
  return FindCommentedLineFunction()
endfunction


" ============================================================
" GET COMMENTED LINE
"
" Returns the text of a line with its comment marker removed.
"
" This is used only for detection.
"
" The actual buffer is NOT modified.
" ============================================================

function! FunctionUncommentedText(lnum) abort
  let marker = GetCommentMarker()

  if empty(marker)
    return getline(a:lnum)
  endif

  let text = getline(a:lnum)

  let pattern = '^\(\s*\)' . escape(marker, '\') . '\s\?'

  return substitute(text, pattern, '\1', '')
endfunction


" ============================================================
" GET COMMENT MARKER
"
" This provides a local mapping for function.vim.
"
" We intentionally do not depend on the block detector here.
" ============================================================

function! GetCommentMarker() abort
  let ft = &filetype

  if ft ==# 'vim'
    return '"'
  endif

  if index([
        \ 'python',
        \ 'sh',
        \ 'bash',
        \ 'zsh',
        \ 'ksh',
        \ 'fish',
        \ 'perl',
        \ 'ruby',
        \ 'yaml',
        \ 'yml',
        \ 'make',
        \ 'dockerfile'
        \ ], ft) >= 0
    return '#'
  endif

  return ''
endfunction


" ============================================================
" FIND COMMENTED PYTHON FUNCTION
"
" Looks for the nearest commented def declaration at or above
" the cursor.
"
" Once found, the original function indentation is recovered
" from the uncommented declaration.
" ============================================================

function! FindCommentedPythonFunction() abort
  let current = line('.')
  let marker = '#'
  let pattern = '^\s*' . escape(marker, '\') . '\s\?\(async\s\+\)\?def\s\+\w\+'

  let start = 0
  let function_indent = -1

  " Search upward for the commented function declaration.
  for lnum in reverse(range(1, current))
    if getline(lnum) =~# pattern
      let start = lnum
      let text = FunctionUncommentedText(lnum)
      let function_indent = indent(lnum)
      break
    endif
  endfor

  " Current line may be the declaration.
  if start == 0 && getline(current) =~# pattern
    let start = current
    let function_indent = indent(current)
  endif

  if start == 0
    return []
  endif

  " Find the end using the indentation of the commented
  " function declaration.
  let finish = start

  for lnum in range(start + 1, line('$'))
    let text = getline(lnum)

    " Non-commented content terminates the commented function.
    if text !~# '^\s*#'
      break
    endif

    let uncommented = FunctionUncommentedText(lnum)

    " Blank commented lines belong to the function.
    if uncommented =~# '^\s*$'
      let finish = lnum
      continue
    endif

    " A commented line at the same or lesser indentation than
    " the def belongs outside the function.
    if indent(lnum) <= function_indent
      break
    endif

    let finish = lnum
  endfor

  return [start, finish]
endfunction


" ============================================================
" FIND COMMENTED SHELL FUNCTION
"
" Searches for:
"
"   # function foo() {
"   # foo() {
"
" and then determines the closing brace.
" ============================================================

function! FindCommentedShellFunction() abort
  let current = line('.')
  let start = 0

  for lnum in reverse(range(1, current))
    let text = FunctionUncommentedText(lnum)

    if getline(lnum) =~# '^\s*#'
          \ && (
          \ text =~# '^\s*function\s\+\w\+'
          \ || text =~# '^\s*\w\+\s*()\s*{'
          \ )
      let start = lnum
      break
    endif
  endfor

  if start == 0
    let text = FunctionUncommentedText(current)

    if getline(current) =~# '^\s*#'
          \ && (
          \ text =~# '^\s*function\s\+\w\+'
          \ || text =~# '^\s*\w\+\s*()\s*{'
          \ )
      let start = current
    endif
  endif

  if start == 0
    return []
  endif

  return FindCommentedBraceRange(start)
endfunction


" ============================================================
" FIND COMMENTED PERL FUNCTION
" ============================================================

function! FindCommentedPerlFunction() abort
  let current = line('.')
  let start = 0

  for lnum in reverse(range(1, current))
    let text = FunctionUncommentedText(lnum)

    if getline(lnum) =~# '^\s*#'
          \ && text =~# '^\s*sub\s\+\w\+'
      let start = lnum
      break
    endif
  endfor

  if start == 0
    let text = FunctionUncommentedText(current)

    if getline(current) =~# '^\s*#'
          \ && text =~# '^\s*sub\s\+\w\+'
      let start = current
    endif
  endif

  if start == 0
    return []
  endif

  return FindCommentedBraceRange(start)
endfunction


" ============================================================
" FIND COMMENTED VIM FUNCTION
" ============================================================

function! FindCommentedVimFunction() abort
  let current = line('.')
  let start = 0

  for lnum in reverse(range(1, current))
    let text = FunctionUncommentedText(lnum)

    if getline(lnum) =~# '^\s*"'
          \ && text =~# '^\s*fu\%[nction]!\?\>'
      let start = lnum
      break
    endif
  endfor

  if start == 0
    let text = FunctionUncommentedText(current)

    if getline(current) =~# '^\s*"'
          \ && text =~# '^\s*fu\%[nction]!\?\>'
      let start = current
    endif
  endif

  if start == 0
    return []
  endif

  let finish = start

  for lnum in range(start + 1, line('$'))
    let text = FunctionUncommentedText(lnum)

    if getline(lnum) =~# '^\s*"'
          \ && text =~# '^\s*endf\%[unction]\>'
      let finish = lnum
      break
    endif
  endfor

  return [start, finish]
endfunction


" ============================================================
" FIND COMMENTED C-STYLE FUNCTION
"
" Cf for C-style languages uses /* ... */ through the shared
" line-commenting infrastructure.
"
" Therefore detect the surrounding comment markers directly.
" ============================================================

function! FindCommentedCStyleFunction() abort
  let current = line('.')
  let start = 0
  let finish = 0

  " Search upward for the opening marker.
  for lnum in reverse(range(1, current))
    if getline(lnum) =~# '^\s*/\*'
      let start = lnum
      break
    endif
  endfor

  if start == 0 && getline(current) =~# '/\*'
    let start = current
  endif

  if start == 0
    return []
  endif

  " Search downward for the closing marker.
  for lnum in range(start, line('$'))
    if getline(lnum) =~# '\*/'
      let finish = lnum
      break
    endif
  endfor

  if finish == 0
    return []
  endif

  if current < start || current > finish
    return []
  endif

  return [start, finish]
endfunction


" ============================================================
" FIND COMMENTED LINE FUNCTION
"
" Generic fallback.
"
" IMPORTANT:
"
" Unlike a simple contiguous-comment detector, this does NOT
" automatically include all comments above the function.
"
" It searches for a recognizable function declaration first.
" ============================================================

function! FindCommentedLineFunction() abort
  let current = line('.')
  let marker = GetCommentMarker()

  if empty(marker)
    return []
  endif

  let start = 0

  for lnum in reverse(range(1, current))
    let text = FunctionUncommentedText(lnum)

    if getline(lnum) =~# '^\s*' . escape(marker, '\')
          \ && (
          \ text =~# '^\s*\(function\|func\|def\|sub\)\>'
          \ || text =~# '\w\+\s*()\s*{'
          \ )
      let start = lnum
      break
    endif
  endfor

  if start == 0
    let text = FunctionUncommentedText(current)

    if getline(current) =~# '^\s*' . escape(marker, '\')
          \ && (
          \ text =~# '^\s*\(function\|func\|def\|sub\)\>'
          \ || text =~# '\w\+\s*()\s*{'
          \ )
      let start = current
    endif
  endif

  if start == 0
    return []
  endif

  return FindCommentedBraceRange(start)
endfunction


" ============================================================
" FIND COMMENTED BRACE RANGE
"
" Counts braces in the uncommented representation of the
" commented lines.
"
" This allows Uf to determine the actual function boundary
" without modifying the buffer first.
" ============================================================

function! FindCommentedBraceRange(start) abort
  let depth = 0
  let found_open = 0
  let finish = a:start

  for lnum in range(a:start, line('$'))
    let text = getline(lnum)

    " Stop when the commented region ends.
    if text !~# '^\s*#'
      break
    endif

    let clean = FunctionUncommentedText(lnum)

    " Remove simple quoted strings before counting braces.
    let clean = substitute(clean, '"[^"]*"', '', 'g')
    let clean = substitute(clean, "'[^']*'", '', 'g')

    let opens = strlen(substitute(clean, '[^{]', '', 'g'))
    let closes = strlen(substitute(clean, '[^}]', '', 'g'))

    let depth += opens
    let depth -= closes

    if opens > 0
      let found_open = 1
    endif

    if found_open
      let finish = lnum
    endif

    if found_open && depth <= 0
      break
    endif
  endfor

  if !found_open
    return []
  endif

  return [a:start, finish]
endfunction
