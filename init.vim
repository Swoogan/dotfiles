call plug#begin()

Plug 'vim-airline/vim-airline'
Plug 'machakann/vim-sandwich'
Plug 'ziglang/zig.vim'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'machakann/vim-highlightedyank'
Plug 'PProvost/vim-ps1'

call plug#end()

set background = "dark"
set termguicolors
set number
set relativenumber
set splitbelow
set splitright
set smartindent
set hidden
set smartcase
set tabstop=8
set sts=4
set shiftwidth=4
set expandtab
set iskeyword+=-                                 " treat - seperated words as a word object
set iskeyword+=_                                 " treat _ seperated words as a word object
 
colorscheme distinguished

let g:sandwich#recipes = deepcopy(g:sandwich#default_recipes)
" Add: Press sa{motion/textobject}{addition}. For example, a key sequence saiw( makes foo to (foo).
" Delete: Press sdb or sd{deletion}. For example, key sequences sdb or sd( makes (foo) to foo. sdb searches a set of surrounding automatically.
" Replace: Press srb{addition} or sr{deletion}{addition}. For example, key sequences srb" or sr(" makes (foo) to "foo".
let mapleader=","

" Auto commands
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
augroup END

augroup markdown
  autocmd!
  autocmd BufNewFile,BufRead *.md setlocal wrap spell
augroup END

augroup zig
  autocmd!
  autocmd FileType zig :iabbrev <buffer> oom return error.OutOfMemory; 
augroup END

"" Mappings
inoremap jk <Esc>

"" Simplified window management
map <C-h> <C-W>h
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-l> <C-W>l
" launch a terminal
noremap <Leader>t :10split\|term<Cr>a

"" Custom
noremap <Leader>r ylp
noremap <Leader>nl :nohl<Cr>

nnoremap <Leader>y "+y
nnoremap <Leader>yy "+yy
nnoremap <Leader>p "+p
nnoremap <Leader>P "+P
nnoremap <C-/> m`I//<Esc>``
nnoremap <Leader>ec :vsplit $MYVIMRC<Cr>
nnoremap <Leader>sc :source $MYVIMRC<Cr>

if has('nvim')
  tnoremap <Esc> <C-\><C-n>
  tnoremap <M-[> <Esc>
  tnoremap <C-v><Esc> <Esc>
"  if has('win32') || has('win64')
"      set shell="powershell"
"  endif 
endif

" FZF
nnoremap <Leader>rg :Rg<Cr>
nnoremap <Leader>cp :Files<Cr>

" Insert mode completion
imap <c-x><c-k> <plug>(fzf-complete-word)
imap <c-x><c-l> <plug>(fzf-complete-line)
imap <c-x><c-f> <plug>(fzf-complete-path)
imap <c-x><c-j> <plug>(fzf-complete-file-rg)

" END FZF

"" Functions

" Setup cache directory so .swp files aren't in the cwd
if !isdirectory(expand("$HOME/.cache/vim/swap"))
  call mkdir(expand("$HOME/.cache/vim/swap"), "p")
endif
set directory=$HOME/.cache/vim/swap


