local M = {}

function M:peek(job)
  local path = tostring(job.file.url)
  local child
  local cmd

  -- Escape path for shell usage
  local escaped_path = path:gsub("'", "'\\''")

  if path:match('%.pdf$') or path:match('%.PDF$') then
    -- For PDF files, use pdftotext
    cmd = string.format("pdftotext '%s' -", escaped_path)
  elseif path:match('%.docx$') or path:match('%.DOCX$') then
    -- For DOCX files, use pandoc or docx2txt if available
    cmd = string.format("pandoc '%s' -t plain", escaped_path)
  elseif path:match('%.doc$') or path:match('%.DOC$') then
    -- For DOC files, use antiword
    cmd = string.format("antiword '%s'", escaped_path)
  else
    ya.preview_widgets(job, { ui.Text("[Unsupported document format]"):area(job.area) })
    return
  end

  child = Command("sh")
    :arg("-c")
    :arg(cmd)
    :stdout(Command.PIPED)
    :stderr(Command.PIPED)
    :spawn()

  if not child then
    ya.preview_widgets(job, { ui.Text("[Failed to spawn command]"):area(job.area) })
    return
  end

  local output = child:wait_with_output()
  if not output or not output.stdout or output.stdout == "" then
    ya.preview_widgets(job, { ui.Text("[No output - command may have failed or document is empty]"):area(job.area) })
    return
  end

  -- Create the text widget with scrolling applied
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