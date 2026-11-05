
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
    dark)
      return @DARK@
      ;;
    tmtheme)
      printf '%s\n' @TMTHEME@
      ;;
    *)
      printf 'usage: foxglove {palette <hue>|dark|tmtheme}\n' >&2
      return 2
      ;;
  esac
}
]=]

function generate()
  local theme = require('foxglove._theme')
  local tmtheme = require('foxglove._tmtheme')
  local palette = theme.palette or {}
  local xml = tmtheme.build(palette, theme.groups or {})

  return (DISPATCH
    :gsub('@PALETTE@', function()
      return emit_cases(palette_entries(palette))
    end)
    :gsub('@DARK@', palette.dark and '0' or '1')
    :gsub('@TMTHEME@', function() return quote(xml) end))
end

return M
