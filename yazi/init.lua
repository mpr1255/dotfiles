
local old_linemode = Folder.linemode
function Folder:linemode(area)
  if cx.active.conf.linemode ~= "my-own" then
    return old_linemode(self, area)
  end

  local lines = {}
  local current_year = os.date("%Y")
  local today = os.date("%Y%m%d")
  for _, f in ipairs(self:by_kind(self.CURRENT).window) do
    local mod_time = f.cha.modified // 1
    local time_str = ""
    if mod_time then
        local mod_year = os.date("%Y", mod_time)
        local is_today = today == os.date("%Y%m%d", mod_time)

        if is_today then
            -- For files modified today: Show "Today" and the time
            time_str = "Today " .. os.date("%H:%M", mod_time)
        elseif mod_year == current_year then
            -- For files modified this year (not today): Show month, day, and time without the year
            time_str = os.date("%b %d %H:%M", mod_time)
        else
            -- For files from previous years: Show month, day, and year
            time_str = os.date("%b %d %Y", mod_time)
        end
    end

    local size = f:size()
    lines[#lines + 1] = ui.Line {
      ui.Span(" "),
      ui.Span(size and ya.readable_size(size):gsub(" ", "") or "-"),
      ui.Span(" "),
      ui.Span(time_str),
      ui.Span(" "),
    }
  end
  return ui.Paragraph(area, lines):align(ui.Paragraph.RIGHT)
end

require("zoxide"):setup {
    update_db = true,
}

require("session"):setup {
	sync_yanked = true,
}

Header = {
	area = ui.Rect.default,
}

function Header:cwd()
	local cwd = cx.active.current.cwd

	local span
	if not cwd.is_search then
		span = ui.Span(ya.readable_path(tostring(cwd)))
	else
		span = ui.Span(string.format("%s (search: %s)", ya.readable_path(tostring(cwd)), cwd.frag))
	end
	return span:style(THEME.manager.cwd)
end

function Header:host()
	if ya.target_family() ~= "unix" then
		return ui.Line {}
	end
	return ui.Span(ya.user_name() .. "@" .. ya.host_name() .. ":"):fg("blue")
end


function Header:tabs()
	local spans = {}
	for i = 1, #cx.tabs do
		local text = i
		if THEME.manager.tab_width > 2 then
			text = ya.truncate(text .. " " .. cx.tabs[i]:name(), THEME.manager.tab_width)
		end
		if i == cx.tabs.idx + 1 then
			spans[#spans + 1] = ui.Span(" " .. text .. " "):style(THEME.manager.tab_active)
		else
			spans[#spans + 1] = ui.Span(" " .. text .. " "):style(THEME.manager.tab_inactive)
		end
	end
	return ui.Line(spans)
end

function Header:layout(area)
	self.area = area

	return ui.Layout()
		:direction(ui.Layout.HORIZONTAL)
		:constraints({ ui.Constraint.Percentage(100), ui.Constraint.Percentage(100) })
		:split(area)
end

function Header:render(area)
	local chunks = self:layout(area)

	local left = ui.Line {self:cwd() } -- deleted self:host()
	local right = ui.Line { self:tabs() }
	return {
		ui.Paragraph(chunks[1], { left }),
		ui.Paragraph(chunks[2], { right }):align(ui.Paragraph.RIGHT),
	}
end

Manager = {
	area = ui.Rect.default,
}

function Manager:layout(area)
	self.area = area

	return ui.Layout()
		:direction(ui.Layout.HORIZONTAL)
		:constraints({
			ui.Constraint.Ratio(MANAGER.ratio.parent, MANAGER.ratio.all),
			ui.Constraint.Ratio(MANAGER.ratio.current, MANAGER.ratio.all),
			ui.Constraint.Ratio(MANAGER.ratio.preview, MANAGER.ratio.all),
		})
		:split(area)
end

function Manager:render(area)
	local chunks = self:layout(area)

	return ya.flat {
		-- Borders
		ui.Bar(chunks[1], ui.Bar.RIGHT):symbol(THEME.manager.border_symbol):style(THEME.manager.border_style),
		ui.Bar(chunks[3], ui.Bar.LEFT):symbol(THEME.manager.border_symbol):style(THEME.manager.border_style),

		-- Parent
		Parent:render(chunks[1]:padding(ui.Padding.x(1))),
		-- Current
		Current:render(chunks[2]),
		-- Preview
		Preview:render(chunks[3]:padding(ui.Padding.x(1))),
	}
end



--      -- function Manager:render(area)
        --  self.area = area

        --  local chunks = ui.Layout()
        --  	:direction(ui.Layout.HORIZONTAL)
        --  	:constraints({
        --  		ui.Constraint.Ratio(MANAGER.ratio.parent, MANAGER.ratio.all),
        --  		ui.Constraint.Ratio(MANAGER.ratio.current, MANAGER.ratio.all),
        --  		ui.Constraint.Ratio(MANAGER.ratio.preview, MANAGER.ratio.all),
        --  	})
        --  	:split(area)

        --  local bar = function(c, x, y)
        --  	return ui.Bar(
        --  		ui.Rect { x = math.max(0, x), y = math.max(0, y), w = math.min(1, area.w), h = math.min(1, area.h) },
        --  		ui.Bar.TOP
        --  	):symbol(c)
        --  end

        --  return ya.flat {
        --  	-- Borders
        --  	ui.Border(area, ui.Border.ALL):type(ui.Border.ROUNDED),
        --  	ui.Bar(chunks[1], ui.Bar.RIGHT),
        --  	ui.Bar(chunks[3], ui.Bar.LEFT),

        --  	bar("┬", chunks[1].right - 1, chunks[1].y),
        --  	bar("┴", chunks[1].right - 1, chunks[1].bottom - 1),
        --  	bar("┬", chunks[2].right, chunks[2].y),
        --  	bar("┴", chunks[2].right, chunks[1].bottom - 1),

        --  	-- Parent
        --  	Parent:render(chunks[1]:padding(ui.Padding.xy(1))),
        --  	-- Current
        --  	Current:render(chunks[2]:padding(ui.Padding.y(1))),
        --  	-- Preview
        --  	Preview:render(chunks[3]:padding(ui.Padding.xy(1))),
        --  }
--en      --d
