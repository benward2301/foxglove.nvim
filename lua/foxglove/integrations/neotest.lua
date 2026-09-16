return function(palette)
  return {
    NeotestPassed = { fg = palette.green1 },
    NeotestFailed = { fg = palette.red1 },
    NeotestRunning = { fg = palette.orange1 },
    NeotestSkipped = { fg = palette.yellow1 },
    NeotestTest = { link = 'Normal' },
    NeotestNamespace = { fg = palette.cyan2 },
    NeotestMarked = { fg = palette.text1, bold = true },
    NeotestFocused = { underline = true },
    NeotestFile = { fg = palette.blue1 },
    NeotestDir = { fg = palette.cyan1 },
    NeotestIndent = { link = 'Conceal' },
    NeotestExpandMarker = { link = 'Conceal' },
    NeotestAdapterName = { fg = palette.magenta1, bold = true },
  }
end
