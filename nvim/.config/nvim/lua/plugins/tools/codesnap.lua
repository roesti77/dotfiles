return {
  'mistricky/codesnap.nvim',
  build = 'make build_generator',
  tag = 'v2.0.1',
  enabled = false, -- native .so crasht nvim (SIGKILL); enable nach 'make build_generator' im plugin-dir
}
