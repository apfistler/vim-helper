" ~/.vim/helper/indent.vim
"
" Vim Editing Helpers - Structural Indentation
"
" Commands:
"
"   :Sb [spaces]    Reindent the block containing the cursor.
"   :Sf [spaces]    Reindent the function containing the cursor.
"
" If spaces are supplied, the requested number of spaces is
" used as the indentation unit.
"
" If no spaces are supplied, Vim's existing indentation
" settings are used.
"
" Debugging:
"
"   :IndentDebugOn
"   :IndentDebugOff
"
" Debugging is ON by default.
"
" This file intentionally does NOT depend on function.vim
" or block.vim.


" ============================================================
" DEBUG
" ============================================================

let g:indent_helper_debug = 1

command! IndentDebugOn let g:indent_helper_debug = 1
command! IndentDebugOff let g:indent_helper_debug = 0


function! IndentDebug(message) abort
  if get(g:, 'indent_helper_debug', 0)
    echomsg a:message
  endif
endfunction


" ============================================================
" COMMANDS
" ============================================================

command! -nargs=? Sb call ShiftBlock(<q-args>)
command! -nargs=? Sf call ShiftFunction(<q-args>)


" ============================================================
" SHIFT BLOCK
" ============================================================

function! ShiftBlock(argument) abort
  let explicit = a:argument !=# ''

  if explicit
    if a:argument !~# '^\d\+$'
      echoerr 'Indentation must be a non-negative number of spaces.'
      return
    endif

    let spaces = str2nr(a:argument)
  else
    let spaces = -1
  endif

  let range = FindIndentBlockRange()

  if empty(range)
    echoerr 'Unable to determine block at current cursor position.'
    return
  endif

  call ReindentRange(range[0], range[1], spaces, 'Sb')
endfunction


" ============================================================
" SHIFT FUNCTION
" ============================================================

function! ShiftFunction(argument) abort
  let explicit = a:argument !=# ''

  if explicit
    if a:argument !~# '^\d\+$'
      echoerr 'Indentation must be a non-negative number of spaces.'
      return
    endif

    let spaces = str2nr(a:argument)
  else
    let spaces = -1
  endif

  let range = FindIndentFunctionRange()

  if empty(range)
    echoerr 'Unable to determine function at current cursor position.'
    return
  endif

  call ReindentRange(range[0], range[1], spaces, 'Sf')
endfunction


" ============================================================
" FUNCTION RANGE
" ============================================================

function! FindIndentFunctionRange() abort
  let ft = &filetype

  if get(g:, 'indent_helper_debug', 0)
    echomsg '--- Sf DEBUG ---'
    echomsg 'Cursor: ' . line('.')
    echomsg 'Filetype: ' . ft
  endif

  if ft ==# 'python'
    let range = FindIndentPythonFunction()

  elseif index([
        \ 'sh',
        \ 'bash',
        \ 'zsh',
        \ 'ksh',
        \ 'fish'
        \ ], ft) >= 0
    let range = FindIndentShellFunction()

  elseif ft ==# 'perl'
    let range = FindIndentPerlFunction()

  elseif ft ==# 'vim'
    let range = FindIndentVimFunction()

  elseif index([
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
    let range = FindIndentBraceFunction()

  else
    let range = FindIndentBraceFunction()
  endif

  if get(g:, 'indent_helper_debug', 0)
    if empty(range)
      echomsg 'Function range: EMPTY'
    else
      echomsg 'Function range: ' . range[0] . ' - ' . range[1]
    endif
  endif

  return range
endfunction


" ============================================================
" PYTHON FUNCTION RANGE
" ============================================================

" ============================================================
" PYTHON FUNCTION RANGE (FIXED FOR BROKEN/UNINDENTED CODE)
" ============================================================

function! FindIndentPythonFunction() abort
  let current = line('.')
  let start = 0
  let function_indent = -1

  " 1. Find the nearest def at or above current line
  for lnum in reverse(range(1, current))
    let text = getline(lnum)
    if text =~# '^\s*\(async\s\+\)\?def\s\+\w\+'
      let start = lnum
      let function_indent = indent(lnum)
      break
    endif
  endfor

  if start == 0
    return []
  endif

  " 2. Walk downward to find where the function ends
  let total_lines = line('$')
  let finish = total_lines
  let last_content_line = start

  for lnum in range(start + 1, total_lines)
    let text = getline(lnum)

    " Skip completely blank lines
    if text =~# '^\s*$'
      continue
    endif

    " Stop IF we encounter a new top-level def/class at the same or outer indent level
    " OR a new unindented top-level statement (indent=0) that isn't a comment
    if lnum > current
      if text =~# '^\s*\(async\s\+\)\?def\s\+\w\+' && indent(lnum) <= function_indent
        break
      endif
      if text =~# '^\s*class\s\+\w\+' && indent(lnum) <= function_indent
        break
      endif
      if text =~# '^\s*if\s\+__name__' && indent(lnum) <= function_indent
        break
      endif
    endif

    let last_content_line = lnum
  endfor

  " Trim trailing blank lines at the bottom of the function
  let finish = last_content_line

  if finish < current
    return []
  endif

  return [start, finish]
endfunction

" ============================================================
" SHELL FUNCTION
" ============================================================

function! FindIndentShellFunction() abort
  let current = line('.')
  let start = 0

  for lnum in reverse(range(1, current))
    let text = getline(lnum)
    if text =~# '^\s*function\s\+\w\+'
          \ || text =~# '^\s*\w\+\s*()\s*{'
      let start = lnum
      break
    endif
  endfor

  if start == 0
    return []
  endif

  return FindIndentBraceRange(start)
endfunction


" ============================================================
" PERL FUNCTION
" ============================================================

function! FindIndentPerlFunction() abort
  let current = line('.')
  let start = 0

  for lnum in reverse(range(1, current))
    if getline(lnum) =~# '^\s*sub\s\+\w\+'
      let start = lnum
      break
    endif
  endfor

  if start == 0
    return []
  endif

  return FindIndentBraceRange(start)
endfunction


" ============================================================
" VIM FUNCTION
" ============================================================

function! FindIndentVimFunction() abort
  let current = line('.')
  let start = 0

  for lnum in reverse(range(1, current))
    if getline(lnum) =~# '^\s*fu\%[nction]!\?\>'
      let start = lnum
      break
    endif
  endfor

  if start == 0
    return []
  endif

  let finish = start
  let depth = 0

  " Track nested function definitions to find matching endfunction
  for lnum in range(start, line('$'))
    let text = getline(lnum)

    if text =~# '^\s*fu\%[nction]!\?\>'
      let depth += 1
    elseif text =~# '^\s*endf\%[unction]\>'
      let depth -= 1
      if depth == 0
        let finish = lnum
        break
      endif
    endif
  endfor

  if finish < current
    return []
  endif

  return [start, finish]
endfunction


" ============================================================
" BRACE FUNCTION
" ============================================================

function! FindIndentBraceFunction() abort
  let current = line('.')
  let start = 0

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
    return []
  endif

  return FindIndentBraceRange(start)
endfunction


" ============================================================
" BRACE RANGE
" ============================================================

function! FindIndentBraceRange(start) abort
  let depth = 0
  let found_open = 0
  let finish = a:start
  let current = line('.')

  for lnum in range(a:start, line('$'))
    let clean = IndentStripCommentsAndStrings(getline(lnum))

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

  if !found_open || finish < current
    return []
  endif

  return [a:start, finish]
endfunction


" ============================================================
" BLOCK RANGE
" ============================================================

function! FindIndentBlockRange() abort
  let ft = &filetype

  if ft ==# 'python'
    return FindIndentPythonBlock()
  endif

  if index([
        \ 'sh',
        \ 'bash',
        \ 'zsh',
        \ 'ksh',
        \ 'fish'
        \ ], ft) >= 0
    return FindIndentShellBlock()
  endif

  if ft ==# 'vim'
    return FindIndentVimBlock()
  endif

  return FindIndentBraceBlock()
endfunction


" ============================================================
" PYTHON BLOCK
" ============================================================

function! FindIndentPythonBlock() abort
  let current = line('.')
  let current_indent = indent(current)

  if current_indent == 0
    return [current, current]
  endif

  let start = current

  " Look backward for block header
  for lnum in reverse(range(1, current - 1))
    let text = getline(lnum)

    if text =~# '^\s*$' || text =~# '^\s*#'
      continue
    endif

    if indent(lnum) < current_indent
      let start = lnum
      break
    endif

    let start = lnum
  endfor

  let base = indent(start)
  let finish = current

  " Look forward for block completion
  for lnum in range(current + 1, line('$'))
    let text = getline(lnum)

    if text =~# '^\s*$' || text =~# '^\s*#'
      continue
    endif

    if indent(lnum) <= base
      break
    endif

    let finish = lnum
  endfor

  return [start, finish]
endfunction


" ============================================================
" SHELL BLOCK
" ============================================================

function! FindIndentShellBlock() abort
  let current = line('.')
  let start = IndentFindOpeningBrace(current)

  if start > 0
    return FindIndentBraceRange(start)
  endif

  return []
endfunction


" ============================================================
" VIM BLOCK
" ============================================================

function! FindIndentVimBlock() abort
  let current = line('.')
  let start = 0
  let end_pattern = ''

  for lnum in reverse(range(1, current))
    let text = getline(lnum)

    if text =~# '^\s*if\>'
      let start = lnum
      let end_pattern = '^\s*endif\>'
      break
    elseif text =~# '^\s*for\>'
      let start = lnum
      let end_pattern = '^\s*endfor\>'
      break
    elseif text =~# '^\s*while\>'
      let start = lnum
      let end_pattern = '^\s*endwhile\>'
      break
    endif
  endfor

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

  if finish < current
    return []
  endif

  return [start, finish]
endfunction


" ============================================================
" BRACE BLOCK
" ============================================================

function! FindIndentBraceBlock() abort
  let current = line('.')
  let start = IndentFindOpeningBrace(current)

  if start <= 0
    return []
  endif

  return FindIndentBraceRange(start)
endfunction


" ============================================================
" FIND OPENING BRACE
" ============================================================

function! IndentFindOpeningBrace(current) abort
  let depth = 0

  for lnum in reverse(range(1, a:current))
    let clean = IndentStripCommentsAndStrings(getline(lnum))

    let opens = strlen(substitute(clean, '[^{]', '', 'g'))
    let closes = strlen(substitute(clean, '[^}]', '', 'g'))

    let depth += closes
    let depth -= opens

    if depth < 0
      return lnum
    endif
  endfor

  let clean = IndentStripCommentsAndStrings(getline(a:current))

  if clean =~# '{'
    return a:current
  endif

  return 0
endfunction


" ============================================================
" STRING & COMMENT CLEANUP
" ============================================================

function! IndentStripCommentsAndStrings(text) abort
  let clean = a:text

  " Strip single-line comments
  if &filetype =~# '^\(c\|cpp\|java\|javascript\|typescript\|go\|rust\|swift\|php\)$'
    let clean = substitute(clean, '//.*$', '', '')
  elseif &filetype =~# '^\(python\|sh\|bash\|zsh\|perl\|ruby\)$'
    let clean = substitute(clean, '#.*$', '', '')
  elseif &filetype ==# 'vim'
    let clean = substitute(clean, '^\s*".*$', '', '')
  endif

  " Strip string literals
  let clean = substitute(clean, '"\(\\"\|[^"]\)*"', '', 'g')
  let clean = substitute(clean, "'\(\\'\|[^']\)*'", '', 'g')

  return clean
endfunction


" ============================================================
" REINDENT RANGE
" ============================================================

" ============================================================
" REINDENT RANGE (FIXED FOR DEFAULT 4-SPACE INDENT)
" ============================================================

function! ReindentRange(start, finish, requested, operation) abort
  let cursor_line = line('.')
  let cursor_col = col('.')

  let old_shiftwidth = &shiftwidth
  let old_softtabstop = &softtabstop
  let old_tabstop = &tabstop
  let old_expandtab = &expandtab
  let old_autoindent = &autoindent
  let old_smartindent = &smartindent
  let old_cindent = &cindent
  let old_indentexpr = &indentexpr

  if get(g:, 'indent_helper_debug', 0)
    echomsg 'Requested spaces: ' . a:requested
    echomsg '--- RANGE BEFORE ---'

    for lnum in range(a:start, a:finish)
      echomsg printf(
            \ '%4d: indent=%d text=%s',
            \ lnum,
            \ indent(lnum),
            \ string(getline(lnum))
            \ )
    endfor
  endif

  " ----------------------------------------------------------
  " Determine temporary indentation settings:
  " - If an explicit argument was passed (a:requested >= 0), use it.
  " - Otherwise, default to 4 spaces.
  " ----------------------------------------------------------

  if a:requested >= 0
    let indent_unit = a:requested
  else
    let indent_unit = 4
  endif

  if get(g:, 'indent_helper_debug', 0)
    echomsg 'Applied indentation unit: ' . indent_unit
  endif

  " ----------------------------------------------------------
  " Configure Vim temporarily to enforce spaces over tabs.
  " ----------------------------------------------------------

  let &shiftwidth = indent_unit
  let &softtabstop = indent_unit
  let &tabstop = indent_unit
  let &expandtab = 1

  " Reindent using visual line range and native operator
  call cursor(a:start, 1)
  normal! V

  if a:finish > a:start
    execute 'normal! ' . (a:finish - a:start) . 'j'
  endif

  normal! =

  " Restore cursor position and option state
  call cursor(cursor_line, cursor_col)

  let &shiftwidth = old_shiftwidth
  let &softtabstop = old_softtabstop
  let &tabstop = old_tabstop
  let &expandtab = old_expandtab
  let &autoindent = old_autoindent
  let &smartindent = old_smartindent
  let &cindent = old_cindent
  let &indentexpr = old_indentexpr

  if get(g:, 'indent_helper_debug', 0)
    echomsg '--- RANGE AFTER ---'

    for lnum in range(a:start, a:finish)
      echomsg printf(
            \ '%4d: indent=%d text=%s',
            \ lnum,
            \ indent(lnum),
            \ string(getline(lnum))
            \ )
    endfor

    echomsg 'Vim state restored.'
    echomsg '--- ' . a:operation . ' DEBUG END ---'
  endif
endfunction
