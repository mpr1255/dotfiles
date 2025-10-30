function Linemode:size()
	local size = self._file:size()
	return ui.Line {
		ui.Span(size and ya.readable_size(size) or "-"):fg("cyan")
	}
end

function Linemode:permissions()
	return ui.Line {
		ui.Span(self._file.cha:permissions() or ""):fg("cyan")
	}
end

function Linemode:mtime()
	local time = math.floor(self._file.cha.mtime or 0)
	if time == 0 then
		return ui.Line("")
	elseif os.date("%Y", time) == os.date("%Y") then
		return ui.Line {
			ui.Span(os.date("%b %d %H:%M", time)):fg("cyan")
		}
	else
		return ui.Line {
			ui.Span(os.date("%b %d  %Y", time)):fg("cyan")
		}
	end
end

function Linemode:file_info()
	local year = os.date("%Y")
	local time = math.floor(self._file.cha.mtime or 0)
	local time_str = ""

	if time > 0 then
		if os.date("%Y", time) == year then
			time_str = os.date("%d-%m %H:%M", time)
		else
			time_str = os.date("%d-%m-%Y", time)
		end
	end

	return ui.Line {
		ui.Span(time_str):fg("cyan")
	}
end

-- === Yazi Plugins ===
-- zoxide and session are built-in preset plugins (no installation needed)
-- fr, compress, and smart-enter are included in .config/yazi/plugins/

require("zoxide"):setup({
	update_db = true,
})

require("session"):setup({
	sync_yanked = true,
})

-- require("fr"):setup({
-- 	fzf = [[--info-command='echo -e "$FZF_INFO 💛"' --no-scrollbar --preview-window top:60%:wrap --color=bg+:242,fg+:15,hl+:11 --color=info:110,prompt:109,spinner:108,pointer:65,marker:65,header:245 --height 100% --bind "enter:execute-silent(echo {} | xargs -n 1 open -g)" --color "hl:-1:underline,hl+:-1:underline:reverse"]],
-- 	rg = "--colors 'line:fg:red' --colors 'match:style:bold' --colors 'match:fg:black' --colors 'match:bg:yellow'",
-- 	bat = "--style 'header,grid' --color=always",
-- 	rga = {
-- 		"--follow",
-- 		"--hidden",
-- 		"--no-ignore",
-- 		"--glob",
-- 		"'!.git'",
-- 		"--glob",
-- 		"!'.venv'",
-- 		"--glob",
-- 		"'!node_modules'",
-- 		"--glob",
-- 		"'!.history'",
-- 		"--glob",
-- 		"'!.Rproj.user'",
-- 		"--glob",
-- 		"'!.ipynb_checkpoints'",
-- 	},
-- 	rga_preview = {
-- 		"--colors 'line:fg:red'"
-- 			.. " --colors 'match:fg:blue'"
-- 			.. " --colors 'match:bg:white'"
-- 			.. " --colors 'match:style:nobold'",
-- 	},
-- })

require("fr"):setup({
	-- fzf options: Reverted 'enter' bind back to full-path subl for testing
	fzf = "--height 100% --preview-window top:60%:wrap --no-scrollbar --info-command='echo \"$FZF_INFO 💛\"' --color=bg+:#FFFF00,bg:#000000,spinner:#fb4934,hl:#FF0000,fg:#ebdbb2,header:#928374,info:#8ec07c,pointer:#fb4934,marker:#fb4934,fg+:#FF0000,prompt:#fb4934,hl+:#FF0000 --bind \"enter:execute('$EDITOR {1}:{2}')\"",
	-- NOTE: Removed the '-b' background flag temporarily from subl

	-- rg colors (as verified by you)
	rg = "--colors 'line:fg:red' --colors 'match:style:bold' --colors 'match:fg:blue' --colors 'match:bg:yellow'",

	-- bat configuration: Removed --theme setting
	bat = "--style 'header,grid' --color=always", -- No theme specified for now

	-- rga configuration
	rga = {
		"--follow",
		"--hidden",
		"--no-ignore",
		"--glob",
		"'!.git'",
		"--glob",
		"'!.venv'",
		"--glob",
		"'!node_modules'",
		"--glob",
		"'!.history'",
		"--glob",
		"'!.Rproj.user'",
		"--glob",
		"'!.ipynb_checkpoints'",
	},

	-- rga_preview configuration
	rga_preview = {
		"--colors 'line:fg:red'"
			.. " --colors 'match:fg:blue'"
			.. " --colors 'match:bg:white'"
			.. " --colors 'match:style:nobold'",
	},
})

