local M = {}

function M.normalize(roles, refuse)
  local out = {}
  for role, value in pairs(roles) do
    if type(value) == 'table' then
      out[role] = value
    elseif type(value) == 'string' then
      out[role] = { fg = value }
    else
      refuse(role, type(value))
    end
  end
  return out
end

function M.with_default(roles, base)
  return setmetatable(roles, { __index = function() return vim.deepcopy(base) end })
end

return M
