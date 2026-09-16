return function(palette)
  return {
    BufferCurrent = { fg = palette.text1, bg = palette.base3 },
    BufferCurrentIndex = { fg = palette.blue1, bg = palette.base3 },
    BufferCurrentMod = { fg = palette.yellow1, bg = palette.base3 },
    BufferCurrentSign = { fg = palette.blue1, bg = palette.base3 },
    BufferCurrentTarget = { fg = palette.red1, bg = palette.base3 },
    BufferVisible = { fg = palette.text1, bg = palette.base0 },
    BufferVisibleIndex = { fg = palette.blue1, bg = palette.base0 },
    BufferVisibleMod = { fg = palette.yellow1, bg = palette.base0 },
    BufferVisibleSign = { fg = palette.blue1, bg = palette.base0 },
    BufferVisibleTarget = { fg = palette.red1, bg = palette.base0 },
    BufferInactive = { fg = palette.subtext1, bg = palette.base0 },
    BufferInactiveIndex = { fg = palette.subtext1, bg = palette.base0 },
    BufferInactiveMod = { fg = palette.yellow2, bg = palette.base0 },
    BufferInactiveSign = { fg = palette.base3, bg = palette.base0 },
    BufferInactiveTarget = { fg = palette.red1, bg = palette.base0 },
    BufferTabpages = { bg = palette.base0 },
    BufferTabpage = { fg = palette.base3, bg = palette.base0 },
  }
end
