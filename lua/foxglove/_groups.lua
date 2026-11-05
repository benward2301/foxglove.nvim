local M = {}

function M.normalize(groups, refuse)
  local out = {}
  for group, value in pairs(groups) do
    if type(value) == 'table' then
      out[group] = value
    else
      refuse(group, type(value))
    end
  end
  return out
end

function M.resolve(groups, name)
  local seen = { [name] = true }
  local attrs = groups[name]
  while attrs and attrs.link do
    if seen[attrs.link] then
      return nil
    end
    seen[attrs.link] = true
    attrs = groups[attrs.link]
  end
  return attrs and vim.deepcopy(attrs) or nil
end

return M
