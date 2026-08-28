" ~/.vim/helper.vim
"
" Vim Editing Helpers
"
" Line, block, and function commenting helpers.
"
" Commands:
"
"   :Is <spaces> <lines>   Insert spaces
"   :Cl <lines>            Comment lines
"   :Ul <lines>            Uncomment lines
"   :Cb                     Comment enclosing block
"   :Ub                     Uncomment enclosing block
"   :Cf                     Comment enclosing function/method/subroutine
"   :Uf                     Uncomment enclosing function/method/subroutine
"
" User-defined Vim commands MUST begin with an uppercase letter.
"

" ============================================================
" COMMENT STYLE
" ============================================================

function! CommentStyle() abort
let ft = &filetype

" Shell / scripting / configuration languages using #.
if ft ==# 'python'
\ || ft ==# 'perl'
\ || ft ==# 'sh'
\ || ft ==# 'bash'
\ || ft ==# 'zsh'
\ || ft ==# 'ksh'
\ || ft ==# 'fish'
\ || ft ==# 'yaml'
\ || ft ==# 'yml'
return '#'
endif

" C-style block comments.
if ft ==# 'c'
\ || ft ==# 'cpp'
\ || ft ==# 'java'
\ || ft ==# 'javascript'
\ || ft ==# 'typescript'
\ || ft ==# 'css'
\ || ft ==# 'scss'
\ || ft ==# 'php'
\ || ft ==# 'go'
\ || ft ==# 'rust'
\ || ft ==# 'csharp'
\ || ft ==# 'cs'
\ || ft ==# 'kotlin'
\ || ft ==# 'swift'
\ || ft ==# 'dart'
\ || ft ==# 'scala'
return '/*'
endif

" Vimscript uses double quotes.
if ft ==# 'vim'
return '"'
endif

" Unknown filetypes default to #.
return '#'
endfunction

" ============================================================
" SIMPLE LINE COMMENTING
" ============================================================

" :Is <spaces> <lines>
"
" Insert <spaces> spaces at the beginning of the current line
" and the following <lines>-1 lines.

command! -nargs=+ Is call InsertSpaces(<f-args>)

function! InsertSpaces(spaces, lines) abort
let indent = repeat(' ', a:spaces)
execute '.,+' . (a:lines - 1) . 's/^/' . escape(indent, '') . '/'
endfunction

" :Cl <lines>
"
" Comment the current line and following <lines>-1 lines.

command! -nargs=1 Cl call CommentLines(<args>)

function! CommentLines(lines) abort
let style = CommentStyle()

if style ==# '/*'
execute '.,+' . (a:lines - 1) . 'normal! I/* '
execute '.,+' . (a:lines - 1) . 'normal! A */'
else
execute '.,+' . (a:lines - 1) . 'normal! I' . style . ' '
endif
endfunction

" :Ul <lines>
"
" Uncomment the current line and following <lines>-1 lines.

command! -nargs=1 Ul call UncommentLines(<args>)

function! UncommentLines(lines) abort
let style = CommentStyle()

if style ==# '/*'
execute '.,+' . (a:lines - 1) . 's/^\(\s*\)/*\s?/\1/'
execute '.,+' . (a:lines - 1) . 's/\s?*/\s*$//'
elseif style ==# '"'
execute '.,+' . (a:lines - 1) . 's/^\s*"\s?//'
else
execute '.,+' . (a:lines - 1) . 's/^\(\s*\)' . escape(style, '') . '\s?/\1/'
endif
endfunction

" ============================================================
" BLOCK DETECTION
" ============================================================

" Find the enclosing brace block.
"
" This handles C-style languages and shell functions using braces.
"
" Returns [start, end] or [].

function! FindBraceBlock() abort
let save = winsaveview()

" Find the opening brace associated with the current position.
let pos = searchpair('{', '', '}', 'bnW')

if pos == 0
call winrestview(save)
return []
endif

let start = pos

" Move to the opening brace and find its matching closing brace.
call cursor(start, 1)

let end = searchpair('{', '', '}', 'nW')

call winrestview(save)

if end == 0
return []
endif

return [start, end]
endfunction

" ============================================================
" PYTHON BLOCK DETECTION
" ============================================================

function! FindPythonBlock() abort
let save = winsaveview()
let current = line('.')

" Walk upward looking for a line whose indentation is less than
" the current block indentation.
let start = 0
let start_indent = -1

for lnum in range(current, 1, -1)
let text = getline(lnum)

if text =~ '^\s*$'
  continue
endif

let indent = indent(lnum)

" A colon-terminated structural line can begin a Python block.
if text =~ ':\s*$'
  if lnum == current || indent < indent(current) || lnum < current
    let start = lnum
    let start_indent = indent
    break
  endif
endif

endfor

if start == 0
call winrestview(save)
return []
endif

let last = line('$')

for lnum in range(start + 1, last)
let text = getline(lnum)

if text =~ '^\s*$'
  continue
endif

if indent(lnum) <= start_indent
  let last = lnum - 1
  break
endif

endfor

call winrestview(save)

return [start, last]
endfunction

" ============================================================
" SHELL BLOCK DETECTION
" ============================================================

function! FindShellBlock() abort
let save = winsaveview()
let current = line('.')

" First try a brace block.
let block = FindBraceBlock()

if !empty(block)
call winrestview(save)
return block
endif

" Look for a shell function declaration and determine its
" indentation/block extent.
let start = 0

for lnum in range(current, 1, -1)
let text = getline(lnum)

if text =~ '^\s*\(function\s\+\)\?\h[\w]*\s*()\?\s*{'
  let start = lnum
  break
endif

endfor

if start == 0
call winrestview(save)
return []
endif

let depth = 0
let last = start

for lnum in range(start, line('$'))
let text = getline(lnum)

let depth += strlen(substitute(text, '[^{]', '', 'g'))
let depth -= strlen(substitute(text, '[^}]', '', 'g'))

let last = lnum

if depth <= 0
  break
endif

endfor

call winrestview(save)

if last >= start
return [start, last]
endif

return []
endfunction

" ============================================================
" FIND ENCLOSING BLOCK
" ============================================================

function! FindBlock() abort
let ft = &filetype

if ft ==# 'python'
return FindPythonBlock()
endif

if ft ==# 'sh'
\ || ft ==# 'bash'
\ || ft ==# 'zsh'
\ || ft ==# 'ksh'
\ || ft ==# 'fish'
return FindShellBlock()
endif

return FindBraceBlock()
endfunction

" ============================================================
" COMMENT BLOCK
" ============================================================

" :Cb
"
" Comment the block containing the cursor.
"
" No argument is required.

command! -nargs=0 Cb call CommentBlock()

function! CommentBlock() abort
let block = FindBlock()

if empty(block)
echoerr 'Unable to determine block at current cursor position.'
return
endif

let start = block[0]
let end = block[1]
let style = CommentStyle()

if style ==# '/*'
call append(end, '*/')
call append(start - 1, '/*')
elseif style ==# '"'
execute start . ',' . end . 's/^/"/'
else
execute start . ',' . end . 's/^/' . escape(style, '') . ' /'
endif
endfunction

" ============================================================
" UNCOMMENT BLOCK
" ============================================================

" :Ub
"
" Uncomment the block containing the cursor.
"
" No argument is required.

command! -nargs=0 Ub call UncommentBlock()

function! UncommentBlock() abort
let block = FindBlock()

if empty(block)
echoerr 'Unable to determine block at current cursor position.'
return
endif

let start = block[0]
let end = block[1]
let style = CommentStyle()

if style ==# '/*'
" Handle block delimiters on the first and last lines.
let first = getline(start)
let last = getline(end)

if first =~ '^\s*/\*'
  execute start . 's/^\(\s*\)\/\*\s\?/\1/'
endif

if last =~ '\*\/\s*$'
  execute end . 's/\s\?\*\/\s*$//'
endif

elseif style ==# '"'
execute start . ',' . end . 's/^\(\s*\)"\s?/\1/'

else
execute start . ',' . end . 's/^\(\s*\)' . escape(style, '') . '\s?/\1/'
endif
endfunction

" ============================================================
" FUNCTION DETECTION
" ============================================================

function! FindPythonFunction() abort
let save = winsaveview()
let current = line('.')

for lnum in range(current, 1, -1)
let text = getline(lnum)

if text =~ '^\s*\(async\s\+\)\?def\s\+\h\w*\s*('
  let start = lnum
  let start_indent = indent(lnum)

  let last = line('$')

  for n in range(start + 1, line('$'))
    let t = getline(n)

    if t =~ '^\s*$'
      continue
    endif

    if indent(n) <= start_indent
      let last = n - 1
      break
    endif
  endfor

  call winrestview(save)
  return [start, last]
endif

endfor

call winrestview(save)
return []
endfunction

function! FindShellFunction() abort
let save = winsaveview()
let current = line('.')

for lnum in range(current, 1, -1)
let text = getline(lnum)

if text =~ '^\s*\(function\s\+\)\?\h[\w]*\s*()\?\s*{'
  let start = lnum
  break
endif

endfor

if !exists('start')
call winrestview(save)
return []
endif

let depth = 0
let last = start

for lnum in range(start, line('$'))
let text = getline(lnum)

let depth += strlen(substitute(text, '[^{]', '', 'g'))
let depth -= strlen(substitute(text, '[^}]', '', 'g'))

let last = lnum

if depth <= 0
  break
endif

endfor

call winrestview(save)

return [start, last]
endfunction

function! FindFunction() abort
let ft = &filetype

if ft ==# 'python'
return FindPythonFunction()
endif

if ft ==# 'sh'
\ || ft ==# 'bash'
\ || ft ==# 'zsh'
\ || ft ==# 'ksh'
\ || ft ==# 'fish'
return FindShellFunction()
endif

" For brace-based languages, the enclosing brace block is
" currently the best representation of the function/method.
return FindBraceBlock()
endfunction

" ============================================================
" COMMENT FUNCTION
" ============================================================

" :Cf
"
" Comment the function/method/subroutine containing the cursor.
"
" No argument is required.

command! -nargs=0 Cf call CommentFunction()

function! CommentFunction() abort
let block = FindFunction()

if empty(block)
echoerr 'Unable to determine function at current cursor position.'
return
endif

let start = block[0]
let end = block[1]
let style = CommentStyle()

if style ==# '/*'
call append(end, '*/')
call append(start - 1, '/*')
elseif style ==# '"'
execute start . ',' . end . 's/^/"/'
else
execute start . ',' . end . 's/^/' . escape(style, '') . ' /'
endif
endfunction

" ============================================================
" UNCOMMENT FUNCTION
" ============================================================

" :Uf
"
" Uncomment the function/method/subroutine containing the cursor.
"
" No argument is required.

command! -nargs=0 Uf call UncommentFunction()

function! UncommentFunction() abort
let block = FindFunction()

if empty(block)
echoerr 'Unable to determine function at current cursor position.'
return
endif

let start = block[0]
let end = block[1]
let style = CommentStyle()

if style ==# '/*'
let first = getline(start)
let last = getline(end)

if first =~ '^\s*/\*'
  execute start . 's/^\(\s*\)\/\*\s\?/\1/'
endif

if last =~ '\*\/\s*$'
  execute end . 's/\s\?\*\/\s*$//'
endif

elseif style ==# '"'
execute start . ',' . end . 's/^\(\s*\)"\s?/\1/'

else
execute start . ',' . end . 's/^\(\s*\)' . escape(style, '') . '\s?/\1/'
endif
endfunction

