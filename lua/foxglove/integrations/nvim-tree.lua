return function(palette)
  return {
    NvimTreeVertSplit = { link = 'WinSeparator' },
    NvimTreeIndentMarker = { fg = palette.base3 },
    NvimTreeRootFolder = { fg = palette.orange1, bold = true },
    NvimTreeFolderName = { fg = palette.blue1 },
    NvimTreeFolderIcon = { fg = palette.blue1 },
    NvimTreeOpenedFolderName = { fg = palette.blue0 },
    NvimTreeEmptyFolderName = { fg = palette.subtext1 },
    NvimTreeSymlink = { fg = palette.magenta2 },
    NvimTreeSpecialFile = { fg = palette.cyan1 },
    NvimTreeImageFile = { fg = palette.subtext1 },
    NvimTreeOpenedFile = { fg = palette.magenta0 },
    NvimTreeGitDeleted = { fg = palette.red1 },
    NvimTreeGitDirty = { fg = palette.yellow1 },
    NvimTreeGitMerge = { fg = palette.orange1 },
    NvimTreeGitNew = { fg = palette.green1 },
    NvimTreeGitRenamed = { link = 'NvimTreeGitDeleted' },
    NvimTreeGitStaged = { fg = palette.green2 },
  }
end
