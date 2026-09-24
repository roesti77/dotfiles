-- Macht den Claude-Harness in avante nutzbar, ohne Claude Code.
--
-- Skills (~/.claude/skills/*/SKILL.md) und Agenten (~/.claude/agents/*.md) sind
-- schlichtes Markdown: ein Frontmatter mit `name` und `description`, darunter der
-- Anweisungstext. Nichts daran haengt an Claude Code -- nur die Laufzeit, die sie
-- bisher gelesen hat. avantes Shortcuts erwarten genau diese drei Angaben und
-- werden im Chat mit `#name` ausgeloest.
--
-- Damit stehen Skills und Agenten auf jedem Rechner zur Verfuegung, egal welcher
-- Provider gerade aktiv ist -- auch dort, wo Claude Code nicht laufen darf.
local M = {}

---Liest `name` und `description` aus dem Frontmatter und gibt den Rumpf zurueck.
---Zeilenweise statt per Pattern: `description` steht oft als letzte Zeile direkt
---vor dem schliessenden `---`, und sieben Dateien nutzen YAML-Blockskalare
---(`>-`, `|`), deren Wert erst in den eingerueckten Folgezeilen steht.
---@param lines string[]
---@return table fields, string body
local function parse_frontmatter(lines)
  if lines[1] ~= '---' then
    return {}, table.concat(lines, '\n')
  end

  local function unquote(value)
    return value:match '^"(.*)"$' or value:match "^'(.*)'$" or value
  end

  local fields, block_key = {}, nil
  local index = 2
  while index <= #lines and lines[index] ~= '---' do
    local line = lines[index]
    local key, value = line:match '^([%w_%-]+):%s*(.*)$'
    if key then
      if value == '>' or value == '>-' or value == '|' or value == '|-' then
        fields[key], block_key = '', key
      else
        fields[key], block_key = unquote(value), nil
      end
    elseif block_key and line:match '^%s+%S' then
      local continuation = vim.trim(line)
      fields[block_key] = fields[block_key] == '' and continuation or (fields[block_key] .. ' ' .. continuation)
    end
    index = index + 1
  end

  return fields, table.concat(vim.list_slice(lines, index + 1), '\n')
end

---@param path string
---@param fallback_name string
---@return table|nil
local function read_entry(path, fallback_name)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or type(lines) ~= 'table' then
    return nil
  end
  local fields, body = parse_frontmatter(lines)
  local name, description = fields.name, fields.description or ''
  body = vim.trim(body)
  if body == '' then
    return nil
  end
  return {
    name = name or fallback_name,
    description = description,
    details = description,
    prompt = body,
  }
end

---Sammelt Skills und Agenten als avante-Shortcuts.
---Fehlende Verzeichnisse sind kein Fehler -- nicht jeder Rechner hat den Harness.
---@return table[]
function M.shortcuts()
  local shortcuts, seen = {}, {}

  -- Nur `~` aufloesen, nicht die Wildcards: vim.fn.expand wuerde die Muster
  -- selbst ersetzen und einen newline-getrennten String liefern, den glob
  -- danach nicht mehr findet.
  local home = vim.fn.expand '~'
  local sources = {
    { glob = home .. '/.claude/skills/*/SKILL.md', kind = 'skill', name_from = ':h:t' },
    { glob = home .. '/.claude/agents/*.md', kind = 'agent', name_from = ':t:r' },
  }

  for _, source in ipairs(sources) do
    for _, path in ipairs(vim.fn.glob(source.glob, false, true)) do
      local entry = read_entry(path, vim.fn.fnamemodify(path, source.name_from))
      if entry then
        -- Skill und Agent koennen gleich heissen. Statt einen still zu
        -- verlieren, bekommt der zweite seine Art als Suffix.
        if seen[entry.name] then
          entry.name = entry.name .. '-' .. source.kind
        end
        seen[entry.name] = true
        table.insert(shortcuts, entry)
      end
    end
  end

  table.sort(shortcuts, function(a, b)
    return a.name < b.name
  end)
  return shortcuts
end

return M
