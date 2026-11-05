local groups_lib = require('foxglove._groups')

local specs = require('foxglove._registry')('spec', function(spec)
  if type(spec.groups) ~= 'function' then
    error(("foxglove: spec '%s' must have a groups function"):format(spec.name), 0)
  end
end)

specs.default = 'foxglove'

local function normalize(who, groups)
  return groups_lib.normalize(groups, function(group, got)
    vim.notify(("foxglove: %s gave group '%s' a %s, wanted a highlight")
      :format(who, group, got), vim.log.levels.WARN)
  end)
end

function specs.instantiate(name, palette)
  local spec = vim.deepcopy(specs.resolve(name))
  spec.groups = normalize(("spec '%s'"):format(spec.name), spec.groups(palette))
  return spec
end

return specs
