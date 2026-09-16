return function(palette)
  return {
    NotifyBackground = { link = 'NormalFloat' },
    NotifyTRACETitle = { fg = palette.subtext1 },
    NotifyTRACEIcon = { link = 'NotifyTRACETitle' },
    NotifyDEBUGTitle = { fg = palette.green1 },
    NotifyDEBUGIcon = { link = 'NotifyDEBUGTitle' },
    NotifyINFOTitle = { fg = palette.blue1 },
    NotifyINFOIcon = { link = 'NotifyINFOTitle' },
    NotifyWARNTitle = { fg = palette.yellow1 },
    NotifyWARNIcon = { link = 'NotifyWARNTitle' },
    NotifyERRORTitle = { fg = palette.red1 },
    NotifyERRORIcon = { link = 'NotifyERRORTitle' },
    NotifyINFOBorder = { fg = palette.base1 },
    NotifyWARNBorder = { fg = palette.base1 },
    NotifyERRORBorder = { fg = palette.base1 },
    NotifyTRACEBorder = { fg = palette.base1 },
    NotifyDEBUGBorder = { fg = palette.base1 },
  }
end
