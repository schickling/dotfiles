# Pi Museum Display Recovery Guide

## Quick Recovery Commands

### SSH Access
```bash
ssh pimuseum  # should work if Tailscale is running
# or
ssh 192.168.1.178
```

### Display Issues - Switch Back to Wayfire
If display is black or Sway isn't working:

```bash
# 1. Revert to original Wayfire setup
ssh pimuseum "sudo sed -i 's/autologin-session=sway/autologin-session=LXDE-pi-wayfire/' /etc/lightdm/lightdm.conf"
ssh pimuseum "sudo sed -i 's/user-session=sway/user-session=LXDE-pi-wayfire/' /etc/lightdm/lightdm.conf"
ssh pimuseum "sudo systemctl restart lightdm"

# 2. Wait 10 seconds then test
sleep 10 && ssh pimuseum "ps aux | grep wayfire"
```

### Display Rotation (if needed)
```bash
# Check current rotation
ssh pimuseum "sudo su - pi -c 'wlr-randr --output DSI-2 --transform 90'"

# Or manually edit wayfire config
ssh pimuseum "sudo su - pi -c 'cat ~/.config/wayfire/wayfire.ini'"
```

### Kill Problematic Processes
```bash
# Kill all Chrome processes
ssh pimuseum "sudo pkill -f chromium"

# Kill Sway (if stuck)
ssh pimuseum "sudo pkill -f sway"

# Restart display manager
ssh pimuseum "sudo systemctl restart lightdm"
```

### Emergency Reboot
```bash
ssh pimuseum "sudo reboot"
```

## Configuration File Locations

### Lightdm Config
```bash
/etc/lightdm/lightdm.conf
```
Key lines:
- `user-session=LXDE-pi-wayfire` (original)
- `autologin-session=LXDE-pi-wayfire` (original)

### Wayfire Config
```bash
/home/pi/.config/wayfire/wayfire.ini
```

### Sway Config (if created)
```bash
/home/pi/.config/sway/config
```

### Scripts
```bash
/home/pi/Desktop/dual-chrome-windows.sh  # Original Wayfire script
/home/pi/dual-chrome-sway-fixed.sh      # Sway script
```

## Current State Before Changes
- **Window Manager**: Wayfire 
- **Display**: 1280x800 landscape (90° rotation)
- **Session**: LXDE-pi-wayfire
- **User**: pi (autologin enabled)

## Working Original Setup Commands
```bash
# Original landscape rotation that worked
ssh pimuseum "sudo su - pi -c 'wlr-randr --output DSI-2 --transform 90'"

# Original dual Chrome script (overlapping windows issue)
ssh pimuseum "sudo su - pi -c '/home/pi/Desktop/dual-chrome-windows.sh'"
```

## Troubleshooting Steps

1. **Check if SSH works**: `ssh pimuseum "whoami"`
2. **Check which WM is running**: `ssh pimuseum "ps aux | grep -E 'sway|wayfire'"`
3. **Check display rotation**: Take photo or SSH screenshot
4. **Revert to last working state**: Use Wayfire commands above
5. **Nuclear option**: `sudo reboot`

## Current Issue to Solve
- Sway is running correctly (✅ confirmed)
- Display shows Sway wallpaper (✅ confirmed) 
- Chrome/applications not appearing as windows
- Need to verify window management works before dual window script

## Next Steps After Recovery
1. Test simple application (foot terminal) in Sway
2. Test single Chrome window visibility  
3. Then work on dual window positioning

---
*Created: 2025-08-13*
*Status: Sway installed but applications not visible*