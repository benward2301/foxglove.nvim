local cl = require('foxglove.colorlab')

return function(raw, axis)
  local base_l = cl.lightness(raw.base)
  local subtext_l = cl.lightness(raw.subtext)
  local reach = math.min(axis.reach, (subtext_l - base_l) * axis.sign * 2 / 3)
  local step = reach / 4

  local lightness = { [1] = base_l }
  local light_pal_pull = { [2] = 0.9, [3] = 0.75, [4] = 0.75 }
  for _, i in ipairs { 2, 3, 4 } do
    local pull = axis.dark and 1 or light_pal_pull[i]
    lightness[i] = base_l + (i - 1) * step * pull * axis.sign
  end

  if axis.dark then
    lightness[0] = base_l + (base_l >= 1 and -step or step / 2) * axis.sign
  else
    lightness[0] = base_l + step / 2 * axis.sign
  end

  local hex = { [1] = raw.base }
  for _, i in ipairs { 0, 2, 3, 4 } do
    hex[i] = cl.with_lightness(raw.base, lightness[i])
  end

  return { hex = hex, lightness = lightness }
end
