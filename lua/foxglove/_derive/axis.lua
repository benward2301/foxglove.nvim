local cl = require('foxglove.colorlab')

return function(raw)
  local base_l = cl.lightness(raw.base)
  local text_l = cl.lightness(raw.text)
  local dark = base_l < text_l
  local sign = dark and 1 or -1
  local span = (text_l - base_l) * sign
  return {
    dark = dark,
    sign = sign,
    reach = math.min(math.max(0.30 * span, 10), span),
  }
end
