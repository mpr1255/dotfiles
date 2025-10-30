--- @sync entry
return {
	entry = function()
		local h = cx.active.current.hovered
		if h and h.cha.is_dir then
			ya.manager_emit("enter", { hovered = true })
		else
			-- Use macOS system default by running 'open' command directly
			local path = tostring(h.url)
			local escaped_path = path:gsub("'", "'\\''")
			local cmd = string.format("open '%s'", escaped_path)
			ya.manager_emit("shell", { cmd, orphan = true })
		end
	end,
}