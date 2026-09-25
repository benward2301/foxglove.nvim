
local M = {}

local GLOBALS, SCOPES, global_dict, scope_dict, font_style, kv, xml_escape

function M.build(palette, roles)
  palette = palette or {}
  roles = roles or {}
  local out = {
    '<?xml version="1.0" encoding="UTF-8"?>\n',
    '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n',
    '<plist version="1.0">\n',
    '<dict>\n',
    kv('\t', 'name', 'foxglove'),
    kv('\t', 'colorSpaceName', 'sRGB'),
    '\t<key>settings</key>\n',
    '\t<array>\n',
    global_dict(palette),
  }
  for _, row in ipairs(SCOPES) do
    out[#out + 1] = scope_dict(row, roles, palette)
  end
  out[#out + 1] = '\t</array>\n'
  out[#out + 1] = '</dict>\n'
  out[#out + 1] = '</plist>\n'
  return table.concat(out)
end

GLOBALS = {
  { 'background', 'base1' },
  { 'foreground', 'text1' },
  { 'caret', 'text2' },
  { 'invisibles', 'subtext1' },
  { 'lineHighlight', 'base2' },
  { 'selection', 'base3' },
  { 'gutter', 'base1' },
  { 'gutterForeground', 'subtext1' },
}

SCOPES = {
  { 'Comment', 'comment, punctuation.definition.comment', 'comment' },
  { 'Punctuation', 'punctuation, punctuation.definition, punctuation.section, meta.brace', 'punctuation' },
  { 'Separator', 'punctuation.separator, punctuation.terminator, punctuation.accessor', 'delimiter' },
  { 'String', 'string, constant.other.symbol', 'string' },
  { 'String Punctuation', 'punctuation.definition.string', 'string' },
  { 'Escape', 'constant.character.escape, constant.character.escaped', 'string_escape', 'bold' },
  { 'Regexp', 'string.regexp', 'string_regex' },
  { 'Interpolation', 'punctuation.section.embedded, punctuation.section.interpolation, punctuation.definition.template-expression, variable.interpolation', 'punctuation_special' },
  { 'Number', 'constant.numeric, keyword.other.unit', 'number' },
  { 'Language Constant', 'constant.language', 'constant_builtin' },
  { 'Constant', 'constant, constant.other, support.constant, variable.other.constant', 'constant' },
  { 'Operator', 'keyword.operator', 'operator' },
  { 'Word Operator', 'keyword.operator.word, keyword.operator.expression, keyword.operator.logical, keyword.operator.new', 'keyword_operator' },
  { 'Return', 'keyword.control.return, keyword.control.flow.return', 'keyword_return' },
  { 'Control Flow', 'keyword.control, keyword.control.conditional, keyword.control.loop, keyword.control.exception', 'conditional' },
  { 'Preprocessor', 'meta.preprocessor, keyword.control.import, keyword.control.at-rule, keyword.other.preprocessor, punctuation.definition.preprocessor', 'preproc' },
  { 'Keyword', 'keyword, keyword.other, storage, storage.type, storage.modifier', 'keyword' },
  { 'Function Keyword', 'storage.type.function, keyword.declaration.function', 'keyword' },
  { 'Builtin Type', 'support.type.builtin, storage.type.builtin, storage.type.primitive', 'type_builtin' },
  { 'Type', 'entity.name.type, entity.name.class, entity.name.type.class, storage.type.class, support.type, support.class', 'type' },
  { 'Inherited Class', 'entity.other.inherited-class', 'constructor' },
  { 'Namespace', 'entity.name.namespace, entity.name.module, support.module, support.type.package, variable.namespace', 'module' },
  { 'Label', 'entity.name.label', 'label' },
  { 'Builtin Function', 'support.function.builtin', 'func_builtin' },
  { 'Macro', 'entity.name.function.macro, entity.name.function.preprocessor', 'func_macro' },
  { 'Function', 'entity.name.function, support.function, variable.function', 'func' },
  { 'Builtin Variable', 'variable.language, variable.other.builtin, support.variable', 'variable_builtin' },
  { 'Parameter', 'variable.parameter', 'parameter' },
  { 'Member', 'variable.other.member, variable.other.property, support.variable.property, entity.name.function.member', 'member' },
  { 'Variable', 'variable, entity.name.variable', 'variable' },
  { 'Tag', 'entity.name.tag, entity.other.attribute-name.class.css, entity.other.attribute-name.pseudo-class', 'tag' },
  { 'Tag Delimiter', 'punctuation.definition.tag', 'tag_delimiter' },
  { 'Attribute', 'entity.other.attribute-name', 'tag_attribute' },
  { 'Attribute Id', 'entity.other.attribute-name.id, punctuation.definition.entity', 'reference' },
  { 'Data Key', 'entity.name.tag.yaml, entity.name.tag.toml, support.type.property-name, meta.mapping.key string, meta.mapping.key punctuation.definition.string, meta.object-literal.key, meta.object-literal.key string, string.unquoted.label', 'member' },
  { 'Heading', 'markup.heading, entity.name.section, markup.heading punctuation.definition.heading', 'cyan1', 'bold' },
  { 'Bold', 'markup.bold, punctuation.definition.bold', '', 'bold' },
  { 'Italic', 'markup.italic, punctuation.definition.italic', '', 'italic' },
  { 'Underline', 'markup.underline', '', 'underline' },
  { 'Quote', 'markup.quote, punctuation.definition.quote.begin.markdown', 'text2' },
  { 'Inline Code', 'markup.raw.inline, markup.inline.raw', 'red1' },
  { 'Fenced Code', 'markup.raw.block, markup.fenced_code.block', 'red1' },
  { 'Fence Punctuation', 'punctuation.definition.raw.markdown, punctuation.definition.fenced.markdown, variable.language.fenced.markdown', 'comment' },
  { 'Link Text', 'string.other.link, punctuation.definition.string.begin.markdown, punctuation.definition.string.end.markdown', 'blue0' },
  { 'Link Url', 'markup.underline.link, markup.link.url', 'orange0', { 'italic', 'underline' } },
  { 'Math', 'markup.math, string.other.math', 'blue0' },
  { 'Diff Inserted', 'markup.inserted, punctuation.definition.inserted', 'green1' },
  { 'Diff Deleted', 'markup.deleted, punctuation.definition.deleted', 'red1' },
  { 'Diff Changed', 'markup.changed', 'blue1' },
  { 'Diff Header', 'meta.diff.header, meta.diff.range', 'reference' },
  { 'Deprecated', 'invalid.deprecated', 'yellow1' },
  { 'Invalid', 'invalid, invalid.illegal', 'red1' },
  { 'Colour', 'constant.other.color, support.constant.color', 'special' },
}

function xml_escape(s)
  return (tostring(s):gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'))
end

function kv(indent, key, value)
  return ('%s<key>%s</key>\n%s<string>%s</string>\n')
    :format(indent, xml_escape(key), indent, xml_escape(value))
end

function font_style(role_hl, forced)
  local out = {}
  local function on(key)
    if role_hl and role_hl[key] == true then
      return true
    end
    if type(forced) == 'table' then
      for _, f in ipairs(forced) do
        if f == key then
          return true
        end
      end
      return false
    end
    return forced == key
  end
  if on('bold') then out[#out + 1] = 'bold' end
  if on('italic') then out[#out + 1] = 'italic' end
  if on('underline') then out[#out + 1] = 'underline' end
  return table.concat(out, ' ')
end

function global_dict(palette)
  local out = { '\t\t<dict>\n', '\t\t\t<key>settings</key>\n', '\t\t\t<dict>\n' }
  for _, row in ipairs(GLOBALS) do
    local hex = palette[row[2]]
    if hex then
      out[#out + 1] = kv('\t\t\t\t', row[1], hex)
    end
  end
  out[#out + 1] = '\t\t\t</dict>\n'
  out[#out + 1] = '\t\t</dict>\n'
  return table.concat(out)
end

function scope_dict(row, roles, palette)
  local role_hl = rawget(roles, row[3])
  local fg = (role_hl and role_hl.fg) or palette[row[3]]
  local style = font_style(role_hl, row[4])
  if not fg and style == '' then
    return ''
  end
  local out = {
    '\t\t<dict>\n',
    kv('\t\t\t', 'name', row[1]),
    kv('\t\t\t', 'scope', row[2]),
    '\t\t\t<key>settings</key>\n',
    '\t\t\t<dict>\n',
  }
  if fg then
    out[#out + 1] = kv('\t\t\t\t', 'foreground', fg)
  end
  if style ~= '' then
    out[#out + 1] = kv('\t\t\t\t', 'fontStyle', style)
  end
  out[#out + 1] = '\t\t\t</dict>\n'
  out[#out + 1] = '\t\t</dict>\n'
  return table.concat(out)
end

return M
