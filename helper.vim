" ~/.vim/plugin/helpers.vim
"
" Small editing helpers

" ------------------------------------------------------------
" :iss <spaces> <lines>
"
" Insert <spaces> spaces at the beginning of the current line
" and the following <lines>-1 lines.
"
" Example:
"   :iss 4 3
"
" Inserts four spaces on three lines.
" ------------------------------------------------------------

command! -nargs=+ iss call InsertSpaces(<f-args>)

function! InsertSpaces(spaces, lines)
  let indent = repeat(' ', a:spaces)
  execute '.,+' . (a:lines - 1) . 's/^/' . escape(indent, '\') . '/'
endfunction


" ------------------------------------------------------------
" :co <lines>
"
" Comment out the current line and the following <lines>-1 lines.
"
" Uses Vim's comment mechanism based on the current filetype.
"
" Example:
"   :co 3
" ------------------------------------------------------------

command! -nargs=1 co execute '.,+' . (<args> - 1) . 'normal! I// '


" ------------------------------------------------------------
" :uc <lines>
"
" Uncomment the current line and the following <lines>-1 lines.
"
" Removes // comments from the beginning of each line.
"
" Example:
"   :uc 3
" ------------------------------------------------------------

command! -nargs=1 uc execute '.,+' . (<args> - 1) . 's/^\(\s*\)\/\/\s\?/\1/'
