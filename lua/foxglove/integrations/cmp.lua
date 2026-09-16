return function(_)
  local kinds = {
    'Default', 'Keyword', 'Variable', 'Constant', 'Reference', 'Value',
    'Function', 'Method', 'Constructor', 'Interface', 'Event', 'Enum', 'Unit',
    'Class', 'Struct', 'Module', 'Property', 'Field', 'TypeParameter',
    'EnumMember', 'Operator', 'Snippet',
  }
  local groups = {
    CmpDocumentation = { link = 'BlinkCmpDoc' },
    CmpDocumentationBorder = { link = 'BlinkCmpDocBorder' },
    CmpItemAbbr = { link = 'BlinkCmpLabel' },
    CmpItemAbbrDeprecated = { link = 'BlinkCmpLabelDeprecated' },
    CmpItemAbbrMatch = { link = 'BlinkCmpLabelMatch' },
    CmpItemAbbrMatchFuzzy = { link = 'BlinkCmpLabelMatch' },
    CmpItemMenu = { link = 'BlinkCmpLabelDetail' },
  }
  for _, kind in ipairs(kinds) do
    groups['CmpItemKind' .. kind] = { link = 'BlinkCmpKind' .. kind }
  end
  return groups
end
