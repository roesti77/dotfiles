-- Deterministischer RPC-Socket, damit externe Tools (z. B. Claude nach einem
-- `git worktree add`) diesem nvim etwas sagen koennen -- siehe zsh/bin/wt-open.
-- Der Socket ist repo-bezogen: bei mehreren nvims ist so eindeutig, welches
-- fuer welches Repo zustaendig ist. Ist der Name belegt (zweites nvim im selben
-- Repo), gewinnt das erste und wir bleiben still.

local root = vim.fs.root(0, '.git')
if not root then
    return
end

local dir = vim.fn.stdpath 'cache' .. '/servers'
vim.fn.mkdir(dir, 'p')

-- Repo-Pfad -> flacher Dateiname
local name = root:gsub('^/', ''):gsub('/', '%%')
local sock = string.format('%s/%s.sock', dir, name)

-- Verwaister Socket eines abgestuerzten nvim: serverstart wuerde daran scheitern.
if vim.uv.fs_stat(sock) and not pcall(vim.fn.sockconnect, 'pipe', sock, { rpc = true }) then
    vim.fn.delete(sock)
end

pcall(vim.fn.serverstart, sock)
