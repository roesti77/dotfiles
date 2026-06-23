return {
  'wallpants/ghost-text.nvim',
  event = 'VeryLazy',
  build = 'bun install',
  opts = {
    port = 4001,
    autostart = true,
    filetype_domains = {
      markdown = {
        '*github.com*',
        '*reddit.com*',
        '*stackoverflow.com*',
        '*stackexchange.com*',
        '*chatgpt.com*',
        '*claude.ai*',
        '*atlassian.net*',
        '*confluence*',
      },
    },
  },
}
