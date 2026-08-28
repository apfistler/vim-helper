" ~/.vim/helper/style.vim
"
" Vim Editing Helpers
"
" Comment style detection.
"
" This module determines how comments should be represented
" for the current Vim filetype.
"
" Return format:
"
"   [comment_marker, comment_type]
"
" Where comment_type is either:
"
"   'line'  - single-line comment marker
"   'block' - C-style /* */ block comments
"
" Unknown filetypes default to # comments.
"

" ============================================================
" GET COMMENT STYLE
" ============================================================
"
" Returns the appropriate comment style for the current
" buffer's Vim filetype.
"
" Examples:
"
"   Python      -> ['#',  'line']
"   Shell       -> ['#',  'line']
"   Perl        -> ['#',  'line']
"   YAML        -> ['#',  'line']
"   Vimscript   -> ['"',  'line']
"   C           -> ['/*', 'block']
"   JavaScript  -> ['/*', 'block']
"   CSS         -> ['/*', 'block']
"   Unknown     -> ['#',  'line']
"
" ============================================================

function! GetCommentStyle() abort
let ft = &filetype

" ----------------------------------------------------------
" Vimscript
" ----------------------------------------------------------

if ft ==# 'vim'
return ['"', 'line']
endif

" ----------------------------------------------------------
" Shell / Python / Perl / YAML and similar languages
" ----------------------------------------------------------

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

" ----------------------------------------------------------
" C-style block comments
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
return ['/*', 'block']
endif

" ----------------------------------------------------------
" Unknown filetypes
"
" Default to shell/Python-style # comments.
" ----------------------------------------------------------

return ['#', 'line']
endfunction

