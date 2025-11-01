# Yazi & Zsh Fixes - README

## What Was Fixed

### 1. Zsh Autocomplete (FIXED ✅)
**Problem**: Grey autocomplete suggestions weren't appearing
**Cause**: Broken nix/home-manager symlinks pointing to non-existent paths
**Solution**: Removed broken symlinks and installed fresh copies of:
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`

**To test**: Open a new zsh session with `exec zsh` and start typing a command

### 2. Yazi Preview for Documents (FIXED ✅)
**Problem**: Document previews not working
**Cause**: Missing `w3m` tool for HTML previews
**Solution**: Installed `w3m` via apt

**To test**: Open yazi and navigate to an HTML file

### 3. Yazi Zoxide Integration (TROUBLESHOOTING NEEDED ⚠️)
**Problem**: Pressing `z` in yazi shows "zoxide exited with code 1" and screen scrambles
**What it should do**: Show an fzf-style dropdown to select from frequently visited directories

**How yazi's zoxide works**:
- Built-in plugin (no need to install separately)
- Runs `zoxide query -i --exclude <current_dir>` which uses fzf for interactive selection
- Requires both `zoxide` and `fzf` to be installed (both are ✅)
- Requires zoxide to have at least 2+ directories in its database (besides current directory)

**Current status**:
- ✅ zoxide installed and working: `/usr/bin/zoxide`
- ✅ fzf installed and working: `/usr/bin/fzf`
- ✅ zoxide has database with entries (checked with `zoxide query --list`)
- ✅ Yazi init.lua has `require("zoxide"):setup({ update_db = true })`
- ✅ Keymap has `z` bound to `plugin zoxide`

**Potential causes of "exit code 1"**:

1. **Not enough non-excluded directories** (MOST LIKELY ⭐)
   - Zoxide query excludes the current directory with `--exclude`
   - If you only have 1-2 directories in zoxide and you're in one of them, there are no results
   - **Solution**: Build up your zoxide database:
     ```bash
     # Navigate to multiple directories
     cd ~/projects && cd ~/Downloads && cd ~/.config && cd /tmp
     # Check database
     zoxide query --list
     ```
   - Need at least 3-4 directories for reliable results

2. **FZF configuration conflicts**
   - Some FZF options might conflict with yazi's terminal state
   - **Solution**: Try setting `YAZI_ZOXIDE_OPTS`:
     ```bash
     export YAZI_ZOXIDE_OPTS="--height=80% --layout=reverse --border"
     ```

3. **Terminal/TTY issues causing screen scramble**
   - The fzf interface might be conflicting with yazi's UI
   - **Debugging**: Check yazi logs with `YAZI_LOG=debug yazi`

**To test**:
1. Make sure you have multiple directories in zoxide:
   ```bash
   zoxide query --list
   ```
   Should show at least 2-3 directories. If empty, navigate to some directories first:
   ```bash
   cd ~/projects
   cd ~/Downloads
   cd ~/.config
   ```

2. Open yazi and press `z`
3. You should see an fzf dropdown like this:
   ```
   > /home/user/projects
     /home/user/.config
     /home/user/Downloads
   ```

4. If it still shows "zoxide exited with code 1", check yazi's error log or try running manually:
   ```bash
   zoxide query -i --exclude $(pwd)
   ```

## Files Changed

- `.config/yazi/package.toml`: Added zoxide, fzf, smart-open plugins
- `.config/yazi/plugins/`: Added smart-enter.yazi and smart-filter.yazi
- `setup-nosudocheck.sh`: New setup script
- `~/.zsh/plugins/`: Fresh install of zsh-autosuggestions and zsh-syntax-highlighting

## To Push Changes

The commit is ready but git push failed due to broken credential helper. To push manually:

```bash
cd ~/tmp-dotfiles
git push origin master
```

You may need to authenticate with GitHub.

## Next Steps

1. **Test zsh autocomplete**: `exec zsh` then type a command
2. **Test yazi zoxide**: Open `yazi`, navigate around a bit, then press `z`
3. If zoxide still doesn't work, we may need to:
   - Check yazi logs for more detailed error messages
   - Test if the fzf dropdown works outside of yazi
   - Add YAZI_LOG=debug environment variable and check logs
