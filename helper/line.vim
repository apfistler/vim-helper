" ~/.vim/helper/line.vim
"
" Vim Editing Helpers
"
" Line-oriented editing helpers.
"
" Commands:
"
"   :Iss <spaces> <lines>  Insert spaces
"   :Cl <lines>            Comment lines
"   :Ul <lines>            Uncomment lines
"
" This module handles explicit line ranges only.
"
" Block and function operations are intentionally kept
" separate so that changes to one type of operation do not
" unexpectedly affect another.
"
" User-defined Vim commands must begin with an uppercase letter.
"

" ============================================================
" INSERT SPACES
"
" :Iss <spaces> <lines>
"
" Inserts <spaces> spaces at the beginning of the current
" line and the following <lines>-1 lines.
"
" Example:
"
"   :Iss 4 3
"
"   one
"   two
"   three
"
" becomes:
"
"       one
"       two
"       three
"
" ============================================================

command! -nargs=+ Iss call InsertSpaces(<f-args>)

function! InsertSpaces(spaces, lines) abort
let spaces = str2nr(a:spaces)
let lines = str2nr(a:lines)

if spaces < 0
echoerr 'Number of spaces must be zero or greater.'
return
endif

if lines < 1
echoerr 'Number of lines must be at least 1.'
return
endif

let indent = repeat(' ', spaces)
let start = line('.')
let finish = start + lines - 1

if finish > line('$')
let finish = line('$')
endif

execute start . ',' . finish . 's/^/' . escape(indent, '') . '/'
endfunction

" ============================================================
" COMMENT EXPLICIT LINES
"
" :Cl <lines>
"
" Comments the current line and following <lines>-1 lines.
"
" The comment style is determined by GetCommentStyle()
" from style.vim.
"
" Line-comment languages:
"
"   #
"   "
"
" C-style languages are handled using /* */ block markers.
"
" ============================================================

command! -nargs=1 Cl call CommentLines(line('.'), line('.') + str2nr(<args>) - 1)

function! CommentLines(start, finish) abort
let finish = min([a:finish, line('$')])
let style = GetCommentStyle()

if style[1] ==# 'line'
call CommentLineRange(a:start, finish, style[0])
else
call CommentBlockRange(a:start, finish)
endif
endfunction

" ============================================================
" UNCOMMENT EXPLICIT LINES
"
" :Ul <lines>
"
" Uncomments the current line and following <lines>-1 lines.
"
" The comment style is determined by GetCommentStyle()
" from style.vim.
"
" ============================================================

command! -nargs=1 Ul call UncommentLines(line('.'), line('.') + str2nr(<args>) - 1)

function! UncommentLines(start, finish) abort
let finish = min([a:finish, line('$')])
let style = GetCommentStyle()

if style[1] ==# 'line'
call UncommentLineRange(a:start, finish, style[0])
else
call UncommentBlockRange(a:start, finish)
endif
endfunction

" ============================================================
" COMMENT LINE RANGE
"
" Adds a line comment marker after the existing indentation.
"
" Example:
"
"       some code
"
" becomes:
"
"       # some code
"
" Existing indentation is preserved.
"
" Already-commented lines are left unchanged.
"
" ============================================================

function! CommentLineRange(start, finish, marker) abort
for lnum in range(a:start, a:finish)
let text = getline(lnum)

" Preserve existing indentation.
let indent = matchstr(text, '^\s*')
let body = strpart(text, strlen(indent))

" Don't double-comment an already-commented line.
if body =~# '^' . escape(a:marker, '\') . '\s'
      \ || body ==# a:marker
  continue
endif

call setline(lnum, indent . a:marker . ' ' . body)

endfor
endfunction

" ============================================================
" UNCOMMENT LINE RANGE
"
" Removes a line comment marker while preserving indentation.
"
" Example:
"
"       # some code
"
" becomes:
"
"       some code
"
" ============================================================

function! UncommentLineRange(start, finish, marker) abort
for lnum in range(a:start, a:finish)
let text = getline(lnum)

" Preserve indentation while removing the comment marker.
let pattern = '^\(\s*\)' . escape(a:marker, '\') . '\s\?'

if text =~# pattern
  call setline(lnum, substitute(text, pattern, '\1', ''))
endif

endfor
endfunction

" ============================================================
" C-STYLE BLOCK COMMENT
"
" This is used by Cl when the current filetype uses C-style
" comments.
"
" Example:
"
"       one
"       two
"       three
"
" becomes:
"
"       /* one
"       two
"       three */
"
" The opening marker is placed at the beginning of the first
" line and the closing marker is placed at the end of the last
" line.
"
" ============================================================

function! CommentBlockRange(start, finish) abort
let first = getline(a:start)
let indent = matchstr(first, '^\s*')
let first_body = strpart(first, strlen(indent))

" Don't add another block marker if this already appears
" to be a C-style block.
if first_body =~# '^/*'
return
endif

call setline(
\ a:start,
\ indent . '/* ' . first_body
\ )

let last = getline(a:finish)
let last_indent = matchstr(last, '^\s*')
let last_body = strpart(last, strlen(last_indent))

call setline(
\ a:finish,
\ last_indent . last_body . ' */'
\ )
endfunction

" ============================================================
" C-STYLE BLOCK UNCOMMENT
"
" Reverses CommentBlockRange().
"
" Removes:
"
"   /*
"
" from the beginning of the first line and:
"
"   */
"
" from the end of the last line.
"
" ============================================================

function! UncommentBlockRange(start, finish) abort
let first = getline(a:start)
let last = getline(a:finish)

" Remove opening /*
if first =~# '^\s*/*\s?'
let first = substitute(
\ first,
\ '^\(\s*\)/*\s?',
\ '\1',
''
\ )

call setline(a:start, first)

endif

" Remove closing */
if last =~# '\s*/\s*$'
let last = substitute(
\ last,
\ '\s*/\s*$',
\ '',
''
\ )

call setline(a:finish, last)

endif
endfunction

