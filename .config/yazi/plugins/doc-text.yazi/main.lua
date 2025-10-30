local M = {}

function M:peek(job)
  local path = tostring(job.file.url)
  local child
  local cmd

  local function render_blank()
    ya.preview_widgets(job, { ui.Text(""):area(job.area) })
  end

  -- Escape path for shell usage
  local escaped_path = path:gsub("'", "'\\''")

  if path:match('%.pdf$') or path:match('%.PDF$') then
    -- For PDF files, use pdftotext
    cmd = string.format("pdftotext '%s' -", escaped_path)
  elseif path:match('%.docx$') or path:match('%.DOCX$') then
    -- For DOCX files, use pandoc or docx2txt if available
    cmd = string.format("pandoc '%s' -t plain", escaped_path)
  elseif path:match('%.rtf$') or path:match('%.RTF$') then
    -- For RTF files, use pandoc
    cmd = string.format("pandoc '%s' -t plain", escaped_path)
  elseif path:match('%.doc$') or path:match('%.DOC$') then
    -- For DOC files, use antiword
    cmd = string.format("antiword '%s'", escaped_path)
  else
    ya.preview_widgets(job, { ui.Text("[Unsupported document format]"):area(job.area) })
    return
  end

  local spawn_err
  child, spawn_err = Command("sh")
    :arg("-c")
    :arg(cmd)
    :stdout(Command.PIPED)
    :stderr(Command.PIPED)
    :spawn()

  if not child then
    if spawn_err then
      ya.err(tostring(spawn_err))
    end
    render_blank()
    return
  end

  local output, output_err = child:wait_with_output()
  if not output then
    if output_err then
      ya.err(tostring(output_err))
    end
    render_blank()
    return
  end

  if not output.status or not output.status.success then
    if output.stderr and output.stderr ~= "" then
      ya.err(output.stderr)
    end
    render_blank()
    return
  end

  local stdout = output.stdout or ""
  if stdout:match("%S") == nil then
    render_blank()
    return
  end

  -- Clean up problematic control characters that break yazi's display
  -- Remove form feeds (\f) which cause blank screen issues
  stdout = stdout:gsub("\f", "")

  -- Remove excessive leading whitespace
  stdout = stdout:gsub("^%s*", "")

  -- Check if we still have content after cleanup
  if stdout:match("%S") == nil then
    render_blank()
    return
  end

  -- Create the text widget with scrolling applied
  local widget = ui.Text(stdout):area(job.area)
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