return function(_, roles)
  local match = roles.overprint and roles.overprint.fg
  if vim.startswith(vim.env.TERM or '', 'screen') then
    return {
      QuickScopePrimary = { fg = match, underline = true },
      QuickScopeSecondary = { underline = true },
    }
  end
  return {
    QuickScopePrimary = { sp = match, underline = true },
    QuickScopeSecondary = { sp = match, underdouble = true },
  }
end
