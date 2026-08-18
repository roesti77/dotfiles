-- Deterministischer RPC-Socket, damit externe Tools (z. B. Claude nach einem
-- `git worktree add`) diesem nvim etwas sagen koennen -- siehe zsh/bin/wt-open.
-- Der Socket ist ortsbezogen: bei mehreren nvims ist so eindeutig, welches
-- wofuer zustaendig ist. Ist der Name belegt (zweites nvim am selben Ort),
-- gewinnt das erste und wir bleiben still.
--
-- Ohne Repo (der Ueberordner mit mehreren Repos darin ist selbst keins) wird auf
-- das Startverzeichnis gekeyed -- sonst gaebe es fuer genau diesen Fall gar
-- keinen Kanal. wt-open sucht von einem Repo aus aufwaerts und findet beides.

local root = vim.fs.root(0, '.git') or vim.uv.cwd()
if not root then
    return
end

local dir = vim.fn.stdpath 'cache' .. '/servers'
vim.fn.mkdir(dir, 'p')

-- Pfad -> flacher Dateiname
local name = root:gsub('^/', ''):gsub('/', '%%')
local sock = string.format('%s/%s.sock', dir, name)

-- Verwaister Socket eines abgestuerzten nvim: serverstart wuerde daran scheitern.
if vim.uv.fs_stat(sock) and not pcall(vim.fn.sockconnect, 'pipe', sock, { rpc = true }) then
    vim.fn.delete(sock)
end

pcall(vim.fn.serverstart, sock)
