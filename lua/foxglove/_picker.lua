
local M = {}

local foxglove = require('foxglove')
local cl = require('foxglove.colorlab')
local palettes = require('foxglove._palettes')
local specs = require('foxglove._specs')
local theme = require('foxglove._theme')

local ns = vim.api.nvim_create_namespace('foxglove-pick')
local ns_sel = vim.api.nvim_create_namespace('foxglove-pick-sel')
local ns_mark = vim.api.nvim_create_namespace('foxglove-pick-mark')

local ROWS_PER_ITEM = 2

local PRIORITY_ROW = 100
local PRIORITY_SEL = 200
local PRIORITY_MARK = 200

local MARK_SEL = vim.fn.nr2char(0x2022) -- •
local MARK_ORIGINAL = vim.fn.nr2char(0x25e6) -- ◦
local MARK_BOTH = vim.fn.nr2char(0x25c9) -- ◉

local SLOTS = { 'base', 'subtext', 'text', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'orange' }

local CODE = {
  { 'let', 'keyword' },
  { ' v: ' },
  { 'T', 'type' },
  { ' ' },
  { '=', 'operator' },
  { ' ' },
  { 'f', 'func' },
  { '(' },
  { '"a"', 'string' },
  { ', ' },
  { '1', 'number' },
  { ')' },
}

local DEFAULT_MAPS = {
  move_down = { '<C-n>', '<C-j>', '<Down>' },
  move_up = { '<C-p>', '<C-k>', '<Up>' },
  next_tab = { '<Tab>' },
  scroll_down = { '<PageDown>', '<C-M-d>' },
  scroll_up = { '<PageUp>', '<C-M-u>' },
  top = { '<M-a>' },
  bottom = { '<M-e>' },
  clear_input = { '<C-u>' },
}

local RULE = vim.fn.nr2char(0x2500)
local PROMPT = '>'

local function restorer()
  local original = theme.current
  local other = vim.g.colors_name
  return function()
    if original then
      theme.switch(original)
    else
      pcall(vim.cmd.colorscheme, other or 'default')
    end
  end
end

local function build_axes()
  local current = theme.current or {}
  return {
    { name = 'palettes', label = 'Palettes', key = 'palette', items = palettes.list(), original = current.palette,
      sep = ' ',
      cells = function(name)
        local ok, raw = pcall(palettes.resolve, name)
        local out = {}
        for i, slot in ipairs(SLOTS) do
          local hex = ok and cl.hex(raw[slot]) or nil
          out[i] = { attrs = hex and { fg = hex } or nil }
        end
        return out
      end },
    { name = 'specs', label = 'Specs', key = 'spec', items = specs.list(), original = current.spec,
      sep = '',
      cells = function(name)
        local ok, roles = pcall(specs.roles, name, foxglove.palette)
        local out = {}
        for i, tok in ipairs(CODE) do
          local hl = ok and tok[2] and roles[tok[2]] or nil
          out[i] = { text = tok[1], attrs = hl and {
            fg = hl.fg and cl.hex(hl.fg) or nil,
            bg = hl.bg and cl.hex(hl.bg) or nil,
            sp = hl.sp and cl.hex(hl.sp) or nil,
            bold = hl.bold, italic = hl.italic,
            underline = hl.underline, undercurl = hl.undercurl,
            strikethrough = hl.strikethrough,
          } or nil }
        end
        return out
      end },
  }
end

local cell_groups = {}
local cell_seq = 0

local function style_key(a)
  return table.concat({ a.fg or '', a.bg or '', a.sp or '',
    a.bold and 'b' or '', a.italic and 'i' or '', a.underline and 'u' or '',
    a.undercurl and 'c' or '', a.strikethrough and 's' or '' }, '|')
end

local function cell_group(attrs)
  local key = style_key(attrs)
  local name = cell_groups[key]
  if not name then
    cell_seq = cell_seq + 1
    name = 'FoxglovePickCell' .. cell_seq
    vim.api.nvim_set_hl(0, name, attrs)
    cell_groups[key] = name
  end
  return name
end

local function filter(items, query)
  if query == '' then
    local out = {}
    for i, name in ipairs(items) do
      out[i] = { name = name, positions = {} }
    end
    return out
  end
  local matched, positions = unpack(vim.fn.matchfuzzypos(items, query))
  local out = {}
  for i, name in ipairs(matched) do
    out[i] = { name = name, positions = positions[i] }
  end
  return out
end

function M.open()
  local axes = build_axes()
  local by_name = {}
  for _, axis in ipairs(axes) do
    by_name[axis.name] = axis
  end
  local active_axis = axes[1].name
  local maps = vim.tbl_extend('force', DEFAULT_MAPS, foxglove.config.maps or {})
  cell_groups, cell_seq = {}, 0

  local restore = restorer()
  local draft = { palette = by_name.palettes.original, spec = by_name.specs.original, preview = true }

  local strips, shown, selected, original = {}, {}, {}, {}

  local function rebuild_strip(name)
    local axis = by_name[name]
    strips[name] = {}
    for _, item in ipairs(axis.items) do
      strips[name][item] = axis.cells(item)
    end
  end

  for _, axis in ipairs(axes) do
    rebuild_strip(axis.name)
    shown[axis.name] = filter(axis.items, '')
    selected[axis.name] = axis.original
    original[axis.name] = axis.original
  end

  local index = 1

  local swatch = vim.g.have_nerd_font and vim.fn.nr2char(0xf14fb) or '■'
  local swatch_width = vim.fn.strdisplaywidth(swatch)
  local code_width = 0
  for _, tok in ipairs(CODE) do
    code_width = code_width + vim.fn.strdisplaywidth(tok[1])
  end
  by_name.palettes.strip_width = #SLOTS * swatch_width + (#SLOTS - 1)
  by_name.specs.strip_width = code_width
  local strip_width = math.max(by_name.palettes.strip_width, by_name.specs.strip_width)
  local gutter = vim.fn.strdisplaywidth(PROMPT) + 1

  local name_width = 0
  for _, axis in ipairs(axes) do
    for _, name in ipairs(axis.items) do
      name_width = math.max(name_width, vim.fn.strdisplaywidth(name))
    end
  end
  local width = gutter + name_width + 2 + strip_width + 1

  local list = vim.api.nvim_create_buf(false, true)
  local prompt = vim.api.nvim_create_buf(false, true)
  local tabs = vim.api.nvim_create_buf(false, true)
  vim.bo[prompt].buftype = 'prompt'
  vim.fn.prompt_setprompt(prompt, PROMPT .. ' ')

  local col = vim.o.columns - width - 2
  local usable = vim.o.lines - vim.o.cmdheight - 1
  local prompt_win = vim.api.nvim_open_win(prompt, true,
    { relative = 'editor', row = 0, col = col,
      width = width, height = 1, style = 'minimal', border = 'rounded' })
  local tabs_win = vim.api.nvim_open_win(tabs, false,
    { relative = 'editor', row = 3, col = col,
      width = width + 2, height = 1, style = 'minimal' })
  local list_win = vim.api.nvim_open_win(list, false,
    { relative = 'editor', row = 4, col = col,
      width = width, height = math.max(1, usable - 6), style = 'minimal', border = 'rounded' })
  vim.wo[prompt_win].winhighlight =
    'NormalFloat:FoxglovePickerPrompt,FloatBorder:FoxglovePickerPromptBorder'
  vim.wo[list_win].wrap = false

  local function mid_row(i) return (i - 1) * ROWS_PER_ITEM + 1 end
  local function rule_below(i) return mid_row(i) + 1 end

  local closed = false
  local function teardown()
    if closed then
      return false
    end
    closed = true
    pcall(vim.api.nvim_win_close, prompt_win, true)
    pcall(vim.api.nvim_win_close, tabs_win, true)
    pcall(vim.api.nvim_win_close, list_win, true)
    pcall(vim.api.nvim_buf_delete, prompt, { force = true })
    pcall(vim.api.nvim_buf_delete, tabs, { force = true })
    pcall(vim.api.nvim_buf_delete, list, { force = true })
    vim.cmd.stopinsert()
    return true
  end

  local function confirm()
    if not teardown() then
      return
    end
    local final = {}
    for _, axis in ipairs(axes) do
      final[axis.key] = selected[axis.name]
    end
    theme.switch(final)
  end

  local function abort()
    if teardown() then
      restore()
    end
  end

  local function render_selection()
    vim.api.nvim_buf_clear_namespace(list, ns_sel, 0, -1)
    local palette = foxglove.palette or {}
    local bg_high = palette.base3
    local fg_high = palette.text0
    vim.api.nvim_set_hl(0, 'FoxglovePickerPrompt',
      { fg = fg_high, bg = bg_high, bold = true })
    vim.api.nvim_set_hl(0, 'FoxglovePickerPromptBorder',
      { fg = bg_high, bg = bg_high })
    vim.api.nvim_set_hl(0, 'FoxglovePickerRule', { fg = palette.base4 })
    vim.api.nvim_set_hl(0, 'FoxglovePickerName', { fg = palette.text2 })
    vim.api.nvim_set_hl(0, 'FoxglovePickerSel', { fg = fg_high, bold = true })
    vim.api.nvim_set_hl(0, 'FoxglovePickerOriginal', { fg = palette.text2 })
    vim.api.nvim_set_hl(0, 'FoxglovePickerTabActive', { fg = palette.base0, bg = palette.text1, bold = true })
    vim.api.nvim_set_hl(0, 'FoxglovePickerTabInactive', { fg = palette.subtext0, bg = palette.base2 })

    local item = shown[active_axis][index]
    if not item then
      return
    end
    vim.api.nvim_buf_set_extmark(list, ns_sel, mid_row(index) - 1, gutter,
      { end_col = gutter + #item.name, hl_group = 'FoxglovePickerSel', priority = PRIORITY_SEL })
    pcall(vim.api.nvim_win_set_cursor, list_win, { mid_row(index), 0 })
    pcall(vim.api.nvim_win_call, list_win, function()
      local view = vim.fn.winsaveview()
      if view.topline % ROWS_PER_ITEM == 0 then
        view.topline = view.topline + 1
        vim.fn.winrestview(view)
      end
    end)
  end

  local function render_marker()
    vim.api.nvim_buf_clear_namespace(list, ns_mark, 0, -1)
    local original_row
    for i, item in ipairs(shown[active_axis]) do
      if item.name == original[active_axis] then
        original_row = i
        break
      end
    end
    local function mark(row, glyph, hl_group)
      vim.api.nvim_buf_set_extmark(list, ns_mark, mid_row(row) - 1, 0, {
        virt_text = { { glyph, hl_group } },
        virt_text_pos = 'overlay',
        priority = PRIORITY_MARK,
      })
    end
    if original_row and original_row == index then
      mark(index, MARK_BOTH, 'FoxglovePickerSel')
    else
      if shown[active_axis][index] then
        mark(index, MARK_SEL, 'FoxglovePickerSel')
      end
      if original_row then
        mark(original_row, MARK_ORIGINAL, 'FoxglovePickerOriginal')
      end
    end
  end

  local function render_tabs()
    local span = vim.api.nvim_win_get_width(tabs_win)
    local left_span = math.floor(span / 2)
    local spans = { left_span, span - left_span }
    local marks = {}
    local text = ''
    for i, axis in ipairs(axes) do
      local w = spans[i]
      local lw = vim.fn.strdisplaywidth(axis.label)
      local before = math.floor(math.max(0, w - lw) / 2)
      local after = math.max(0, w - lw - before)
      local from = #text
      text = text .. (' '):rep(before) .. axis.label .. (' '):rep(after)
      marks[#marks + 1] = { col = from, end_col = #text,
        hl_group = axis.name == active_axis and 'FoxglovePickerTabActive' or 'FoxglovePickerTabInactive' }
    end

    vim.bo[tabs].modifiable = true
    vim.api.nvim_buf_set_lines(tabs, 0, -1, false, { text })
    vim.bo[tabs].modifiable = false

    vim.api.nvim_buf_clear_namespace(tabs, ns, 0, -1)
    for _, mark in ipairs(marks) do
      pcall(vim.api.nvim_buf_set_extmark, tabs, ns, 0, mark.col,
        { end_col = mark.end_col, hl_group = mark.hl_group })
    end
  end

  local function render_list()
    local lines, marks = {}, {}
    local span = vim.api.nvim_win_get_width(list_win)
    local rule = RULE:rep(span)

    local axis = by_name[active_axis]
    local sep = axis.sep
    local lead = (' '):rep(math.max(0, strip_width - axis.strip_width))
    local list_shown, list_cells = shown[active_axis], strips[active_axis]
    for i, item in ipairs(list_shown) do
      local pad = (' '):rep(name_width - vim.fn.strdisplaywidth(item.name) + 2)
      local prefix = (' '):rep(gutter) .. item.name .. pad .. lead

      local strip, cells = {}, list_cells[item.name] or {}
      for _, cell in ipairs(cells) do
        local text = cell.text or (cell.attrs and swatch or (' '):rep(swatch_width))
        strip[#strip + 1] = text
        if cell.attrs then
          local at = #prefix + #table.concat(strip, sep) - #text
          marks[#marks + 1] = { row = mid_row(i) - 1, col = at,
            end_col = at + #text, hl_group = cell_group(cell.attrs) }
        end
      end
      local line = prefix .. table.concat(strip, sep)
      lines[mid_row(i)] = line .. (' '):rep(math.max(0, span - vim.fn.strdisplaywidth(line)))
      marks[#marks + 1] = { row = mid_row(i) - 1, col = gutter,
        end_col = gutter + #item.name, hl_group = 'FoxglovePickerName', priority = PRIORITY_ROW }
      if i < #list_shown then
        lines[rule_below(i)] = rule
        marks[#marks + 1] = { row = rule_below(i) - 1, col = 0, end_col = #rule,
          hl_group = 'FoxglovePickerRule', priority = PRIORITY_ROW }
      end
    end

    vim.bo[list].modifiable = true
    vim.api.nvim_buf_set_lines(list, 0, -1, false, lines)
    vim.bo[list].modifiable = false

    vim.api.nvim_buf_clear_namespace(list, ns, 0, -1)
    for _, mark in ipairs(marks) do
      pcall(vim.api.nvim_buf_set_extmark, list, ns, mark.row, mark.col, {
        end_col = mark.end_col,
        hl_group = mark.hl_group,
        priority = mark.priority,
      })
    end
    for i, item in ipairs(list_shown) do
      for _, pos in ipairs(item.positions or {}) do
        pcall(vim.api.nvim_buf_set_extmark, list, ns, mid_row(i) - 1, gutter + pos,
          { end_col = gutter + pos + 1, hl_group = 'PmenuMatch' })
      end
    end
  end

  local function preview_selection()
    local item = shown[active_axis][index]
    if not item then
      return
    end
    selected[active_axis] = item.name
    draft[by_name[active_axis].key] = item.name
    pcall(theme.render, draft)
    if active_axis == 'palettes' then
      rebuild_strip('specs')
    end
  end

  local function select_at(i)
    index = i
    preview_selection()
    render_selection()
    render_marker()
  end

  local function move_wrapping(delta)
    if #shown[active_axis] == 0 then
      return
    end
    select_at((index - 1 + delta) % #shown[active_axis] + 1)
  end

  local function move_clamped(delta)
    if #shown[active_axis] == 0 then
      return
    end
    select_at(math.max(1, math.min(#shown[active_axis], index + delta)))
  end

  local function refresh_shown()
    local line = vim.api.nvim_buf_get_lines(prompt, 0, 1, false)[1] or ''
    local query = line:sub(#PROMPT + 2)
    shown[active_axis] = filter(by_name[active_axis].items, query)
    index = 1
    if query == '' then
      for i, item in ipairs(shown[active_axis]) do
        if item.name == selected[active_axis] then
          index = i
          break
        end
      end
    end
  end

  local function clear_prompt()
    vim.api.nvim_buf_set_lines(prompt, 0, -1, false, { PROMPT .. ' ' })
    pcall(vim.api.nvim_win_set_cursor, prompt_win, { 1, #PROMPT + 1 })
  end

  local function redraw()
    refresh_shown()
    preview_selection()
    render_list()
    render_selection()
    render_marker()
  end

  local function switch_axis(next_axis)
    if next_axis == active_axis or not by_name[next_axis] then
      return
    end
    active_axis = next_axis
    clear_prompt()
    redraw()
    render_tabs()
  end

  local function revert_axis()
    selected[active_axis] = original[active_axis]
    clear_prompt()
    redraw()
  end

  local function cycle(delta)
    local at = 1
    for i, axis in ipairs(axes) do
      if axis.name == active_axis then
        at = i
        break
      end
    end
    switch_axis(axes[(at - 1 + delta) % #axes + 1].name)
  end

  vim.api.nvim_create_autocmd({ 'TextChangedI', 'TextChanged' }, {
    buffer = prompt,
    callback = redraw,
  })

  local function clear_and_redraw()
    clear_prompt()
    redraw()
  end

  local function map(lhs, fn)
    vim.keymap.set({ 'i', 'n' }, lhs, fn, { buffer = prompt, nowait = true })
  end
  local function bind(action, fn)
    local lhs = maps[action]
    if type(lhs) == 'string' then
      lhs = { lhs }
    end
    for _, one in ipairs(lhs or {}) do
      map(one, fn)
    end
  end

  bind('move_down', function() move_wrapping(1) end)
  bind('move_up', function() move_wrapping(-1) end)
  bind('next_tab', function() cycle(1) end)

  local function page(delta)
    return function()
      local rows = vim.api.nvim_win_get_height(list_win)
      move_clamped(delta * math.max(1, math.floor(rows / ROWS_PER_ITEM)))
    end
  end
  bind('scroll_down', page(1))
  bind('scroll_up', page(-1))

  bind('top', function()
    if #shown[active_axis] > 0 then select_at(1) end
  end)
  bind('bottom', function()
    if #shown[active_axis] > 0 then select_at(#shown[active_axis]) end
  end)

  bind('clear_input', clear_and_redraw)

  local function cancel()
    if selected[active_axis] ~= original[active_axis] then
      revert_axis()
    else
      abort()
    end
  end

  map('<CR>', confirm)
  map('<Esc>', cancel)
  map('<C-c>', abort)

  vim.api.nvim_create_autocmd('BufLeave', {
    buffer = prompt,
    once = true,
    callback = abort,
  })

  redraw()
  render_tabs()
  vim.cmd.startinsert()
end

return M
