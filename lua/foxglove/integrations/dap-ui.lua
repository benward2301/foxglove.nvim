return function(palette)
  return {
    DapUIVariable = { link = '@variable' },
    DapUIScope = { fg = palette.cyan0 },
    DapUIType = { link = 'Type' },
    DapUIValue = { link = '@variable' },
    DapUIModifiedValue = { fg = palette.text1, bold = true },
    DapUIDecoration = { fg = palette.subtext1 },
    DapUIThread = { link = 'String' },
    DapUIStoppedThread = { fg = palette.cyan0 },
    DapUIFrameName = { link = 'Normal' },
    DapUISource = { link = 'Keyword' },
    DapUILineNumber = { link = 'Number' },
    DapUIFloatBorder = { link = 'FloatBorder' },
    DapUIWatchesEmpty = { fg = palette.red1 },
    DapUIWatchesValue = { fg = palette.yellow1 },
    DapUIWatchesError = { fg = palette.red1 },
    DapUIBreakpointsPath = { fg = palette.cyan0 },
    DapUIBreakpointsInfo = { fg = palette.blue1 },
    DapUIBreakpointsCurrentLine = { fg = palette.green1, bold = true },
    DapUIBreakpointsLine = { link = 'DapUILineNumber' },
    DapUIBreakpointsDisabledLine = { fg = palette.subtext1 },
  }
end
