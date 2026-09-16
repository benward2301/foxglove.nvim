
return function(kind, validate)
  local M = {}

  local entries = {}

  local function add(entry)
    if type(entry.name) ~= 'string' then
      error('foxglove: a ' .. kind .. ' must have a name', 0)
    end
    if validate then
      validate(entry)
    end
    entries[entry.name] = entry
  end

  function M.register(entry)
    if type(entry) ~= 'table' then
      error(('foxglove: a %s must be a table, got a %s'):format(kind, type(entry)), 0)
    end
    if next(entry) == nil then
      return
    end
    if M.batched(entry) then
      for _, one in ipairs(entry) do
        add(one)
      end
    else
      add(entry)
    end
  end

  function M.batched(entry)
    return type(entry) == 'table' and type(entry[1]) == 'table'
  end

  function M.list()
    local names = {}
    for name in pairs(entries) do
      names[#names + 1] = name
    end
    table.sort(names)
    return names
  end

  function M.resolve(name)
    if type(name) ~= 'string' then
      error(('foxglove: wanted the name of a %s, got a %s'):format(kind, type(name)), 0)
    end
    local entry = entries[name]
    if not entry then
      error(('foxglove: no %s named %s'):format(kind, tostring(name)), 0)
    end
    return entry
  end

  return M
end
