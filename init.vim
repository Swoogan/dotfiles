call plug#begin()

Plug 'lokaltog/vim-distinguished'
Plug 'vim-airline/vim-airline'
Plug 'machakann/vim-sandwich'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'machakann/vim-highlightedyank'
" Plug 'tpope/vim-commentary'
" Plug 'tpope/vim-unimpaired'
" Plug 'tpope/vim-repeat'
Plug 'sheerun/vim-polyglot'
Plug 'neovim/nvim-lspconfig'
Plug 'editorconfig/editorconfig-vim'

call plug#end()


set background = "dark"
set termguicolors
set number          " show the current line number (w/ relative on)
set relativenumber  " show relative line numbers
set splitbelow      " new horizontal windows appear on the bottom
set splitright      " new vertical windows appear on the right
set smartindent
set cursorline      " highlights current line
set hidden
set smartcase       " searching case insensitive unless mixed case
set nowritebackup   " Prevent vim from writing to new files every time
set tabstop=8
set sts=4
set shiftwidth=4
set expandtab       " converts tab presses to spaces
set iskeyword+=-    " treat - seperated words as a word object
set iskeyword+=_    " treat _ seperated words as a word object
set inccommand=nosplit    " shows effects of substitutions 
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

"" Simplified window management
map <C-h> <C-W>h
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-l> <C-W>l

" launch a terminal
if has('win32') || has('win64')
    noremap <Leader>t :10split\|term://powershell<Cr>a
else
    noremap <Leader>t :10split\|term<Cr>a
endif 

"" Custom
" Repeats the character under the cursor
noremap <Leader>r ylp
" Removes search highlighting
noremap <Leader>nl :nohl<Cr>
" Save file
nnoremap <leader>w <Esc>:w<cr>
" Save and quit
nnoremap <leader>x <Esc>:x<cr>


" Yanks selection to system clipboard
nnoremap <Leader>y "+y
" Yanks selection to system clipboard
vnoremap <Leader>y "+y  
" Yanks line to system clipboard
nnoremap <Leader>yy "+yy 
" Pastes from system clipboard
nnoremap <Leader>p "+p
" Pastes from system clipboard
nnoremap <Leader>P "+P

" Edit vim config in split
nnoremap <Leader>ec :vsplit $MYVIMRC<Cr>
" Source vim config
nnoremap <Leader>sc :source $MYVIMRC<Cr>

" Uncomment line
nnoremap <C-k><C-u> :normal 02x<Cr>
vnoremap <C-k><C-u> :normal 02x<Cr>
nnoremap <C-k>u :normal ^2x<Cr>
vnoremap <C-k>u :normal ^2x<Cr>
" Comment line
nnoremap <C-k>c :normal 0I// <Cr>
vnoremap <C-k>c :normal 0I// <Cr>
" Adds c-style comment to the beginning of a line
nnoremap <C-/> m`I//<Esc>``

" Remap keys in terminal mode
tnoremap <Esc> <C-\><C-n>
tnoremap <M-[> <Esc>
tnoremap <C-v><Esc> <Esc>

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

command! DiffOrig vertical new | set buftype=nofile | read # | 0d_ | diffthis | wincmd p | diffthis
