return function(palette)
  local groups = {}
  for i = 0, 15 do
    groups['GlyphPalette' .. i] = { fg = palette['ansi' .. i] }
  end
  return groups
end
