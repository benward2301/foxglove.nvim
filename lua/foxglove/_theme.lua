
local palettes = require('foxglove._palettes')
local specs = require('foxglove._specs')
local state = require('foxglove._state')
local derive = require('foxglove._derive').derive
local build = require('foxglove._highlights')
local hook = require('foxglove._hook')
local editor = require('foxglove._editor')

local M = {}

M.SCHEME = 'foxglove'

M.current = nil

M.palette = nil

M.spec = nil

local DEFAULT = { palette = palettes.default, spec = specs.default }

local overrides = {}

local pending

local carried_over, switch_through_colorscheme, as_foxglove_error, compose
local render_composed, settle, announce_render, announce_theme_change
local override_highlight, overridden_highlights

local function pick(want_half, from_half, default)
  return want_half or from_half or default
end

function M.resolve(want)
  local from = M.current or carried_over()
  want = want or {}
  local out = {
    palette = pick(want.palette, from.palette, DEFAULT.palette),
    spec = pick(want.spec, from.spec, DEFAULT.spec),
  }
  palettes.resolve(out.palette)
  specs.resolve(out.spec)
  return out
end

function M.render(want)
  local target = M.resolve(want)
  local preview = want and want.preview or false
  local composed = compose(target)
  local palette = render_composed(composed, preview)
  if not preview then
    settle(target)
  end
  announce_render(target)
  return palette
end

function M.switch(want)
  local ok, result = pcall(switch_through_colorscheme, want)
  if not ok then
    error(as_foxglove_error(result), 0)
  end
  return result
end

function M.enter_colorscheme(want)
  local stashed = pending
  pending = nil
  local target = M.resolve(want or stashed)
  local composed = compose(target)

  vim.cmd('highlight clear')
  if vim.fn.exists('syntax_on') == 1 then
    vim.cmd('syntax reset')
  end
  vim.g.colors_name = M.SCHEME

  local palette = render_composed(composed)
  settle(target)
  announce_render(target)
  return palette
end

function M.highlight(group, fn)
  overrides[group] = fn
  if fn and M.palette then
    local hl = override_highlight(group, fn, M.palette, M.spec)
    if hl then
      editor.define_group(group, hl)
    end
  end
end

function M.label(theme)
  return theme.palette .. '/' .. theme.spec
end

local function foxglove()
  return require('foxglove')
end

function carried_over()
  local left = state.remembered() or {}
  local out = {}
  for half, registry in pairs { palette = palettes, spec = specs } do
    local name = left[half]
    if name and pcall(registry.resolve, name) then
      out[half] = name
    end
  end
  return out
end

function switch_through_colorscheme(want)
  local target = M.resolve(want)
  if #vim.api.nvim_get_runtime_file('colors/' .. M.SCHEME .. '.lua', false) == 0 then
    vim.notify(('foxglove: no %s colourscheme on the runtimepath; rendering directly')
      :format(M.SCHEME), vim.log.levels.WARN)
    return M.enter_colorscheme(target)
  end
  pending = target
  local ok, err = pcall(vim.cmd.colorscheme, M.SCHEME)
  pending = nil
  if not ok then
    error(err, 0)
  end
  return M.palette
end

function as_foxglove_error(err)
  local line = tostring(err):match('^[^\n]*')
  if not line:find('foxglove: ', 1, true) then
    return 'foxglove: ' .. line
  end
  return (line:gsub('^.-foxglove: ', 'foxglove: '))
end

local function overlay(groups, touched, extra)
  for group, attrs in pairs(extra) do
    groups[group] = attrs
    touched[group] = true
  end
end

function override_highlight(group, fn, palette, spec)
  return hook(("highlight '%s'"):format(group), fn, nil, palette, spec)
end

function overridden_highlights(palette, spec)
  local out = {}
  for group, fn in pairs(overrides) do
    out[group] = override_highlight(group, fn, palette, spec)
  end
  return out
end

local function adjust_spec(name, fn, palette, spec)
  local out = hook(name, fn, spec, palette, spec)
  if out == spec then
    return spec
  end
  if type(out.roles) ~= 'table' then
    vim.notify(('foxglove: %s must return a spec with a roles table'):format(name), vim.log.levels.WARN)
    return spec
  end
  out.roles = specs.normalize(name, out.roles)
  return out
end

local function changed_groups(before, after)
  local out = {}
  for group, hl in pairs(after) do
    local was = before[group]
    if type(was) ~= 'table' then
      out[group] = true
    else
      for key, value in pairs(hl) do
        if was[key] ~= value then out[group] = true end
      end
      for key in pairs(was) do
        if hl[key] == nil then out[group] = true end
      end
    end
  end
  for group in pairs(before) do
    if after[group] == nil then out[group] = true end
  end
  return out
end

function compose(target)
  local config = foxglove().config

  local raw = palettes.resolve(target.palette)
  raw = hook('pre_palette', config.pre_palette, raw, raw)

  local palette = derive(raw)
  palette = hook('post_palette', config.post_palette, palette, palette)

  local defined = specs.instantiate(target.spec, palette)
  local spec = specs.complete(defined, palette)

  local plain
  if config.pre_render then
    plain = build(palette, spec)
    spec = specs.complete(adjust_spec('pre_render', config.pre_render, palette, defined), palette)
  end

  local groups = build(palette, spec)
  local touched = plain and changed_groups(plain, groups) or {}

  overlay(groups, touched, overridden_highlights(palette, spec))

  return { palette = palette, spec = spec, groups = groups, touched = touched }
end

function render_composed(composed, preview)
  M.palette, M.spec = composed.palette, composed.spec
  editor.render(composed.palette, composed.spec, composed.groups, composed.touched, preview)
  return composed.palette
end

function settle(target)
  local previous = M.current
  M.current = target

  local script = foxglove().shell_script
  local shell_ok, shell_err = pcall(require('foxglove._shell').write, script)
  if not shell_ok then
    vim.notify('foxglove: could not write ' .. script .. ': ' .. tostring(shell_err), vim.log.levels.WARN)
  end

  local record = { palette = target.palette, spec = target.spec }

  local left = state.remembered()
  if not left or left.palette ~= record.palette or left.spec ~= record.spec then
    local state_ok, state_err = pcall(state.remember, record)
    if not state_ok then
      vim.notify('foxglove: could not write ' .. state.dir .. ': ' .. tostring(state_err),
        vim.log.levels.WARN)
    end
  end

  if not previous or previous.palette ~= target.palette or previous.spec ~= target.spec then
    announce_theme_change(target, previous)
  end
end

function announce_render(target)
  vim.api.nvim_exec_autocmds('User', {
    pattern = 'FoxgloveRendered',
    modeline = false,
    data = { theme = target },
  })
end

function announce_theme_change(target, previous)
  vim.api.nvim_exec_autocmds('User', {
    pattern = 'FoxgloveThemeChanged',
    modeline = false,
    data = { theme = target, previous = previous },
  })
end

return M
