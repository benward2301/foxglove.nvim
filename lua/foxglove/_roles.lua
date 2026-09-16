local M = {}

function M.merge(base, over, refuse)
  local out = {}
  for role, value in pairs(base) do
    out[role] = value
  end
  for role, value in pairs(over) do
    if type(value) == 'table' then
      out[role] = value
    elseif type(value) == 'string' then
      local into = {}
      if type(base[role]) == 'table' then
        for key, attr in pairs(base[role]) do
          into[key] = attr
        end
      end
      if into.bg and not into.fg then
        into.bg = value
      else
        into.fg = value
      end
      out[role] = into
    else
      refuse(role, type(value))
    end
  end
  return setmetatable(out, getmetatable(base))
end

function M.with_default(roles, base)
  return setmetatable(roles, { __index = function() return base end })
end

return M
