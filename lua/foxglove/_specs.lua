local roles_lib = require('foxglove._roles')
local merge = roles_lib.merge
local hook = require('foxglove._hook')

local specs = require('foxglove._registry')('spec', function(spec)
  if type(spec.roles) ~= 'function' then
    error(("foxglove: spec '%s' must have a roles function"):format(spec.name), 0)
  end
  if spec.highlights ~= nil and type(spec.highlights) ~= 'function' then
    error(("foxglove: spec '%s' highlights must be a function"):format(spec.name), 0)
  end
end)

specs.default = 'default'

function specs.roles(name, palette)
  local spec = specs.resolve(name)
  local out = merge({}, spec.roles(palette), function(role, got)
    vim.notify(("foxglove: spec '%s' gave role '%s' a %s, wanted a highlight or a colour")
      :format(spec.name, role, got), vim.log.levels.WARN)
  end)
  if not out.include then out.include = out.preproc end
  if not out.boolean then out.boolean = out.number end
  if not out.decorator then out.decorator = out.constant end
  if not out.overprint then
    out.overprint = { fg = palette.dark and palette.yellow0 or palette.orange0 }
  end
  return roles_lib.with_default(out, { bg = palette.base1, fg = palette.text1 })
end

function specs.highlights(name, palette, roles)
  local spec = specs.resolve(name)
  return hook(("spec '%s' highlights"):format(spec.name), spec.highlights, {}, palette, roles)
end

return specs
