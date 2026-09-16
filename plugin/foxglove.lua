require('foxglove')

local HALVES = { palette = true, spec = true }

local function parse(fargs)
  if #fargs == 0 then
    return { pick = true }
  end
  local theme = {}
  for _, arg in ipairs(fargs) do
    local half, value = arg:match('^([%w_]+)=(.+)$')
    if not half or not HALVES[half] then
      return nil, ("foxglove: don't know '%s'; wanted palette=… or spec=…"):format(arg)
    end
    theme[half] = value
  end
  return { theme = theme }
end

local function complete(lead, line)
  local half, partial = lead:match('^([%w_]+)=(.*)$')
  if half and HALVES[half] then
    local registry = half == 'palette' and require('foxglove._palettes') or require('foxglove._specs')
    local names = registry.list()
    return vim.tbl_map(function(name)
      return half .. '=' .. name
    end, vim.tbl_filter(function(name)
      return name:find(partial, 1, true) == 1
    end, names))
  end

  local used = {}
  for name in line:gmatch('([%w_]+)=') do
    used[name] = true
  end

  local out = {}
  for name in pairs(HALVES) do
    if not used[name] then
      out[#out + 1] = name .. '='
    end
  end
  table.sort(out)
  return vim.tbl_filter(function(candidate)
    return candidate:find(lead, 1, true) == 1
  end, out)
end

vim.api.nvim_create_user_command('Foxglove', function(opts)
  local want, err = parse(opts.fargs)
  if not want then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
  if want.pick then
    require('foxglove._picker').open()
    return
  end
  local ok, failed = pcall(require('foxglove._theme').switch, want.theme)
  if not ok then
    vim.notify(tostring(failed), vim.log.levels.ERROR)
  end
end, {
  nargs = '*',
  desc = 'Browse foxglove palettes and specs in one picker, or set either by name',
  complete = complete,
})
