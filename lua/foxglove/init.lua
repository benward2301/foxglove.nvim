local M = {}

local palettes = require('foxglove._palettes')
local specs = require('foxglove._specs')
local theme = require('foxglove._theme')
local state = require('foxglove._state')
local editor = require('foxglove._editor')

M.config = {}

M.shell_script = vim.fn.stdpath('data') .. '/foxglove.sh'

M.palette = nil
M.roles = nil

local half_name

function M.setup(opts)
  M.config = opts or {}
  local want = { palette = half_name('palette'), spec = half_name('spec') }
  if not (want.palette or want.spec or theme.current or state.remembered()) then
    return
  end
  local ok, err = pcall(theme.switch, want)
  if not ok then
    vim.notify(tostring(err), vim.log.levels.ERROR)
  end
end

function M.highlight(group, fn)
  theme.highlight(group, fn, M.palette, M.roles)
end

function M.register_palette(palette)
  palettes.register(palette)
end

function M.register_spec(spec)
  specs.register(spec)
end

function half_name(key)
  local value = M.config[key]
  if value == nil or type(value) == 'string' then
    return value
  end
  vim.notify(('foxglove: %s wants the name of a %s, got a %s'):format(key, key, type(value)),
    vim.log.levels.WARN)
  return nil
end

local source = debug.getinfo(1, 'S').source:sub(2)
local ROOT = source:match('^(.*)/lua/foxglove/init%.lua$')
if not ROOT then
  error('foxglove: cannot resolve plugin root from ' .. source)
end

local function load_bundled(dir, registry)
  local at = ROOT .. '/' .. dir
  local ok, entries = pcall(vim.fn.readdir, at)
  local bundled = {}
  for _, entry in ipairs(ok and entries or {}) do
    if entry:match('%.lua$') then
      local loaded, one = pcall(dofile, at .. '/' .. entry)
      if loaded and type(one) == 'table' then
        bundled[#bundled + 1] = one
      else
        vim.notify(('foxglove: %s/%s did not load: %s'):format(dir, entry, tostring(one)),
          vim.log.levels.WARN)
      end
    end
  end
  registry.register(bundled)
end

load_bundled('palettes', palettes)
load_bundled('specs', specs)
editor.load_integrations(ROOT .. '/lua/foxglove/integrations')

return M
