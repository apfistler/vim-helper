" ~/.vim/helper/function.vim
"
" Vim Editing Helpers
"
" Function / method / subroutine commenting helpers.
"
" Commands:
"
"   :Cf  Comment the function/method/subroutine containing
"        the current cursor position.
"
"   :Uf  Uncomment the function/method/subroutine containing
"        the current cursor position.
"
" This module depends on GetCommentStyle() from style.vim
" and the line/block commenting functions provided by the
" other helper modules.
"
" User-defined Vim commands must begin with an uppercase
" letter.
"

" ============================================================
" FUNCTION DETECTION
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
"
" Example:
"
"   def foo():
"       one()
"       if something:
"           two()
"
"       three()
"
"   def bar():
"
" The function ends when a non-blank line is encountered at
" the same or lesser indentation than the def statement.
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

" A class can contain methods. If the cursor is inside a
" method, continue searching for def first.
if text =~# '^\s*class\s\+\w\+'
  if start == 0
    let start = lnum
    let function_indent = indent(lnum)
  endif
  break
endif

endfor

if start == 0
" Current line itself may be the function declaration.
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
if getline(start) =~# '^\s*class\s+'
for lnum in range(start + 1, current)
if getline(lnum) =~# '^\s*\(async\s\+\)?def\s+\w+'
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
if getline(lnum) =~# '^\s*sub\s+\w+'
let start = lnum
break
endif
endfor

if start == 0 && getline(current) =~# '^\s*sub\s+\w+'
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
if getline(lnum) =~# '^\s*fu%[nction]!?>'
let start = lnum
break
endif
endfor

if start == 0 && getline(current) =~# '^\s*fu%[nction]!?>'
let start = current
endif

if start == 0
return []
endif

let finish = start

for lnum in range(start + 1, line('$'))
if getline(lnum) =~# '^\s*endf%[unction]>'
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
" declaration. We intentionally allow a broad definition
" because different brace-based languages have very
" different function syntax.
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

return [a:start, finish]
endfunction

" ============================================================
" COMMENT FUNCTION
"
" :Cf
"
" Comments the entire function/method/subroutine containing
" the current cursor position.
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
" Uncomments the entire function/method/subroutine containing
" the current cursor position.
" ============================================================

command! Uf call UncommentFunction()

function! UncommentFunction() abort
let range = FindFunctionRange()

if empty(range)
echoerr 'Unable to determine function at current cursor position.'
return
endif

call UncommentLines(range[0], range[1])
endfunction

