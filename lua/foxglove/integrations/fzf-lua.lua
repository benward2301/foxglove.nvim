return function(palette, roles)
  return {
    FzfLuaFzfMatch = roles.overprint,
    FzfLuaBorder = { bg = palette.base1, fg = palette.base1 },
    FzfLuaBufNr = { fg = palette.orange1 },
    FzfLuaBufFlagCur = { fg = palette.red1 },
    FzfLuaBufFlagAlt = { fg = palette.cyan1 },
    FzfLuaPathLineNr = { fg = palette.green1 },
    FzfLuaPathColNr = { fg = palette.cyan1 },
    FzfLuaDirPart = { fg = palette.subtext1 },
    FzfLuaHeaderBind = { fg = palette.yellow1 },
    FzfLuaHeaderText = { fg = palette.red1 },
    FzfLuaTabTitle = { fg = palette.blue1 },
    FzfLuaTabMarker = { fg = palette.orange1 },
    FzfLuaLivePrompt = { fg = palette.magenta1 },
    FzfLuaLiveSym = { fg = palette.magenta1 },
  }
end
