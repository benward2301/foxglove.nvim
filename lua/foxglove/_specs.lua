local roles_lib = require('foxglove._roles')

local specs = require('foxglove._registry')('spec', function(spec)
  if type(spec.roles) ~= 'function' then
    error(("foxglove: spec '%s' must have a roles function"):format(spec.name), 0)
  end
end)

specs.default = 'nightfox'

function specs.normalize(who, roles)
  return roles_lib.normalize(roles, function(role, got)
    vim.notify(("foxglove: %s gave role '%s' a %s, wanted a highlight or a colour")
      :format(who, role, got), vim.log.levels.WARN)
  end)
end

function specs.instantiate(name, palette)
  local spec = vim.deepcopy(specs.resolve(name))
  spec.roles = specs.normalize(("spec '%s'"):format(spec.name), spec.roles(palette))
  return spec
end

function specs.complete(spec, palette)
  local roles = vim.tbl_extend('force', {}, spec.roles)
  if not roles.include then roles.include = roles.preproc end
  if not roles.boolean then roles.boolean = roles.number end
  if not roles.decorator then roles.decorator = roles.constant end
  if not roles.func_call then roles.func_call = roles.func end
  if not roles.overprint then
    roles.overprint = { fg = palette.dark and palette.yellow0 or palette.orange0 }
  end
  roles = roles_lib.with_default(roles, { bg = palette.base1, fg = palette.text1 })
  return vim.tbl_extend('force', spec, { roles = roles })
end

function specs.roles(name, palette)
  return specs.complete(specs.instantiate(name, palette), palette).roles
end

return specs
