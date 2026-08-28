" ~/.vim/helper/block.vim
"
" Vim Editing Helpers - Block Operations
"
" Commands:
"
"   :Cb    Comment the block containing the current cursor
"   :Ub    Uncomment the block containing the current cursor
"
" Block detection is based on the current filetype.
"
" Line-comment languages:
"   #  Python, Perl, Shell, YAML, etc.
"
" C-style languages:
"   /* ... */
"
" Vimscript:
"   "
"
" User-defined commands must begin with an uppercase letter.
"


" ============================================================
" BLOCK COMMENT STYLE
" ============================================================

function! BlockCommentStyle() abort
  let ft = &filetype

  " Vimscript
  if ft ==# 'vim'
    return ['"', 'line']
  endif

  " Python / Perl / Shell / YAML and similar languages
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
    return ['#', 'line']
  endif

  " C-style languages
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
    return ['/*', 'block']
  endif

  " Unknown filetypes default to #.
  return ['#', 'line']
endfunction


" ============================================================
" COMMENT BLOCK
"
" :Cb
"
" Finds the block containing the current cursor and comments
" the entire block.
"
" For line-comment languages, the entire block is commented
" line by line.
"
" For C-style languages, /* and */ are placed around the block.
" ============================================================

command! Cb call CommentBlock()

function! CommentBlock() abort
  let range = FindBlock()

  if empty(range)
    echoerr 'Unable to determine block at current cursor position.'
    return
  endif

  let style = BlockCommentStyle()

  if style[1] ==# 'line'
    call BlockCommentLines(range[0], range[1], style[0])
  else
    call BlockCommentCStyle(range[0], range[1])
  endif
endfunction


" ============================================================
" UNCOMMENT BLOCK
"
" :Ub
"
" Finds the block containing the current cursor and reverses
" the operation performed by Cb.
" ============================================================

command! Ub call UncommentBlock()

function! UncommentBlock() abort
  let range = FindBlock()

  if empty(range)
    echoerr 'Unable to determine block at current cursor position.'
    return
  endif

  let style = BlockCommentStyle()

  if style[1] ==# 'line'
    call BlockUncommentLines(range[0], range[1], style[0])
  else
    call BlockUncommentCStyle(range[0], range[1])
  endif
endfunction


" ============================================================
" FIND BLOCK
"
" Attempts to determine the logical block containing the
" current cursor.
"
" The implementation deliberately remains independent from
" function.vim.
"
" This is important:
"
"   Cb / Ub = block operations
"   Cf / Uf = function operations
"
" They may use similar detection logic, but changing one
" should not break the other.
" ============================================================

function! FindBlock() abort
  let ft = &filetype

  " ----------------------------------------------------------
  " Python
  "
  " Python blocks are indentation based.
  " ----------------------------------------------------------

  if ft ==# 'python'
    return FindPythonBlock()
  endif


  " ----------------------------------------------------------
  " Shell
  " ----------------------------------------------------------

  if index([
        \ 'sh',
        \ 'bash',
        \ 'zsh',
        \ 'ksh',
        \ 'fish'
        \ ], ft) >= 0
    return FindShellBlock()
  endif


  " ----------------------------------------------------------
  " Perl
  " ----------------------------------------------------------

  if ft ==# 'perl'
    return FindPerlBlock()
  endif


  " ----------------------------------------------------------
  " Vimscript
  " ----------------------------------------------------------

  if ft ==# 'vim'
    return FindVimBlock()
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
    return FindBraceBlock()
  endif


  " ----------------------------------------------------------
  " Unknown filetype
  "
  " Fall back to brace detection.
  " ----------------------------------------------------------

  return FindBraceBlock()
endfunction


" ============================================================
" FIND PYTHON BLOCK
"
" Python blocks are indentation based.
"
" The current line is considered part of the block.
"
" A block begins at the nearest enclosing line whose
" indentation is less than the current line's indentation.
"
" This intentionally does NOT attempt to determine whether
" the block is a function, class, if statement, loop, etc.
"
" That belongs to function.vim.
" ============================================================

function! FindPythonBlock() abort
  let current = line('.')
  let current_indent = indent(current)

  " If the current line is top-level, use the current line
  " as the block.
  if current_indent == 0
    return [current, current]
  endif

  let start = current

  " Walk upward until we encounter a less-indented line.
  for lnum in reverse(range(1, current - 1))
    let text = getline(lnum)

    " Blank lines are skipped while looking for the enclosing
    " indentation level.
    if text =~# '^\s*$'
      continue
    endif

    if indent(lnum) < current_indent
      let start = lnum
      break
    endif

    let start = lnum
  endfor

  " Determine the indentation level represented by the
  " beginning of the block.
  let block_indent = indent(start)

  let finish = current

  for lnum in range(current + 1, line('$'))
    let text = getline(lnum)

    " Blank lines remain part of the block.
    if text =~# '^\s*$'
      let finish = lnum
      continue
    endif

    if indent(lnum) < block_indent
      break
    endif

    let finish = lnum
  endfor

  return [start, finish]
endfunction


" ============================================================
" FIND SHELL BLOCK
"
" Finds a brace-delimited block surrounding the cursor.
"
" Example:
"
"   if condition; then
"       command
"       command
"   fi
"
" Shell also uses braces:
"
"   {
"       command
"       command
"   }
"
" and:
"
"   foo() {
"       command
"   }
"
" For brace-based shell blocks, brace balancing is used.
" ============================================================

function! FindShellBlock() abort
  let current = line('.')

  " First try to find an enclosing {.
  let start = FindOpeningBrace(current)

  if start > 0
    return FindBraceRangeFromStart(start)
  endif

  " If there is no brace block, look for common shell block
  " constructs.
  let start = FindShellKeywordBlock(current)

  if !empty(start)
    return start
  endif

  return []
endfunction


" ============================================================
" FIND PERL BLOCK
"
" Perl uses braces heavily, so use brace balancing.
" ============================================================

function! FindPerlBlock() abort
  let current = line('.')
  let start = FindOpeningBrace(current)

  if start > 0
    return FindBraceRangeFromStart(start)
  endif

  return []
endfunction


" ============================================================
" FIND VIM BLOCK
"
" Vimscript blocks such as:
"
"   if ...
"       ...
"   endif
"
"   for ...
"       ...
"   endfor
"
"   while ...
"       ...
"   endwhile
"
"   try
"       ...
"   endtry
"
"   function ...
"       ...
"   endfunction
"
" are detected using matching end commands.
" ============================================================

function! FindVimBlock() abort
  let current = line('.')
  let start = 0
  let end_pattern = ''

  " Search upward for the nearest block opener.
  for lnum in reverse(range(1, current))
    let text = getline(lnum)

    if text =~# '^\s*if\>'
      let start = lnum
      let end_pattern = '^\s*endif\>'
      break
    endif

    if text =~# '^\s*for\>'
      let start = lnum
      let end_pattern = '^\s*endfor\>'
      break
    endif

    if text =~# '^\s*while\>'
      let start = lnum
      let end_pattern = '^\s*endwhile\>'
      break
    endif

    if text =~# '^\s*try\>'
      let start = lnum
      let end_pattern = '^\s*endtry\>'
      break
    endif

    if text =~# '^\s*fu\%[nction]!\?\>'
      let start = lnum
      let end_pattern = '^\s*endf\%[unction]\>'
      break
    endif
  endfor

  " The current line itself may be the block opener.
  if start == 0
    let text = getline(current)

    if text =~# '^\s*if\>'
      let start = current
      let end_pattern = '^\s*endif\>'
    elseif text =~# '^\s*for\>'
      let start = current
      let end_pattern = '^\s*endfor\>'
    elseif text =~# '^\s*while\>'
      let start = current
      let end_pattern = '^\s*endwhile\>'
    elseif text =~# '^\s*try\>'
      let start = current
      let end_pattern = '^\s*endtry\>'
    elseif text =~# '^\s*fu\%[nction]!\?\>'
      let start = current
      let end_pattern = '^\s*endf\%[unction]\>'
    endif
  endif

  if start == 0
    return []
  endif

  let finish = start

  for lnum in range(start + 1, line('$'))
    if getline(lnum) =~# end_pattern
      let finish = lnum
      break
    endif
  endfor

  return [start, finish]
endfunction


" ============================================================
" FIND BRACE BLOCK
"
" Finds the nearest opening brace surrounding the cursor and
" returns its matching closing brace.
" ============================================================

function! FindBraceBlock() abort
  let current = line('.')
  let start = FindOpeningBrace(current)

  if start <= 0
    return []
  endif

  return FindBraceRangeFromStart(start)
endfunction


" ============================================================
" FIND OPENING BRACE
"
" Walk upward from the current line while maintaining brace
" depth.
"
" Returns the line containing the opening brace for the block
" surrounding the cursor.
" ============================================================

function! FindOpeningBrace(current) abort
  let depth = 0

  for lnum in reverse(range(1, a:current))
    let text = getline(lnum)

    let clean = BlockStripStrings(text)

    let opens = strlen(substitute(clean, '[^{]', '', 'g'))
    let closes = strlen(substitute(clean, '[^}]', '', 'g'))

    let depth += closes
    let depth -= opens

    if depth < 0
      return lnum
    endif
  endfor

  " Check whether the current line itself contains an opening
  " brace before the cursor position.
  let text = getline(a:current)
  let clean = BlockStripStrings(text)

  if clean =~# '{'
    return a:current
  endif

  return 0
endfunction


" ============================================================
" FIND BRACE RANGE FROM START
"
" Counts nested braces until the matching closing brace.
" ============================================================

function! FindBraceRangeFromStart(start) abort
  let depth = 0
  let found_open = 0
  let finish = a:start

  for lnum in range(a:start, line('$'))
    let text = getline(lnum)
    let clean = BlockStripStrings(text)

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
" FIND SHELL KEYWORD BLOCK
"
" Supports common shell constructs:
"
"   if ... fi
"   for ... done
"   while ... done
"   case ... esac
"
" The implementation is intentionally separate from function
" detection.
" ============================================================

function! FindShellKeywordBlock(current) abort
  let start = 0
  let end_pattern = ''

  for lnum in reverse(range(1, a:current))
    let text = getline(lnum)

    if text =~# '^\s*if\>'
      let start = lnum
      let end_pattern = '^\s*fi\>'
      break
    endif

    if text =~# '^\s*for\>'
      let start = lnum
      let end_pattern = '^\s*done\>'
      break
    endif

    if text =~# '^\s*while\>'
      let start = lnum
      let end_pattern = '^\s*done\>'
      break
    endif

    if text =~# '^\s*until\>'
      let start = lnum
      let end_pattern = '^\s*done\>'
      break
    endif

    if text =~# '^\s*case\>'
      let start = lnum
      let end_pattern = '^\s*esac\>'
      break
    endif
  endfor

  if start == 0
    let text = getline(a:current)

    if text =~# '^\s*if\>'
      let start = a:current
      let end_pattern = '^\s*fi\>'
    elseif text =~# '^\s*for\>'
      let start = a:current
      let end_pattern = '^\s*done\>'
    elseif text =~# '^\s*while\>'
      let start = a:current
      let end_pattern = '^\s*done\>'
    elseif text =~# '^\s*until\>'
      let start = a:current
      let end_pattern = '^\s*done\>'
    elseif text =~# '^\s*case\>'
      let start = a:current
      let end_pattern = '^\s*esac\>'
    endif
  endif

  if start == 0
    return []
  endif

  let finish = start

  for lnum in range(start + 1, line('$'))
    if getline(lnum) =~# end_pattern
      let finish = lnum
      break
    endif
  endfor

  return [start, finish]
endfunction


" ============================================================
" STRIP SIMPLE STRINGS
"
" Removes simple quoted strings before counting braces.
"
" This is deliberately lightweight. It is intended to prevent
" the common case of braces appearing inside quoted strings
" from confusing block detection.
" ============================================================

function! BlockStripStrings(text) abort
  let clean = a:text

  let clean = substitute(clean, '"[^"]*"', '', 'g')
  let clean = substitute(clean, "'[^']*'", '', 'g')

  return clean
endfunction


" ============================================================
" COMMENT LINE BLOCK
"
" Used by Cb for languages whose block comments are actually
" line comments.
" ============================================================

function! BlockCommentLines(start, finish, marker) abort
  for lnum in range(a:start, a:finish)
    let text = getline(lnum)

    let indent = matchstr(text, '^\s*')
    let body = strpart(text, strlen(indent))

    " Do not double-comment a line.
    if body ==# a:marker
      continue
    endif

    if body =~# '^' . escape(a:marker, '\') . '\s'
      continue
    endif

    call setline(
          \ lnum,
          \ indent . a:marker . ' ' . body
          \ )
  endfor
endfunction


" ============================================================
" UNCOMMENT LINE BLOCK
" ============================================================

function! BlockUncommentLines(start, finish, marker) abort
  for lnum in range(a:start, a:finish)
    let text = getline(lnum)

    let pattern = '^\(\s*\)' . escape(a:marker, '\') . '\s\?'

    if text =~# pattern
      call setline(
            \ lnum,
            \ substitute(text, pattern, '\1', '')
            \ )
    endif
  endfor
endfunction


" ============================================================
" COMMENT C-STYLE BLOCK
"
" Places:
"
"   /*
"
" at the beginning of the first line and:
"
"   */
"
" at the end of the final line.
"
" Existing indentation is preserved.
" ============================================================

function! BlockCommentCStyle(start, finish) abort
  let first = getline(a:start)

  " Don't double-comment an already-commented block.
  if first =~# '^\s*/\*'
    return
  endif

  let first_indent = matchstr(first, '^\s*')
  let first_body = strpart(first, strlen(first_indent))

  call setline(
        \ a:start,
        \ first_indent . '/* ' . first_body
        \ )


  let last = getline(a:finish)

  " Re-read the final line after modifying the first line.
  let last_indent = matchstr(last, '^\s*')
  let last_body = strpart(last, strlen(last_indent))

  call setline(
        \ a:finish,
        \ last_indent . last_body . ' */'
        \ )
endfunction


" ============================================================
" UNCOMMENT C-STYLE BLOCK
"
" Reverses BlockCommentCStyle().
" ============================================================

function! BlockUncommentCStyle(start, finish) abort
  let first = getline(a:start)
  let last = getline(a:finish)

  " Remove opening /*
  if first =~# '^\s*/\*\s\?'
    let first = substitute(
          \ first,
          \ '^\(\s*\)/\*\s\?',
          \ '\1',
          ''
          \ )

    call setline(a:start, first)
  endif


  " Remove closing */
  if last =~# '\s\*/\s*$'
    let last = substitute(
          \ last,
          \ '\s\*/\s*$',
          \ '',
          ''
          \ )

    call setline(a:finish, last)
  endif
endfunction
