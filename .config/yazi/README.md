# Yazi Configuration

This directory contains a comprehensive yazi file manager configuration with custom plugins and preview functionality.

## Directory Structure

```
~/.config/yazi/
├── README.md              # This file - overview of the setup
├── yazi.toml              # Main configuration file
├── keymap.toml            # Key bindings
├── theme.toml             # Visual theme settings
├── init.lua               # Yazi initialization script
├── package.toml           # Plugin package definitions
├── plugins/               # Custom plugins directory
│   ├── doc-text.yazi/     # Document preview plugin (PDF, DOC, DOCX)
│   ├── w3m.yazi/          # HTML/MHTML preview plugin
│   ├── rich-preview.yazi/ # Rich text preview plugin
│   └── [other plugins]/
└── flavors/               # Color scheme definitions
    ├── catppuccin-mocha.yazi/
    └── ayu-dark.yazi/
```

## Key Features

### Document Preview System

The configuration includes a sophisticated document preview system that converts various file types to text for preview in yazi:

#### Supported Formats:
- **PDF files** → `pdftotext` (with form feed cleanup)
- **HTML/MHTML files** → `w3m` browser
- **DOC files** → `antiword`
- **DOCX files** → `pandoc`

#### Configuration (yazi.toml):
```toml
[plugin]
prepend_previewers = [
  { name = "*.html", run = "w3m" },
  { name = "*.mhtml", run = "w3m" },
  { name = "*.mht", run = "w3m" },
  { name = "*.pdf", run = "doc-text" },
  { name = "*.PDF", run = "doc-text" },
  { name = "*.doc", run = "doc-text" },
  { name = "*.DOC", run = "doc-text" },
  { name = "*.docx", run = "doc-text" },
  { name = "*.DOCX", run = "doc-text" },
]
```

### Critical: PDF Preview Issues

**Problem**: Some PDFs (especially from Anna's Archive/DuXiu collection) contain many form feed characters (`\f`) that cause yazi to display blank screens, making the interface appear broken.

**Solution**: The `doc-text.yazi` plugin includes cleanup logic:
```lua
-- Remove form feeds (\f) which cause blank screen issues
stdout = stdout:gsub("\f", "")
-- Remove excessive leading whitespace
stdout = stdout:gsub("^%s*", "")
```

**Example Problematic File**:
```
/Users/m/dls/中国公民器官捐献500问 = Five hundred questions of Chinese citizen -- [details].pdf
```
This file starts with 176 form feed characters that would break the display without cleanup.

### Opener Configuration

Custom file openers for different document types:

```toml
[opener]
pdf_text = [
  { run = 'pdftotext "$1" - | nvim', block = true },
]

doc_text = [
  { run = 'antiword "$1" | nvim', block = true },
]

docx_text = [
  { run = 'pandoc "$1" -t plain | nvim', block = true },
]

mhtml_browser = [
  { run = 'mhtml-to-html "$1" | w3m -T text/html | nvim', block = true },
]

w3m_open = [
  { run = 'w3m "$@" | nvim', block = true},
]
```

### Open Rules

Associates file types with appropriate openers:

```toml
[open]
rules = [
  { name = "*.html", use = ["w3m_open", "browser", "text", "subl" ] },
  { name = "*.mhtml", use = [ "mhtml_browser"] },
  { name = "*.mht", use = [ "mhtml_browser"] },
  { name = "*.pdf", use = [ "pdf_text", "open" ] },
  { name = "*.doc", use = [ "doc_text", "open" ] },
  { name = "*.docx", use = [ "docx_text", "open" ] },
  # ... other rules
]
```

## Dependencies

Ensure these tools are installed for full functionality:

### Required for Document Previews:
- `pdftotext` (from poppler-utils) - PDF text extraction
- `pandoc` - DOCX to text conversion
- `antiword` - DOC to text conversion
- `w3m` - HTML/MHTML rendering

### Installation (macOS):
```bash
brew install poppler pandoc w3m
# antiword may need separate installation
```

### Optional OCR Enhancement:
- `textra` (macOS only) - For image-based PDFs that pdftotext can't handle

## Plugin Development Guidelines

**Critical Lessons Learned:**

1. **Keep It Simple**: Complex fallback logic (like quality detection + textra fallback) breaks easily. Simple approaches work better.

2. **Test Edge Cases**: Files from Anna's Archive, DuXiu collection, and other sources often have unusual formatting that exposes bugs.

3. **Minimal Changes**: Each modification should solve exactly one problem. Don't over-engineer.

4. **Handle Control Characters**: Form feeds (`\f`) and other control characters can break yazi's display completely.

## Common Issues & Debugging

### No PDF Previews
```bash
# Test extraction manually
pdftotext "/path/to/file.pdf" -

# Check plugin syntax
luac -p ~/.config/yazi/plugins/doc-text.yazi/main.lua

# Verify dependencies
which pdftotext pandoc antiword w3m
```

### PDFs Showing Blank Screens
```bash
# Check for problematic characters
pdftotext "/path/to/file.pdf" - | hexdump -C | head -20

# Look for form feeds (0c in hex)
pdftotext "/path/to/file.pdf" - | grep -P '\f' | wc -l
```

### Plugin Not Loading
- Check yazi.toml syntax
- Verify plugin directory structure
- Look for lua errors in yazi logs

## File Manager Settings

### Key Settings in yazi.toml:
```toml
[mgr]
ratio = [ 1, 3, 4 ]       # Sidebar, main, preview widths
sort_by = "mtime"         # Sort by modification time
sort_reverse = true       # Newest first
linemode = "file_info"    # Show file details

[preview]
wrap = "yes"              # Wrap long lines
tab_size = 2              # Tab display width
```

### Performance Settings:
```toml
[tasks]
micro_workers = 10        # Small task workers
macro_workers = 25        # Large task workers
image_alloc = 536870912   # 512MB for images
```

## Future Enhancements

### Textra OCR Integration
For image-based PDFs, consider adding textra as a simple fallback:
```lua
-- Only when pdftotext completely fails
cmd = "pdftotext 'file.pdf' - || textra 'file.pdf' --outputStdout"
```

**Warning**: Avoid complex quality detection logic - it's proven fragile.

### Additional Document Types
Could add support for:
- RTF files
- ODT files
- PowerPoint files
- Excel files (via CSV conversion)

## Maintenance

### Regular Checks:
1. Test preview functionality with various document types
2. Verify dependencies are up to date
3. Check for new problematic files that break the display
4. Monitor yazi plugin API changes

### When Things Break:
1. **First**: Test with a known-good PDF
2. **Second**: Check the problematic file manually with extraction tools
3. **Third**: Look for control characters or unusual formatting
4. **Last**: Consider reverting to simpler logic

## Backup Strategy

Keep a copy of working configurations:
```bash
# Backup working state
cp -r ~/.config/yazi ~/.config/yazi.backup.$(date +%Y%m%d)

# Restore if needed
cp -r ~/.config/yazi.backup.YYYYMMDD ~/.config/yazi
```

This configuration has been battle-tested with various document types including problematic PDFs from academic archives.