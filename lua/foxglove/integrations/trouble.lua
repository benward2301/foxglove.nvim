return function(palette)
  return {
    TroubleText = { fg = palette.text2 },
    TroubleCount = { fg = palette.magenta1, bg = palette.base3 },
    TroubleNormal = { fg = palette.subtext1, bg = palette.base0 },
    LspTroubleText = { link = 'TroubleText' },
    LspTroubleCount = { link = 'TroubleCount' },
    LspTroubleNormal = { link = 'TroubleNormal' },
  }
end
