call plug#begin()

Plug 'vim-airline/vim-airline'
Plug 'machakann/vim-sandwich'
Plug 'ziglang/zig.vim'

call plug#end()

set background = "dark"
set termguicolors
set number
set relativenumber

colorscheme distinguished

let g:sandwich#recipes = deepcopy(g:sandwich#default_recipes)
" Add: Press sa{motion/textobject}{addition}. For example, a key sequence saiw( makes foo to (foo).
" Delete: Press sdb or sd{deletion}. For example, key sequences sdb or sd( makes (foo) to foo. sdb searches a set of surrounding automatically.
" Replace: Press srb{addition} or sr{deletion}{addition}. For example, key sequences srb" or sr(" makes (foo) to "foo".
