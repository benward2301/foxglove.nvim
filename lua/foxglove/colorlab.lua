
local function clamp(x, lo, hi)
  if x < lo then return lo end
  if x > hi then return hi end
  return x
end

local function hex_to_rgb(hex)
  hex = hex:gsub('^#', '')
  return tonumber(hex:sub(1, 2), 16),
         tonumber(hex:sub(3, 4), 16),
         tonumber(hex:sub(5, 6), 16)
end

local function rgb_to_hex(r, g, b)
  return string.format('#%02x%02x%02x',
    clamp(math.floor(r + 0.5), 0, 255),
    clamp(math.floor(g + 0.5), 0, 255),
    clamp(math.floor(b + 0.5), 0, 255))
end

local function srgb_to_linear(c)
  c = c / 255
  return c <= 0.04045 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4
end

local function linear_to_srgb(c)
  c = c <= 0.0031308 and 12.92 * c or 1.055 * c ^ (1 / 2.4) - 0.055
  return clamp(c, 0, 1) * 255
end

local function cbrt(x)
  return x < 0 and -((-x) ^ (1 / 3)) or x ^ (1 / 3)
end

local function linear_to_oklab(r, g, b)
  local l = cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
  local m = cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
  local s = cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
  return 100 * (0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s),
    1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
end

local function oklab_point_to_linear(L, a, b, scale)
  local Lr = L / 100
  local A, B = a * scale, b * scale
  local l = (Lr + 0.3963377774 * A + 0.2158037573 * B) ^ 3
  local m = (Lr - 0.1055613458 * A - 0.0638541728 * B) ^ 3
  local s = (Lr - 0.0894841775 * A - 1.2914855480 * B) ^ 3
  return 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
end

local function in_gamut(L, a, b, scale)
  local r, g, bl = oklab_point_to_linear(L, a, b, scale)
  return math.min(r, g, bl) >= -0.0001 and math.max(r, g, bl) <= 1.0001
end

local function hex_to_oklab(hex)
  local r, g, b = hex_to_rgb(hex)
  local lin = srgb_to_linear
  if r == g and g == b then
    return (linear_to_oklab(lin(r), lin(r), lin(r))), 0, 0
  end
  return linear_to_oklab(lin(r), lin(g), lin(b))
end

local function oklab_to_hex(L, a, b)
  L = clamp(L, 0, 100)
  if L <= 0 then
    return '#000000'
  end
  local scale = 1
  if not in_gamut(L, a, b, 1) then
    local lo, hi = 0, 1
    for _ = 1, 20 do
      local mid = (lo + hi) / 2
      if in_gamut(L, a, b, mid) then lo = mid else hi = mid end
    end
    scale = lo
  end
  local r, g, bl = oklab_point_to_linear(L, a, b, scale)
  return rgb_to_hex(linear_to_srgb(r),
    linear_to_srgb(g), linear_to_srgb(bl))
end

local M = {}

function M.hex(value)
  if type(value) ~= 'string' then
    return nil
  end
  local digits = value:match('^#?(%x%x%x%x%x%x)$')
  return digits and ('#' .. digits:lower()) or nil
end

function M.lightness(hex)
  return (hex_to_oklab(hex))
end

function M.with_lightness(hex, L)
  local _, a, b = hex_to_oklab(hex)
  return oklab_to_hex(L, a, b)
end

function M.chroma(hex)
  local _, a, b = hex_to_oklab(hex)
  return math.sqrt(a * a + b * b)
end

function M.with_chroma(hex, C)
  local L, a, b = hex_to_oklab(hex)
  local c0 = math.sqrt(a * a + b * b)
  if c0 == 0 then
    return hex
  end
  local scale = math.max(C, 0) / c0
  return oklab_to_hex(L, a * scale, b * scale)
end

local atan2 = math.atan2 or math.atan

function M.hue(hex)
  local _, a, b = hex_to_oklab(hex)
  local deg = math.deg(atan2(b, a))
  return deg < 0 and deg + 360 or deg
end

function M.with_hue(hex, h)
  local L, a, b = hex_to_oklab(hex)
  local c0 = math.sqrt(a * a + b * b)
  if c0 == 0 then
    return hex
  end
  local rad = math.rad(h)
  return oklab_to_hex(L, c0 * math.cos(rad), c0 * math.sin(rad))
end

function M.lighten(hex, frac)
  local L = M.lightness(hex)
  frac = clamp(frac, -1, 1)
  return M.with_lightness(hex, frac >= 0 and L + (100 - L) * frac or L + L * frac)
end

function M.saturate(hex, frac)
  local L, a, b = hex_to_oklab(hex)
  local scale = math.max(1 + frac, 0)
  return oklab_to_hex(L, a * scale, b * scale)
end

function M.rotate(hex, degrees)
  return M.with_hue(hex, M.hue(hex) + degrees)
end

function M.blend(fg, bg, alpha)
  alpha = clamp(alpha, 0, 1)
  local r1, g1, b1 = hex_to_rgb(fg)
  local r2, g2, b2 = hex_to_rgb(bg)
  return rgb_to_hex(
    r1 * alpha + r2 * (1 - alpha),
    g1 * alpha + g2 * (1 - alpha),
    b1 * alpha + b2 * (1 - alpha))
end

return M
