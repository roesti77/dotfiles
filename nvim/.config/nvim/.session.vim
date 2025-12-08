let SessionLoad = 1
let s:so_save = &g:so | let s:siso_save = &g:siso | setg so=0 siso=0 | setl so=-1 siso=-1
let v:this_session=expand("<sfile>:p")
silent only
silent tabonly
cd ~/dotfiles/nvim/.config/nvim
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
let s:shortmess_save = &shortmess
if &shortmess =~ 'A'
  set shortmess=aoOA
else
  set shortmess=aoO
endif
badd +36 ~/dotfiles/nvim/.config/nvim/lua/plugins/coding/none-ls.lua
badd +239 ~/dotfiles/nvim/.config/nvim/lua/plugins/coding/lsp.lua
badd +110 ~/dotfiles/nvim/.config/nvim/lua/plugins/coding/treesitter.lua
badd +1 ~/dotfiles/nvim/.config/nvim/lua/plugins/coding/cmp-cmdline.lua
badd +35 health://
badd +197 ~/dotfiles/nvim/.config/nvim/lua/plugins/debug/dap.lua
badd +1 ~/dotfiles/nvim/.config/nvim/lua/plugins/debug/go.lua
badd +1 ~/dotfiles/nvim/.config/nvim/lua/plugins/debug/python.lua
badd +27 ~/dotfiles/nvim/.config/nvim/init.lua
badd +4 ~/dotfiles/nvim/.config/nvim/lua/plugins/coding-languages/jinja.lua
badd +2 ~/dotfiles/nvim/.config/nvim/lua/plugins/coding/outline.lua
badd +25 ~/dotfiles/nvim/.config/nvim/lua/core/keymaps.lua
badd +1 ~/dotfiles/nvim/.config/nvim/lua/core/completition.lua
badd +34 ~/dotfiles/nvim/.config/nvim/lua/core/options.lua
badd +17 ~/dotfiles/nvim/.config/nvim/lua/plugins/core/colortheme.lua
badd +5 ~/dotfiles/nvim/.config/nvim/lua/plugins/ai/codeium.lua
badd +20 ~/dotfiles/nvim/.config/nvim/lua/plugins/tools/obsidian.lua
badd +1 ~/dotfiles/nvim/.config/nvim/lua/plugins/coding/test.lua
badd +1 ~/dotfiles/nvim/.config/nvim/lua/plugins/debug/dap-ui.lua
badd +1 ~/dotfiles/nvim/.config/nvim/lua/plugins/debug/virtual-text.lua
badd +1 ~/dotfiles/nvim/.config/nvim/.stylua.toml
badd +31 ~/dotfiles/nvim/.config/nvim/lua/plugins/tools/gitlab-review.lua
badd +1 ~/dotfiles/nvim/.config/nvim/lua/plugins/core/lualine.lua
badd +37 ~/dotfiles/nvim/.config/nvim/lua/plugins/core/snacks.lua
badd +1 ~/dotfiles/nvim/.config/nvim/lua/plugins/core/fugitive.lua
badd +1 ~/dotfiles/nvim/.config/nvim/lua/plugins/core/git-blame.lua
badd +1 ~/dotfiles/nvim/.config/nvim/lua/plugins/core/git-stuff.lua
badd +1 ~/dotfiles/nvim/.config/nvim/lua/plugins/core/lazydocker.lua
badd +21 ~/dotfiles/nvim/.config/nvim/lua/plugins/core/bufferline.lua
badd +9 ~/dotfiles/nvim/.config/nvim/lua/plugins/coding/refactor.lua
badd +1 ~/dotfiles/nvim/.config/nvim/lua/plugins/ai/opencode_.lua
badd +1 ~/dotfiles/nvim/.config/nvim/lua/plugins/ai/opencode.lua
badd +40 ~/dotfiles/nvim/.config/nvim/lua/plugins/coding/symbols-outline.lua
argglobal
%argdel
edit ~/dotfiles/nvim/.config/nvim/lua/plugins/coding/symbols-outline.lua
wincmd t
let s:save_winminheight = &winminheight
let s:save_winminwidth = &winminwidth
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
argglobal
balt ~/dotfiles/nvim/.config/nvim/lua/plugins/ai/opencode.lua
setlocal foldmethod=manual
setlocal foldexpr=v:lua.vim.treesitter.foldexpr()
setlocal foldmarker={{{,}}}
setlocal foldignore=#
setlocal foldlevel=99
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldenable
silent! normal! zE
sil! 12,15fold
sil! 17,24fold
sil! 4,25fold
sil! 31,34fold
sil! 37,40fold
sil! 46,54fold
sil! 45,55fold
sil! 44,56fold
sil! 3,57fold
sil! 1,58fold
let &fdl = &fdl
let s:l = 40 - ((24 * winheight(0) + 25) / 50)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 40
normal! 036|
tabnext 1
if exists('s:wipebuf') && len(win_findbuf(s:wipebuf)) == 0 && getbufvar(s:wipebuf, '&buftype') isnot# 'terminal'
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20
let &shortmess = s:shortmess_save
let &winminheight = s:save_winminheight
let &winminwidth = s:save_winminwidth
let s:sx = expand("<sfile>:p:r")."x.vim"
if filereadable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &g:so = s:so_save | let &g:siso = s:siso_save
nohlsearch
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
