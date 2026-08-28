" ~/.vim/helper.vim
"
" Vim Editing Helpers
"
" Main loader for the Vim Editing Helpers modules.
"
" Commands provided by the modules:
"
"   :Iss <spaces> <lines>  Insert spaces
"   :Cl <lines>            Comment lines
"   :Ul <lines>            Uncomment lines
"   :Cb                    Comment block
"   :Ub                    Uncomment block
"   :Cf                    Comment function/method/subroutine
"   :Uf                    Uncomment function/method/subroutine
"
" User-defined Vim commands must begin with an uppercase letter.
"

" ============================================================
" LOAD HELPER MODULES
" ============================================================

let s:helper_dir = expand('<sfile>:p:h') . '/helper'

" Comment style detection
if filereadable(s:helper_dir . '/style.vim')
execute 'source ' . fnameescape(s:helper_dir . '/style.vim')
endif

" Line editing helpers
if filereadable(s:helper_dir . '/line.vim')
execute 'source ' . fnameescape(s:helper_dir . '/line.vim')
endif

" Block editing helpers
if filereadable(s:helper_dir . '/block.vim')
execute 'source ' . fnameescape(s:helper_dir . '/block.vim')
endif

" Function/method/subroutine helpers
if filereadable(s:helper_dir . '/function.vim')
execute 'source ' . fnameescape(s:helper_dir . '/function.vim')
endif

