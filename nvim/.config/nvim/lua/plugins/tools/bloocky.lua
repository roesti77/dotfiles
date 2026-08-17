return {
  'atiladefreitas/bloocky',
  event = 'VeryLazy',
  opts = {
    week_start = 'monday',
    -- Read-only: shows dooing todos on their due date, never writes back
    integrations = {
      dooing = { enabled = true },
    },
  },
}
