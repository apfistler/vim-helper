" ~/.vim/helper.vim
"
" Small editing helpers

" ------------------------------------------------------------
" :Iss <spaces> <lines>
"
" Insert <spaces> spaces at the beginning of the current line
" and the following <lines>-1 lines.
"
" Example:
"   :Iss 4 3
"
" Inserts four spaces on three lines.
" ------------------------------------------------------------

command! -nargs=+ Iss call InsertSpaces(<f-args>)

function! InsertSpaces(spaces, lines)
  let indent = repeat(' ', a:spaces)
  execute '.,+' . (a:lines - 1) . 's/^/' . escape(indent, '\') . '/'
endfunction


" ------------------------------------------------------------
" :Cl <lines>
"
" Comment out the current line and the following <lines>-1 lines.
"
" Currently uses // as the comment prefix.
"
" Example:
"   :Cl 3
" ------------------------------------------------------------

command! -nargs=1 Cl execute '.,+' . (<args> - 1) . 'normal! I// '


" ------------------------------------------------------------
" :Uc <lines>
"
" Uncomment the current line and the following <lines>-1 lines.
"
" Removes // comments from the beginning of each line.
"
" Example:
"   :Uc 3
" ------------------------------------------------------------

command! -nargs=1 Uc execute '.,+' . (<args> - 1) . 's/^\(\s*\)\/\/\s\?/\1/'
