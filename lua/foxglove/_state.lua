
local env = require('foxglove._env')

local M = {}

M.dir = (env('XDG_STATE_HOME') or ((env('HOME') or '.') .. '/.local/state')) .. '/foxglove'

local FILE = '/theme'

function M.remember(theme)
  vim.fn.mkdir(M.dir, 'p')
  local f = assert(io.open(M.dir .. FILE, 'w'))
  for _, key in ipairs({ 'palette', 'spec' }) do
    if theme[key] then
      f:write(key, '=', theme[key], '\n')
    end
  end
  f:close()
end

function M.remembered()
  local f = io.open(M.dir .. FILE, 'r')
  if not f then
    return nil
  end
  local out = {}
  for line in f:lines() do
    local key, value = line:match('^(%w+)=(.+)$')
    if key then
      out[key] = value
    end
  end
  f:close()
  return next(out) and out or nil
end

return M
