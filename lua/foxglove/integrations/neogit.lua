return function(palette)
  return {
    NeogitBranch = { fg = palette.yellow1 },
    NeogitRemote = { fg = palette.green1 },
    NeogitHunkHeader = { fg = palette.blue1, bg = palette.base3 },
    NeogitHunkHeaderHighlight = { fg = palette.blue1, bg = palette.base4 },
    NeogitDiffAdd = { fg = palette.green2 },
    NeogitDiffDelete = { fg = palette.red2 },
    NeogitDiffAddHighlight = { link = 'DiffAdd' },
    NeogitDiffDeleteHighlight = { link = 'DiffDelete' },
    NeogitDiffContextHighlight = { bg = palette.base2 },
    NeogitNotificationInfo = { fg = palette.blue1 },
    NeogitNotificationWarning = { fg = palette.yellow1 },
    NeogitNotificationError = { fg = palette.red1 },
  }
end
