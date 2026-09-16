local cl = require('foxglove.colorlab')
local ramp_axis = require('foxglove._derive.axis')
local base_ramp = require('foxglove._derive.base')
local text_ramp = require('foxglove._derive.text')
local accent_ramp = require('foxglove._derive.accent')

local ACCENTS = { 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'orange' }

local validate_declared, declared

local function derive(raw)
  validate_declared(raw)
  raw = declared(raw)

  local axis = ramp_axis(raw)
  local palette = { name = raw.name, dark = axis.dark }

  local base = base_ramp(raw, axis)
  for i = 0, 4 do palette['base' .. i] = base.hex[i] end

  local text = text_ramp(raw, axis)
  for i = 0, 2 do palette['text' .. i] = text.text[i] end
  for i = 0, 2 do palette['subtext' .. i] = text.subtext[i] end

  for _, name in ipairs(ACCENTS) do
    local accent = accent_ramp(raw, axis, name, base.lightness)
    for i = 0, 4 do palette[name .. i] = accent[i] end
  end

  palette.ansi0, palette.ansi8 = palette.base2, palette.subtext1
  palette.ansi7, palette.ansi15 = palette.text1, palette.text0
  for i, name in ipairs { 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan' } do
    palette['ansi' .. i] = palette[name .. '1']
    palette['ansi' .. (i + 8)] = palette[name .. '0']
  end

  return palette
end

local MIN_BASE_SEPARATION = 10
local MIN_TEXT_SEPARATION = 5

local DECLARED = { 'base', 'subtext', 'text' }
for _, name in ipairs(ACCENTS) do DECLARED[#DECLARED + 1] = name end

function validate_declared(raw)
  local missing, malformed = {}, {}
  for _, slot in ipairs(DECLARED) do
    local hex = raw[slot]
    if hex == nil then
      missing[#missing + 1] = slot
    elseif not cl.hex(hex) then
      malformed[#malformed + 1] = ('%s = %s'):format(slot, tostring(hex))
    end
  end
  if #missing > 0 or #malformed > 0 then
    local parts = {}
    if #missing > 0 then
      parts[#parts + 1] = 'must declare ' .. table.concat(missing, ', ')
    end
    if #malformed > 0 then
      parts[#parts + 1] = 'has no six-digit hex for ' .. table.concat(malformed, ', ')
    end
    error(("foxglove: palette '%s' %s"):format(
      tostring(raw.name), table.concat(parts, ', and ')), 0)
  end

  local base_l, subtext_l, text_l =
    cl.lightness(raw.base), cl.lightness(raw.subtext), cl.lightness(raw.text)
  local lo, hi = math.min(base_l, text_l), math.max(base_l, text_l)
  if subtext_l < lo or subtext_l > hi then
    error(("foxglove: palette '%s' has a subtext that doesn't sit between base and text " ..
      '(for an accented comment colour, override the comment role in the spec instead)')
      :format(tostring(raw.name)), 0)
  end

  if math.abs(subtext_l - base_l) < MIN_BASE_SEPARATION then
    error(("foxglove: palette '%s' has a subtext too close to base " ..
      '(needs at least %d lightness units of separation for the base ramp to stay legible)')
      :format(tostring(raw.name), MIN_BASE_SEPARATION), 0)
  end

  if math.abs(text_l - subtext_l) < MIN_TEXT_SEPARATION then
    error(("foxglove: palette '%s' has a subtext too close to text " ..
      '(needs at least %d lightness units of separation for a comment to read as one)')
      :format(tostring(raw.name), MIN_TEXT_SEPARATION), 0)
  end
end

function declared(raw)
  local out = { name = raw.name }
  for _, slot in ipairs(DECLARED) do
    out[slot] = cl.hex(raw[slot])
  end
  return out
end

return derive
