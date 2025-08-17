# Museum Display Nix Deployment Guide

**Date**: August 17, 2025  
**Target**: Raspberry Pi 5 Museum Display  
**Configuration**: Enhanced rpi-museum.nix with production launcher  

## 🚀 Deployment Overview

The enhanced Nix configuration provides:
- ✅ **Production launcher** as a proper Nix derivation
- ✅ **Complete Sway setup** with display rotation and touch calibration
- ✅ **Automated startup** via systemd user service
- ✅ **Touch calibration** via udev rules template
- ✅ **Comprehensive documentation** and troubleshooting guides

## 📋 Deployment Steps

### 1. Deploy to Raspberry Pi

```bash
# From your Mac (this directory)
home-manager switch --flake .#rpi-museum
```

**What this does:**
- Installs all required packages (Sway, Chromium, etc.)
- Creates the production launcher script
- Configures Sway with proper display rotation (90°)
- Sets up input handling for touch calibration
- Creates systemd service for auto-start
- Generates documentation and setup files

### 2. Manual System-Level Setup (One-time)

Since some configurations require root access, these need manual setup:

```bash
# On the Raspberry Pi
ssh pimuseum

# Install touch calibration udev rule
sudo cp ~/.config/museum-display/99-goodix-touchscreen.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger

# Verify touch calibration
libinput list-devices | grep -A 15 "Goodix"
# Should show: Calibration: -1.00 0.00 1.00 0.00 -1.00 1.00
```

### 3. Enable Auto-Start Service

```bash
# Enable museum display service
systemctl --user enable museum-display.service

# Start immediately (optional)
systemctl --user start museum-display.service

# Check status
systemctl --user status museum-display.service
```

### 4. Test Manual Launch

```bash
# Test the launcher directly
~/launch-museum-display.sh

# Check logs
tail -f /tmp/museum-display-$(date +%Y%m%d).log
```

## 🔧 Configuration Details

### Enhanced Features

**Production Launcher (`museum-display-launcher`):**
- Complete production-ready script as Nix derivation
- Pre-flight dependency checks
- Enhanced error handling and retry logic
- Comprehensive logging with timestamps
- Graceful cleanup and signal handling
- Dynamic socket detection
- Window validation and health checks

**Sway Configuration:**
- **Display**: DSI-2 with 90° rotation (800x1280 → 1280x800)
- **Touch Input**: Mapped to DSI-2 with calibration support
- **Window Management**: Optimized for dual Chrome layout
- **Auto-start**: Museum display launches 5 seconds after Sway starts
- **Clean UI**: No borders, gaps, or unnecessary elements

**System Integration:**
- **Systemd Service**: Auto-restart on failure, proper environment
- **Kanshi Profiles**: Display management for reliable setup
- **Touch Calibration**: Udev rules for persistent calibration
- **Documentation**: Complete setup and troubleshooting guides

### Key Files Created

```
~/.config/museum-display/
├── README.md                          # Complete documentation
└── 99-goodix-touchscreen.rules        # Touch calibration udev rule

~/launch-museum-display.sh             # Production launcher (symlink)

~/.config/sway/config                  # Sway configuration (managed by Nix)

~/.config/systemd/user/
└── museum-display.service             # Auto-start service
```

## 🧪 Testing & Validation

### Quick Validation Checklist

```bash
# 1. Check Nix deployment
home-manager generations

# 2. Verify launcher exists and is executable
ls -la ~/launch-museum-display.sh

# 3. Test Sway configuration
swaymsg -t get_version
swaymsg -t get_outputs

# 4. Check touch calibration
libinput list-devices | grep -A 10 Goodix

# 5. Test launcher
~/launch-museum-display.sh
```

### Expected Results

**Sway Display Output:**
```json
{
  "name": "DSI-2",
  "make": "Unknown",
  "model": "Unknown",
  "transform": "90",
  "current_mode": {
    "width": 800,
    "height": 1280,
    "refresh": 60000
  }
}
```

**Touch Calibration:**
```
Device: Goodix Capacitive TouchScreen
Calibration: -1.00 0.00 1.00 0.00 -1.00 1.00
```

**Launcher Success:**
```
[15:30:15] 🏛️  Starting Museum Display System (Production Mode)...
[SUCCESS] All dependencies available
[SUCCESS] Sway IPC connection verified
[SUCCESS] ✅ Museum Display System Fully Operational!
[SUCCESS] 🎯 System ready for museum visitors!
```

## 🏗️ Architecture

### Nix Configuration Structure

```nix
rpi-museum.nix
├── museum-display-launcher      # Production script derivation
├── packages                     # Sway, Chromium, tools
├── wayland.windowManager.sway   # Display & input configuration
├── services.kanshi              # Display management
├── systemd.user.services        # Auto-start service
└── home.file                    # Documentation & udev rules
```

### Runtime Architecture

```
┌─────────────────────────────────────────────┐
│ Raspberry Pi 5 Museum Display System       │
├─────────────────────────────────────────────┤
│ DSI Touchscreen (800x1280)                 │
│ ↓ [90° rotation]                           │
│ Landscape Display (1280x800)               │
│ ↓ [Sway window manager]                    │
│ Dual Chrome Windows (640x800 each)         │
│ ↓ [Touch input: -1 0 1 0 -1 1]            │
│ Accurate Touch Coordinate Mapping          │
└─────────────────────────────────────────────┘
```

## 🚨 Troubleshooting

### Common Issues

**Touch not working:**
```bash
# Check udev rule installation
ls -la /etc/udev/rules.d/99-goodix*
# Reinstall if missing
sudo cp ~/.config/museum-display/99-goodix-touchscreen.rules /etc/udev/rules.d/
```

**Launcher not starting:**
```bash
# Check systemd service
systemctl --user status museum-display.service
journalctl --user -u museum-display.service

# Test manual launch
~/launch-museum-display.sh
```

**Display issues:**
```bash
# Check Sway configuration
swaymsg -t get_outputs
# Reload Sway config
swaymsg reload
```

### Recovery Commands

```bash
# Reset everything
systemctl --user stop museum-display.service
pkill -f chromium
swaymsg exit
# Restart Sway session
```

## 🎯 Production Deployment

### Final Deployment Commands

```bash
# 1. Deploy Nix configuration
home-manager switch --flake .#rpi-museum

# 2. Install system-level components
ssh pimuseum "
  sudo cp ~/.config/museum-display/99-goodix-touchscreen.rules /etc/udev/rules.d/
  sudo udevadm control --reload-rules
  sudo udevadm trigger
"

# 3. Enable auto-start
ssh pimuseum "
  systemctl --user enable museum-display.service
  systemctl --user start museum-display.service
"

# 4. Verify deployment
ssh pimuseum "~/launch-museum-display.sh"
```

## ✅ Success Criteria

- [ ] Nix configuration deploys without errors
- [ ] Launcher script exists and is executable
- [ ] Touch calibration is properly configured
- [ ] Sway displays proper output configuration
- [ ] Museum display launches successfully
- [ ] Dual Chrome windows display in 50:50 layout
- [ ] Touch input works accurately across entire screen
- [ ] Auto-start service is enabled and functional

**🏛️ The museum display system is now fully provisioned via Nix! ✨**