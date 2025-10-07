# Zellij Auto Tab Name Setup Guide

## ✅ Plugin Installation Complete

Your plugin has been successfully compiled and configured! The plugin will automatically:
- Listen for terminal title changes (OSC sequences)
- Update tab names based on the current command or directory
- Work with Fish shell hooks that are already configured

## 🔐 First-Time Permission Setup

**IMPORTANT**: When you first start Zellij, you'll see a permission prompt like this:

```
This plugin asks permission to: ReadApplicationState, ChangeApplicationState. Allow? (y/n)
```

**To enable automatic tab naming, you MUST press `y` and then Enter.**

This is a one-time setup - Zellij will remember your choice for future sessions.

## 🚀 Testing the Setup

1. **Start Zellij**:
   ```bash
   zellij
   ```

2. **Grant Permissions** (when prompted):
   - You'll see the permission dialog
   - Press `y` and then `Enter` to allow

3. **Test Dynamic Naming**:
   ```bash
   # Tab should show "> ls" 
   ls
   
   # Tab should show "> htop"
   htop
   
   # Tab should show "> vim"
   vim some-file.txt
   
   # After command exits, tab should show directory name
   # (e.g., "zellij-auto-tabname" for current directory)
   ```

## 🔧 How It Works

1. **Fish Shell Hooks**: Automatically set terminal titles using OSC sequences
   - `fish_preexec`: Sets title to command name when you run a command
   - `fish_postexec`: Sets title back to directory name when command finishes

2. **Zellij Plugin**: Listens for pane title changes and updates tab names accordingly
   - Prefixes command names with `> ` (e.g., `> vim`)
   - Shows directory name when no command is running

3. **Built-in Tab Bar**: The familiar Zellij tab bar at the top shows the dynamic names

## 🛠️ Troubleshooting

**Plugin not working?**
- Make sure you granted permissions when prompted
- Restart Zellij if needed: `zellij kill-all-sessions && zellij`
- Check that you're using Fish shell (the hooks only work in Fish)

**No permission prompt?**
- The plugin might already be trusted
- Try running a command and see if the tab name changes

**Tab names not updating?**
- The Fish hooks only work in Fish shell
- Make sure you're in a Zellij session (not just a regular terminal)
- Try running: `printf "\033]0;test title\007"` to manually test

## 📝 Notes

- This setup integrates with your existing home-manager configuration
- The plugin binary is located at: `~/.config/zellij/plugins/auto-tabname.wasm`
- Fish shell hooks are automatically loaded when Fish starts in Zellij
- Works with all Zellij layouts and sessions

Enjoy your dynamic tab names! 🎉