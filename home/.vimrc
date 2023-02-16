set nocompatible              " be iMproved, required

let g:polyglot_disabled = ['hcl']

syntax on
filetype plugin indent on

set noerrorbells                " No beeps
set backspace=indent,eol,start  " Makes backspace key more powerful.
set showcmd                     " Show me what I'm typing
set showmode                    " Show current mode.

set noswapfile                  " Don't use swapfile
set nobackup                            " Don't create annoying backup files
set splitright                  " Split vertical windows right to the current windows
set splitbelow                  " Split horizontal windows below to the current windows
set encoding=utf-8              " Set default encoding to UTF-8
set autowrite                   " Automatically save before :next, :make etc.
set autoread                    " Automatically reread changed files without asking me anything
set laststatus=2

set fileformats=unix,dos,mac    " Prefer Unix over Windows over OS 9 formats

set showmatch                   " Do not show matching brackets by flickering
set incsearch                   " Shows the match while typing
set hlsearch                    " Highlight found searches
set ignorecase                  " Search case insensitive...
set smartcase                   " ... but not when search pattern contains upper case characters

set switchbuf=usetab,newtab     " open new buffers always in new tabs

nnoremap <F3> :set invpaste paste?<CR>
set pastetoggle=<F3>

map <Leader><Space> :let @/=""<CR>
nnoremap <silent> <Leader>= :GFiles! --exclude-standard --cached --others<CR>
nnoremap <silent> <Leader>- :Files!<CR>
nnoremap <silent> <Leader>0 :GFiles!?<CR>

set number                      " Show line numbers
set norelativenumber            " Show numbers relative to current line
"map <silent> <F2> :set invnumber<cr>
noremap <F2> :set invnumber<CR>
inoremap <F2> <C-O>:set invnumber<CR>

set textwidth=0 wrapmargin=0
set nowrap " Don't wrap lines

let g:is_bash=1

nnoremap <F7> mzgg=G'z
inoremap <F7> <ESC>mzgg=G'z

nnoremap <F4> :%!jq --tab .<CR>

inoremap <silent> <PageUp> <ESC><PageUp>
inoremap <silent> <PageDown> <ESC><PageDown>

function! ClearUndo()
	let choice = confirm("Clear undo information?", "&Yes\n&No", 2)
	if choice == 1
		let old_undolevels = &undolevels
		set undolevels=-1
		exe "normal a \<Bs>\<Esc>"
		let &undolevels = old_undolevels
		echo "done."
	endif
endfunction
map <Leader>dU :call ClearUndo()<CR>

" base16 color
set background=dark
let base16colorspace=256
colorscheme base16-default-dark

set t_Co=256

" helps activete vim-airline
set laststatus=2
" make insert mode pop instantly
set ttimeoutlen=50
" vim-indent-guides
let g:indent_guides_start_level=1
let g:indent_guides_enable_on_vim_startup=1
let g:indent_guides_auto_colors=0
let g:indent_guides_guide_size=1
"autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd ctermbg=16 guibg=#000000 "rgb=0,0,0
"autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd ctermbg=233 guibg=#121212 "rgb=18,18,18
"autocmd VimEnter,Colorscheme * :hi IndentGuidesEven ctermbg=234 guibg=#1c1c1c "rgb=28,28,28
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven ctermbg=235 guibg=#262626 "rgb=38,38,38
let g:js_indent_log = 0

let g:html_exclude_tags = ['html', 'style', 'script', 'body']

au BufRead,BufNewFile *.tag setfiletype html

"autocmd BufEnter * :syntax sync fromstart
" toggle syntax highlighting fix in long files
noremap <F8> <Esc>:syntax sync fromstart<CR>
inoremap <F8> <C-o>:syntax sync fromstart<CR>

" search for visually selected text
vnoremap // y/<C-R>"<CR>

vnoremap <silent> * :<C-U>
  \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
  \gvy/<C-R><C-R>=substitute(
  \escape(@", '/\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
  \gV:call setreg('"', old_reg, old_regtype)<CR>

" use OS clipboard
"set clipboard=unnamedplus

let g:javascript_opfirst = 1

" if hidden is not set, TextEdit might fail.
set hidden

" Some servers have issues with backup files, see #649
set nobackup
set nowritebackup

" Better display for messages
set cmdheight=2

" You will have bad experience for diagnostic messages when it's default 4000.
set updatetime=300

" don't give |ins-completion-menu| messages.
set shortmess+=c

" always show signcolumns
set signcolumn=yes

" Use tab for trigger completion with characters ahead and navigate.
" Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
" Coc only does snippet and additional edit on confirm.
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
" Or use `complete_info` if your vim support it, like:
" inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"

" Use `[g` and `]g` to navigate diagnostics
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Highlight symbol under cursor on CursorHold
autocmd CursorHold * silent call CocActionAsync('highlight')

" Remap for rename current word
nmap <leader>rn <Plug>(coc-rename)

" Remap for format selected region
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Remap for do codeAction of selected region, ex: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap for do codeAction of current line
nmap <leader>ac  <Plug>(coc-codeaction)
" Fix autofix problem of current line
nmap <leader>qf  <Plug>(coc-fix-current)

" Create mappings for function text object, requires document symbols feature of languageserver.
xmap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap if <Plug>(coc-funcobj-i)
omap af <Plug>(coc-funcobj-a)

" Use <C-d> for select selections ranges, needs server support, like: coc-tsserver, coc-python
"nmap <silent> <C-d> <Plug>(coc-range-select)
"xmap <silent> <C-d> <Plug>(coc-range-select)

" Use `:Format` to format current buffer
command! -nargs=0 Format :call CocAction('format')

" Use `:Fold` to fold current buffer
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" use `:OR` for organize import of current buffer
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" Add status line support, for integration with other plugin, checkout `:h coc-status`
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Using CocList
" Show all diagnostics
nnoremap <silent> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions
nnoremap <silent> <space>e  :<C-u>CocList extensions<cr>
" Show commands
nnoremap <silent> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document
nnoremap <silent> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols
nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list
nnoremap <silent> <space>p  :<C-u>CocListResume<CR>

"let g:airline#extensions#tabline#enabled = 1
"let g:airline#extensions#tabline#formatter = 'default'
"let g:airline#extensions#tabline#formatter = 'unique_tail_improved'

let g:terraform_align=1
let g:terraform_fmt_on_save=1

vnoremap > >gv
vnoremap < <gv

"augroup numbertoggle
  "autocmd!
  "autocmd BufEnter,FocusGained,InsertLeave,WinEnter * if &nu | set rnu   | endif
  "autocmd BufLeave,FocusLost,InsertEnter,WinLeave   * if &nu | set nornu | endif
"augroup END
autocmd BufRead,BufNewFile Dockerfile.*,Dockerfile-* set filetype=dockerfile

autocmd BufNewFile,BufRead *.nomad     set filetype=terraform
let g:vim_jsx_pretty_colorful_config = 1
let g:indentLine_fileTypeExclude = [ "json" ]
let g:vim_json_syntax_conceal=1
let g:vim_markdown_new_list_item_indent = 2

let g:fzf_preview_window = ['up:50%:hidden', 'ctrl-/']

