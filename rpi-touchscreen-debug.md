# Raspberry Pi 5 DSI Touchscreen Debug Guide

## System Information Collection

Run these commands on your Raspberry Pi to gather system information:

### 1. Display Configuration
```bash
# Check current display setup
wlr-randr
swaymsg -t get_outputs

# Check physical display properties
cat /sys/class/drm/card*/card*/modes
ls -la /dev/dri/
```

### 2. Touch Input Device Identification
```bash
# List all input devices
libinput list-devices

# Check touch-specific devices
ls -la /dev/input/
cat /proc/bus/input/devices | grep -A 10 -B 5 touch

# Check udev rules for touch devices
ls -la /etc/udev/rules.d/ | grep touch
```

### 3. Current Input Configuration
```bash
# Check current Sway configuration
cat ~/.config/sway/config | grep -i input
swaymsg -t get_inputs

# Check libinput configuration
libinput list-devices | grep -A 20 "Device:"
```

## Root Cause Analysis

Based on the symptoms (touch hit areas don't match visual elements with 90-degree rotation), the most likely causes are:

### 1. **Coordinate System Mismatch**
- Physical touchscreen reports coordinates in portrait orientation (800x1280)
- Display is rotated to landscape (1280x800) via `wlr-randr --transform 90`
- Touch input isn't being transformed to match the rotated display

### 2. **Input Device Mapping Issues**
- Touch device may not be properly mapped to the rotated output
- Calibration matrix may not account for rotation

### 3. **Sway Input Configuration Missing**
- Touch device may need explicit input configuration in Sway

## Diagnostic Commands

### Check Touch Event Flow
```bash
# Monitor raw touch events
sudo libinput debug-events --device /dev/input/eventX  # Replace X with touch device number

# Test touch accuracy with visual feedback
# Install if needed: sudo apt install xinput-calibrator (for testing)
```

### Verify Display Transformation
```bash
# Check if transformation is applied correctly
wlr-randr --output DSI-1 --transform 90  # Adjust output name as needed

# Check current transformation matrix
swaymsg -t get_outputs | jq '.[].transform'
```

## Solution Steps

### Step 1: Identify Touch Device
```bash
# Find your touch device name/path
libinput list-devices | grep -A 10 -B 2 -i touch
```

### Step 2: Configure Touch Input in Sway

Add to your `~/.config/sway/config`:

```bash
# Replace "Your Touch Device Name" with actual device name from libinput list-devices
input "type:touch" {
    map_to_output DSI-1  # Replace with your actual output name
    # Alternative: map_to_region 0 0 1280 800
}

# For specific touch device (more precise):
input "1234:5678:TouchDevice" {  # Replace with actual vendor:product:name
    map_to_output DSI-1
}
```

### Step 3: Apply Coordinate Transformation

If mapping to output doesn't work, try explicit transformation matrix:

```bash
# Add to sway config - this transforms touch coordinates for 90° rotation
input "type:touch" {
    calibration_matrix 0 1 0 -1 0 1
}
```

### Step 4: Alternative libinput Configuration

Create `/etc/libinput/local-overrides.quirks`:

```ini
[Touchscreen Rotation Fix]
MatchName=*YourTouchDeviceName*
AttrInputProp=WL_CALIBRATION_MATRIX=0 1 0 -1 0 1
```

## Testing Methodology

### 1. Touch Accuracy Test
```bash
# Create a simple test
cat > ~/touch_test.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <style>
        body { margin: 0; font-size: 20px; }
        .corner { 
            position: absolute; 
            width: 100px; 
            height: 100px; 
            background: red; 
            color: white; 
            text-align: center; 
            line-height: 100px;
        }
        .tl { top: 0; left: 0; }
        .tr { top: 0; right: 0; }
        .bl { bottom: 0; left: 0; }
        .br { bottom: 0; right: 0; }
        .center { 
            top: 50%; 
            left: 50%; 
            transform: translate(-50%, -50%);
        }
    </style>
</head>
<body>
    <div class="corner tl" onclick="alert('Top Left')">TL</div>
    <div class="corner tr" onclick="alert('Top Right')">TR</div>
    <div class="corner bl" onclick="alert('Bottom Left')">BL</div>
    <div class="corner br" onclick="alert('Bottom Right')">BR</div>
    <div class="corner center" onclick="alert('Center')">C</div>
</body>
</html>
EOF

# Open in Chromium to test
chromium-browser ~/touch_test.html
```

### 2. Coordinate Mapping Verification
```bash
# Monitor touch events while testing
sudo libinput debug-events | grep TOUCH_DOWN
```

## Advanced Debugging

### Check Kernel Touch Driver
```bash
# Check if touch driver is loaded correctly
dmesg | grep -i touch
lsmod | grep touch

# Check device tree for touch configuration
ls -la /boot/overlays/ | grep touch
```

### Monitor Input Pipeline
```bash
# Install debugging tools if needed
sudo apt install input-utils evtest

# Test raw input events
sudo evtest /dev/input/eventX  # Replace X with touch device number
```

## Expected Transformation Matrix Values

For 90-degree clockwise rotation (portrait 800x1280 to landscape 1280x800):
- Matrix: `0 1 0 -1 0 1`

For other rotations:
- 180°: `-1 0 1 0 -1 1`
- 270°: `0 -1 1 1 0 0`
- No rotation: `1 0 0 0 1 0`

## Common Issues and Fixes

### Issue: Touch works but coordinates are wrong
**Fix**: Apply correct transformation matrix in Sway config

### Issue: Touch device not detected
**Fix**: Check device tree overlay, ensure DSI touchscreen driver is loaded

### Issue: Touch events received but no response
**Fix**: Check input device permissions, ensure user is in input group

### Issue: Intermittent touch response
**Fix**: Check power management settings, disable touch device power saving

## Verification Steps

1. **Test corner taps**: Touch should register exactly where you tap
2. **Test edge cases**: Touch near bezels should work correctly
3. **Test multi-touch**: If supported, multiple fingers should work
4. **Test after reboot**: Configuration should persist

## Final Configuration Example

Complete Sway configuration section for touch:

```bash
# In ~/.config/sway/config
input "type:touch" {
    # Map touch to specific output
    map_to_output DSI-1
    
    # If above doesn't work, try transformation matrix
    # calibration_matrix 0 1 0 -1 0 1
    
    # Additional touch settings
    tap enabled
    natural_scroll disabled
}

# Reload Sway configuration
# swaymsg reload
```

Run these diagnostics and apply the solutions step by step. The most likely fix is adding the proper input configuration to your Sway config with either `map_to_output` or the correct `calibration_matrix` for the 90-degree rotation.