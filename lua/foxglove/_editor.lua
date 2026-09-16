
local M = {}

local integrations = {}

local rendered = {}

local standing = { groups = {}, touched = {} }

local generation = 0

local define_groups, run_integrations, reassert, set_terminal_colors

function M.render(palette, roles, groups, touched, preview)
  touched = touched or {}
  local now = {}
  define_groups(groups, now)
  set_terminal_colors(palette)

  run_integrations(palette, roles, now)
  reassert(touched, groups, now)

  local stale = {}
  for group in pairs(rendered) do
    if not now[group] then
      stale[group] = {}
    end
  end
  define_groups(stale)
  rendered = now
  standing = { groups = groups, touched = touched }

  generation = generation + 1
  if preview then
    return
  end
  local mine = generation
  vim.schedule(function()
    if mine == generation then
      run_integrations(palette, roles, rendered)
      reassert(standing.touched, standing.groups, rendered)
    end
  end)
end

function M.define_group(name, attrs)
  define_groups({ [name] = attrs }, rendered)
  standing.groups[name] = attrs
  standing.touched[name] = true
end

function M.load_integrations(dir)
  local ok, found = pcall(vim.fn.readdir, dir)
  for _, entry in ipairs(ok and found or {}) do
    local name = entry:match('^(.+)%.lua$')
    if name then
      local loaded, fn = pcall(require, 'foxglove.integrations.' .. name)
      if loaded and type(fn) == 'function' then
        integrations[name] = fn
      else
        vim.notify('foxglove: integration ' .. name .. ' did not load a function: ' .. tostring(fn),
          vim.log.levels.WARN)
      end
    end
  end
end

function define_groups(groups, sink)
  local rejected, first = 0, nil
  for group, attrs in pairs(groups) do
    local ok, err = pcall(vim.api.nvim_set_hl, 0, group, attrs)
    if ok then
      if sink then sink[group] = true end
    else
      rejected = rejected + 1
      first = first or ('%s (%s)'):format(group, tostring(err))
    end
  end
  if rejected > 0 then
    vim.notify(('foxglove: nvim rejected %d highlight group(s), first was %s'):format(rejected, first),
      vim.log.levels.WARN)
  end
end

function set_terminal_colors(palette)
  for i = 0, 15 do
    vim.g['terminal_color_' .. i] = palette['ansi' .. i]
  end
end

function run_integrations(palette, roles, sink)
  local names = {}
  for name in pairs(integrations) do
    names[#names + 1] = name
  end
  table.sort(names)
  for _, name in ipairs(names) do
    local ok, groups = pcall(integrations[name], palette, roles)
    if not ok then
      vim.notify('foxglove: integration ' .. name .. ' failed: ' .. tostring(groups), vim.log.levels.WARN)
    elseif type(groups) == 'table' then
      define_groups(groups, sink)
    end
  end
end

function reassert(touched, groups, sink)
  local out = {}
  for group in pairs(touched) do
    out[group] = groups[group] or {}
  end
  define_groups(out, sink)
end

return M
