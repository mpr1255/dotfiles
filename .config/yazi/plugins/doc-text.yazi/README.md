# Document Text Preview Plugin for Yazi

This plugin provides text preview functionality for various document formats in yazi file manager.

## Supported Formats

- **PDF**: Uses `pdftotext` to extract text content
- **DOCX**: Uses `pandoc` to convert to plain text
- **DOC**: Uses `antiword` to extract text

## How It Works

The plugin follows this flow:

1. **File Type Detection**: Matches file extensions to determine the appropriate extraction tool
2. **Command Execution**: Runs the tool via shell command with piped output
3. **Text Cleanup**: Removes problematic characters that can break yazi's display
4. **Widget Rendering**: Creates a scrollable text widget for the preview pane

## Key Implementation Details

### Path Escaping
```lua
local escaped_path = path:gsub("'", "'\\''")
```
Handles file paths with special characters by escaping single quotes for shell safety.

### Command Execution Pattern
```lua
child, spawn_err = Command("sh")
  :arg("-c")
  :arg(cmd)
  :stdout(Command.PIPED)
  :stderr(Command.PIPED)
  :spawn()
```
Uses yazi's Command API to execute shell commands with proper output capture.

### Critical Text Cleanup
```lua
-- Remove form feeds (\f) which cause blank screen issues
stdout = stdout:gsub("\f", "")

-- Remove excessive leading whitespace
stdout = stdout:gsub("^%s*", "")
```

**This cleanup is ESSENTIAL** - some PDFs contain many form feed characters (`\f`) that cause yazi to display blank screens, making it appear that the interface is broken. The cleanup ensures readable content is displayed.

## Common Issues and Solutions

### Problem: No Preview for Any PDFs
**Cause**: Plugin syntax errors or missing dependencies
**Solution**:
1. Check lua syntax: `luac -p main.lua`
2. Verify `pdftotext` is installed: `which pdftotext`
3. Test command manually: `pdftotext "file.pdf" -`

### Problem: PDFs with Blank Screens
**Cause**: Form feed characters (`\f`) in PDF text output
**Solution**: The plugin now automatically strips these characters
**Example**: Anna's Archive PDFs often have 100+ form feeds at the start

### Problem: Plugin Completely Broken
**Cause**: Complex fallback logic or variable scope issues
**Solution**: Keep the implementation simple - avoid complex shell commands with `||` operators

## Dependencies

- `pdftotext` (from poppler-utils)
- `pandoc` (for DOCX files)
- `antiword` (for DOC files)

## Configuration

The plugin is automatically loaded when configured in `yazi.toml`:

```toml
[plugin]
prepend_previewers = [
  { name = "*.pdf", run = "doc-text" },
  { name = "*.PDF", run = "doc-text" },
  { name = "*.doc", run = "doc-text" },
  { name = "*.DOC", run = "doc-text" },
  { name = "*.docx", run = "doc-text" },
  { name = "*.DOCX", run = "doc-text" },
]
```

## Future Enhancements

### Textra Integration (OCR Fallback)
For image-based PDFs that `pdftotext` can't handle, `textra` (macOS) could be added as a fallback:

```bash
# Simple approach - only when pdftotext completely fails
pdftotext 'file.pdf' - || textra 'file.pdf' --outputStdout
```

**Warning**: Complex fallback logic with quality detection has proven fragile. Keep it simple.

### File Size Limits
Consider adding file size checks for very large documents:

```lua
local stat = fs.stat(Url(path))
if stat and stat.len > 100 * 1024 * 1024 then  -- 100MB
  ya.preview_widgets(job, { ui.Text("[File too large]"):area(job.area) })
  return
end
```

## Development Notes

- **Keep it simple**: Complex logic leads to hard-to-debug issues
- **Test edge cases**: PDFs with unusual content (like Anna's Archive) expose problems
- **Minimal changes**: Each modification should solve exactly one problem
- **Error handling**: Always provide graceful fallbacks instead of crashes

## Testing

Test with these types of PDFs:
1. **Normal text PDFs**: Regular documents with extractable text
2. **Image PDFs**: Scanned documents requiring OCR
3. **Problematic PDFs**: Files with control characters (Anna's Archive, DuXiu collection)
4. **Large PDFs**: Files that might cause performance issues

## Debugging

If previews stop working:

1. **Test extraction manually**:
   ```bash
   pdftotext "/path/to/file.pdf" -
   ```

2. **Check for form feeds**:
   ```bash
   pdftotext "/path/to/file.pdf" - | hexdump -C | head -20
   ```

3. **Verify plugin loading**:
   Check yazi logs for lua errors or plugin loading issues.