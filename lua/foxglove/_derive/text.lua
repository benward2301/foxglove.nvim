local cl = require('foxglove.colorlab')

local function subtext_ramp(hex, sign, step, lo, hi)
  local L = cl.lightness(hex)
  local function to(target)
    return cl.with_lightness(hex, math.min(math.max(target, lo), hi))
  end
  return {
    [0] = to(L + step * sign),
    [1] = hex,
    [2] = to(L - step * sign),
  }
end

local function text2_lightness(text_l, subtext1_l, sign)
  local midpoint_gap = math.abs(subtext1_l - text_l) / 2
  return text_l - math.min(8, midpoint_gap) * sign
end

return function(raw, axis)
  local step = axis.reach / 3
  local base_l, text_l = cl.lightness(raw.base), cl.lightness(raw.text)
  local subtext = subtext_ramp(raw.subtext, axis.sign, step,
    math.min(base_l, text_l), math.max(base_l, text_l))

  local text = {
    [0] = cl.with_lightness(raw.text, text_l + step * axis.sign),
    [1] = raw.text,
    [2] = cl.with_lightness(raw.text,
      text2_lightness(text_l, cl.lightness(subtext[1]), axis.sign)),
  }

  return {
    text = text,
    subtext = subtext,
  }
end
