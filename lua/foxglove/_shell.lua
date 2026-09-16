
local M = {}

local generate

function M.write(path)
  path = vim.fn.expand(path)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
  local tmp = path .. '.tmp'
  local f = assert(io.open(tmp, 'w'))
  f:write(generate())
  f:close()
  assert(os.rename(tmp, path))
  return path
end

local function quote(s)
  return "'" .. (tostring(s):gsub("'", [['\'']])) .. "'"
end

local function is_hex(v)
  return type(v) == 'string' and v:match('^#%x%x%x%x%x%x$') ~= nil
end

local function sorted_keys(t)
  local keys = {}
  for key in pairs(t) do
    keys[#keys + 1] = key
  end
  table.sort(keys)
  return keys
end

local BRANCH_INDENT = '        '

local function emit_cases(entries)
  local out = {}
  for _, key in ipairs(sorted_keys(entries)) do
    out[#out + 1] = BRANCH_INDENT .. quote(key) .. ") printf '%s\\n' "
      .. quote(entries[key]) .. ' ;;'
  end
  return table.concat(out, '\n')
end

local function palette_entries(palette)
  local out = {}
  for key, value in pairs(palette) do
    if is_hex(value) then
      out[key] = value
    end
  end
  return out
end

local function role_entries(roles)
  local out = {}
  for role, hl in pairs(roles or {}) do
    if type(hl) == 'table' then
      for attr, value in pairs(hl) do
        if is_hex(value) then
          out[role .. '.' .. attr] = value
        elseif value == true then
          out[role .. '.' .. attr] = 'true'
        end
      end
    end
  end
  return out
end

local BOOL_ATTRS = {
  'bold', 'italic', 'underline', 'undercurl', 'underdouble', 'underdotted',
  'underdashed', 'strikethrough', 'reverse', 'standout', 'nocombine',
}

local DISPATCH = [=[
foxglove() {
  case "${1:-}" in
    palette)
      [ -n "${2:-}" ] || { printf 'usage: foxglove palette <hue>\n' >&2; return 2; }
      case "$2" in
@PALETTE@
        *) printf "foxglove: no palette hue '%s'\n" "$2" >&2; return 1 ;;
      esac
      ;;
    roles)
      case "${2:-}" in
        ?*.?*) ;;
        *) printf 'usage: foxglove roles <role>.<key>\n' >&2; return 2 ;;
      esac
      case "$2" in
@ROLES@
        *)
          case "${2##*.}" in
            @BOOL_ATTRS@) printf 'false\n' ;;
            *) return 1 ;;
          esac
          ;;
      esac
      ;;
    dark)
      return @DARK@
      ;;
    tmtheme)
      printf '%s\n' @TMTHEME@
      ;;
    *)
      printf 'usage: foxglove {palette <hue>|roles <role>.<key>|dark|tmtheme}\n' >&2
      return 2
      ;;
  esac
}
]=]

function generate()
  local root = require('foxglove')
  local tmtheme = require('foxglove._tmtheme')
  local palette = root.palette or {}
  local xml = tmtheme.build(palette, root.roles or {})

  return (DISPATCH
    :gsub('@PALETTE@', function()
      return emit_cases(palette_entries(palette))
    end)
    :gsub('@ROLES@', function()
      return emit_cases(role_entries(root.roles))
    end)
    :gsub('@BOOL_ATTRS@', table.concat(BOOL_ATTRS, '|'))
    :gsub('@DARK@', palette.dark and '0' or '1')
    :gsub('@TMTHEME@', function() return quote(xml) end))
end

return M
