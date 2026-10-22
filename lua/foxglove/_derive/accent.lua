local cl = require('foxglove.colorlab')

local VISIBLE_CHROMA = 0.035
local LIGHTEN = 0.14
local DARKEN = 0.11

local function chroma_floor(hex)
  local c0 = cl.chroma(hex)
  return math.min(
    0.9 * c0,
    VISIBLE_CHROMA + 0.55 * math.max(c0 - VISIBLE_CHROMA, 0))
end

local function toward(hex, target, floor)
  local L0 = cl.lightness(hex)
  local function at(t) return cl.with_lightness(hex, L0 + (target - L0) * t) end
  if cl.chroma(at(1)) >= floor then
    return at(1)
  end
  local lo, hi = 0, 1
  for _ = 1, 16 do
    local mid = (lo + hi) / 2
    if cl.chroma(at(mid)) >= floor then lo = mid else hi = mid end
  end
  return at(lo)
end

local function shift(hex, sign)
  local L = cl.lightness(hex)
  return sign > 0 and LIGHTEN * (100 - L) or DARKEN * L
end

local function emphasis(hex, sign)
  return toward(hex, cl.lightness(hex) + sign * shift(hex, sign), chroma_floor(hex))
end

local function dim(hex, sign, limit)
  local L0 = cl.lightness(hex)
  local step = shift(hex, -sign)
  local bound = sign > 0 and math.min(limit, L0) or math.max(limit, L0)
  local target = sign > 0 and math.max(L0 - step, bound) or math.min(L0 + step, bound)
  return toward(hex, target, chroma_floor(hex))
end

local function tint(hex, base, alpha, target)
  local raw = cl.blend(hex, base, alpha)
  return cl.with_lightness(raw, target)
end

return function(raw, axis, name, base_lightness)
  local hex = raw[name]
  return {
    [0] = emphasis(hex, axis.sign),
    [1] = hex,
    [2] = dim(hex, axis.sign, base_lightness[4]),
    [3] = tint(hex, raw.base, 0.30, (base_lightness[3] + base_lightness[4]) / 2),
    [4] = tint(hex, raw.base, 0.12, base_lightness[2]),
  }
end
