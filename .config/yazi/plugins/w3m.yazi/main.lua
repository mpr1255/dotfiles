local M = {}

function M:peek(job)
  local path = tostring(job.file.url)
  local child

  if path:match('%.mht$') or path:match('%.mhtml$') then
    -- For MHT files, we need to use shell for piping but handle unicode properly
    -- Use single quotes and escape only single quotes in the filename
    local escaped_path = path:gsub("'", "'\\''")
    local cmd = string.format("/Users/m/go/bin/mhtml-to-html '%s' | w3m -dump -T text/html -", escaped_path)

    child = Command("sh")
      :arg("-c")
      :arg(cmd)
      :stdout(Command.PIPED)
      :stderr(Command.PIPED)
      :spawn()
  else
    -- For regular HTML files - use Command directly to handle unicode
    child = Command("w3m")
      :arg("-dump")
      :arg("-T")
      :arg("text/html")
      :arg(path)
      :stdout(Command.PIPED)
      :stderr(Command.PIPED)
      :spawn()
  end

  if not child then
    ya.preview_widgets(job, { ui.Text("[Failed to spawn command]"):area(job.area) })
    return
  end

  local output = child:wait_with_output()
  if not output or not output.stdout or output.stdout == "" then
    ya.preview_widgets(job, { ui.Text("[No output - command may have failed]"):area(job.area) })
    return
  end

  -- Create the text widget with scrolling applied (x, y)
  local widget = ui.Text(output.stdout):area(job.area)
  if job.skip and job.skip > 0 then
    widget = widget:scroll(0, job.skip)
  end

  ya.preview_widgets(job, { widget })
end

function M:seek(job)
  local h = cx.active.current.hovered
  if not h or h.url ~= job.file.url then
    return
  end

  local step = math.floor(job.units * job.area.h / 10)
  if step == 0 then
    step = job.units > 0 and 1 or -1
  end

  ya.emit("peek", {
    math.max(0, cx.active.preview.skip + step),
    only_if = job.file.url,
  })
end

return M