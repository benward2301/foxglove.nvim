return function(name, fn, fallback, ...)
  if fn == nil then
    return fallback
  end
  local function refuse(why)
    vim.notify(('foxglove: %s %s'):format(name, why), vim.log.levels.WARN)
    return fallback
  end
  if type(fn) ~= 'function' then
    return refuse('must be a function, got ' .. type(fn))
  end
  local count = select('#', ...)
  local args = vim.deepcopy { ... }
  local ok, result = pcall(fn, unpack(args, 1, count))
  if not ok then
    return refuse('failed: ' .. tostring(result))
  end
  if type(result) ~= 'table' then
    return refuse('must return a table, got ' .. type(result))
  end
  return result
end
