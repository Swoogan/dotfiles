call plug#begin()

Plug 'vim-airline/vim-airline'
Plug 'machakann/vim-sandwich'
Plug 'ziglang/zig.vim'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'machakann/vim-highlightedyank'

call plug#end()

set background = "dark"
set termguicolors
set number
set relativenumber
set splitbelow
set splitright
set smartindent
set hidden
set ts=8 sts=4 sw=4 expandtab

colorscheme distinguished

let g:sandwich#recipes = deepcopy(g:sandwich#default_recipes)
" Add: Press sa{motion/textobject}{addition}. For example, a key sequence saiw( makes foo to (foo).
" Delete: Press sdb or sd{deletion}. For example, key sequences sdb or sd( makes (foo) to foo. sdb searches a set of surrounding automatically.
" Replace: Press srb{addition} or sr{deletion}{addition}. For example, key sequences srb" or sr(" makes (foo) to "foo".
let mapleader=","

augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
augroup END

"" Mappings
inoremap jk <Esc>

"" Simplified window management
map <C-h> <C-W>h
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-l> <C-W>l
map <Leader>a <C-W>_
map <Leader>i <C-W>=
" launch a terminal
map <Leader>t :10split\|term<Cr>a

"" Custom
map <Leader>r ylp
map <Leader>nl :nohl<Cr>

nmap <Leader>y "+y
nmap <Leader>yy "+yy
nmap <Leader>p "+p
nmap <Leader>P "+P
nmap <C-/> m`I//<Esc>``

if has('nvim')
  tnoremap <Esc> <C-\><C-n>
  tnoremap <M-[> <Esc>
  tnoremap <C-v><Esc> <Esc>
endif

" FZF
nmap <Leader>rg :Rg<Cr>
nmap <Leader>cp :Files<Cr>

" Insert mode completion
imap <c-x><c-k> <plug>(fzf-complete-word)
imap <c-x><c-l> <plug>(fzf-complete-line)
imap <c-x><c-f> <plug>(fzf-complete-path)
imap <c-x><c-j> <plug>(fzf-complete-file-rg)

" END FZF
