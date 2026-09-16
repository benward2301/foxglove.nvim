return function(palette)
  return {
    IblIndent = { fg = palette.base3 },
    IblWhitespace = { link = 'NonText' },
    IblScope = { fg = palette.subtext1 },
    ['@ibl'] = {},
    ['@ibl.indent.char.1'] = { fg = palette.base3, nocombine = true },
    ['@ibl.whitespace.char.1'] = { nocombine = true },
    ['@ibl.scope.char.1'] = { fg = palette.subtext1, nocombine = true },
    ['@ibl.scope.underline.1'] = { sp = palette.subtext1, underline = true },
  }
end
