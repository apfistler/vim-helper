" ============================================================
" INDENT HELPER (indent.vim)
" Commands:
"   :Sb [spaces] - Reindent current block
"   :Sf [spaces] - Reindent current function
"   :Sd [spaces] - Reindent entire document
" ============================================================

" Debug flag: set g:indent_helper_debug = 1 in .vimrc to enable logging
let g:indent_helper_debug = get(g:, 'indent_helper_debug', 0)

" ------------------------------------------------------------
" COMMAND DEFINITIONS
" ------------------------------------------------------------

command! -nargs=? Sb call ShiftBlock(<q-args>)
command! -nargs=? Sf call ShiftFunction(<q-args>)
command! -nargs=? Sd call ShiftDocument(<q-args>)

" ------------------------------------------------------------
" CORE REINDENT ENGINE
" ------------------------------------------------------------

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

  if g:indent_helper_debug
    echomsg '--- ' . a:operation . ' DEBUG START ---'
    echomsg 'Cursor: line ' . cursor_line . ', col ' . cursor_col
    echomsg 'Filetype: ' . &filetype
    echomsg 'Target range: ' . a:start . ' - ' . a:finish
    echomsg 'Requested spaces: ' . a:requested
    echomsg '--- RANGE BEFORE ---'
    for lnum in range(a:start, a:finish)
      echomsg printf('%4d: indent=%d text=%s', lnum, indent(lnum), string(getline(lnum)))
    endfor
    echomsg 'Original shiftwidth: ' . old_shiftwidth
    echomsg 'Original softtabstop: ' . old_softtabstop
    echomsg 'Original tabstop: ' . old_tabstop
    echomsg 'Original expandtab: ' . old_expandtab
  endif

  " Determine indentation spacing (explicit arg, else default to 4 spaces)
  if a:requested >= 0
    let indent_unit = a:requested
  else
    let indent_unit = 4
  endif

  if g:indent_helper_debug
    echomsg 'Applied indentation unit: ' . indent_unit
  endif

  " Temporarily override indentation settings to enforce space-based indent
  let &shiftwidth = indent_unit
  let &softtabstop = indent_unit
  let &tabstop = indent_unit
  let &expandtab = 1

  " Reindent strategy: use Python AST/syntax loop for Python files, Vim '=' for others
  if &filetype ==# 'python' && has('python3')
    python3 << EOF
import vim

start_line = int(vim.eval('a:start'))
finish_line = int(vim.eval('a:finish'))
indent_size = int(vim.eval('indent_unit'))

buf = vim.current.buffer
lines = buf[start_line-1:finish_line]

reindented = []
indent_stack = [0]

for line in lines:
    stripped = line.strip()
    if not stripped:
        reindented.append('')
        continue

    # Deduce nesting changes based on control structure keywords
    if stripped.startswith(('elif ', 'else:', 'except', 'finally:')):
        level = max(0, len(indent_stack) - 2) if len(indent_stack) > 1 else 0
        indent_str = ' ' * (level * indent_size)
    else:
        indent_str = ' ' * (indent_stack[-1] * indent_size)

    reindented.append(indent_str + stripped)

    # If the line opens a block (ends with ':'), increase indent level
    if stripped.endswith(':'):
        indent_stack.append(indent_stack[-1] + 1)

buf[start_line-1:finish_line] = reindented
EOF
  else
    " Perform reindentation using visual line selection + Vim's '=' operator
    call cursor(a:start, 1)
    normal! V
    if a:finish > a:start
      execute 'normal! ' . (a:finish - a:start) . 'j'
    endif
    normal! =
  endif

  " Restore original cursor position and settings
  call cursor(cursor_line, cursor_col)

  let &shiftwidth = old_shiftwidth
  let &softtabstop = old_softtabstop
  let &tabstop = old_tabstop
  let &expandtab = old_expandtab
  let &autoindent = old_autoindent
  let &smartindent = old_smartindent
  let &cindent = old_cindent
  let &indentexpr = old_indentexpr

  if g:indent_helper_debug
    echomsg '--- RANGE AFTER ---'
    for lnum in range(a:start, a:finish)
      echomsg printf('%4d: indent=%d text=%s', lnum, indent(lnum), string(getline(lnum)))
    endfor
    echomsg 'Vim state restored.'
    echomsg '--- ' . a:operation . ' DEBUG END ---'
  endif
endfunction

" ------------------------------------------------------------
" HELPER FUNCTIONS FOR SCOPE DETECTION
" ------------------------------------------------------------

function! ParseSpaceArg(arg) abort
  if a:arg ==# ''
    return -1
  endif
  if a:arg !~# '^\d\+$'
    echoerr 'Indentation must be a non-negative number of spaces.'
    return -2
  endif
  return str2nr(a:arg)
endfunction

function! FindBraceRange() abort
  let start = search('^{', 'bcnW')
  if start == 0
    let start = search('{', 'bcnW')
  endif
  if start == 0
    return []
  endif

  let saved_pos = getpos('.')
  call cursor(start, 1)
  normal! %
  let finish = line('.')
  call setpos('.', saved_pos)

  if finish <= start
    return []
  endif

  return [start, finish]
endfunction

function! FindIndentPythonFunction() abort
  let current = line('.')
  let start = 0
  let function_indent = -1

  " 1. Search backwards for nearest def statement
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

  " 2. Walk forward to find end boundary
  let total_lines = line('$')
  let last_content_line = start

  for lnum in range(start + 1, total_lines)
    let text = getline(lnum)

    if text =~# '^\s*$'
      continue
    endif

    " Stop if we reach a new top-level construct after cursor position
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

  let finish = last_content_line
  if finish < current
    return []
  endif

  return [start, finish]
endfunction

function! FindIndentPythonBlock() abort
  let current = line('.')
  let cur_indent = indent(current)
  let total_lines = line('$')

  " If on blank line, walk up to find nearest non-blank line
  if getline(current) =~# '^\s*$'
    let non_blank = prevnonblank(current)
    if non_blank == 0
      return []
    endif
    let cur_indent = indent(non_blank)
  endif

  " Find start of block
  let start = current
  while start > 1
    let prev_line = start - 1
    let prev_text = getline(prev_line)

    if prev_text =~# '^\s*$'
      let start = prev_line
      continue
    endif

    if indent(prev_line) < cur_indent
      break
    endif

    let start = prev_line
  endwhile

  " Find end of block
  let finish = current
  while finish < total_lines
    let next_line = finish + 1
    let next_text = getline(next_line)

    if next_text =~# '^\s*$'
      let finish = next_line
      continue
    endif

    if indent(next_line) < cur_indent
      break
    endif

    let finish = next_line
  endwhile

  return [start, finish]
endfunction

" ------------------------------------------------------------
" COMMAND IMPLEMENTATIONS
" ------------------------------------------------------------

function! ShiftBlock(argument) abort
  let spaces = ParseSpaceArg(a:argument)
  if spaces == -2
    return
  endif

  let range_coords = []
  if &filetype ==# 'python'
    let range_coords = FindIndentPythonBlock()
  else
    let range_coords = FindBraceRange()
  endif

  if empty(range_coords)
    echo 'No enclosing block found.'
    return
  endif

  call ReindentRange(range_coords[0], range_coords[1], spaces, 'Sb')
endfunction

function! ShiftFunction(argument) abort
  let spaces = ParseSpaceArg(a:argument)
  if spaces == -2
    return
  endif

  let range_coords = []
  if &filetype ==# 'python'
    let range_coords = FindIndentPythonFunction()
  else
    let range_coords = FindBraceRange()
  endif

  if empty(range_coords)
    echo 'No enclosing function found.'
    return
  endif

  call ReindentRange(range_coords[0], range_coords[1], spaces, 'Sf')
endfunction

function! ShiftDocument(argument) abort
  let spaces = ParseSpaceArg(a:argument)
  if spaces == -2
    return
  endif

  let last_line = line('$')
  if last_line <= 0
    return
  endif

  call ReindentRange(1, last_line, spaces, 'Sd')
endfunction
