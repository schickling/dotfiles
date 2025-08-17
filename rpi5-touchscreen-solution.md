# Raspberry Pi 5 DSI Touchscreen Coordinate Fix - Complete Solution

## Root Cause Analysis

Based on research and common patterns, your issue stems from:

1. **Coordinate System Mismatch**: The DSI touchscreen reports coordinates in its native 800x1280 portrait orientation
2. **Missing Input Transformation**: When you rotate the display 90° to 1280x800 landscape via `wlr-randr --transform 90`, the touch input coordinates aren't automatically transformed to match
3. **Sway/Wayland Input Pipeline**: Unlike X11, Wayland requires explicit calibration matrix configuration through libinput

## Immediate Solution Steps

### Step 1: Identify Your Touch Device

On your Raspberry Pi 5, run:
```bash
# Find touch device details
libinput list-devices | grep -A 15 -i touch

# Alternative method
cat /proc/bus/input/devices | grep -A 10 -B 5 -i touch
```

Look for output like:
```
Device:           Raspberry Pi Foundation Touchscreen
Kernel:           /dev/input/event1
Group:            2
Seat:             seat0, default
Capabilities:     touch
```

### Step 2: Configure Sway Input (Primary Fix)

Add this to your `~/.config/sway/config`:

```bash
# For 90-degree clockwise rotation (portrait 800x1280 → landscape 1280x800)
input "type:touch" {
    map_to_output DSI-1
    calibration_matrix 0 -1 1 1 0 0
}

# If you know the specific device name, use it instead:
# input "Raspberry Pi Foundation Touchscreen" {
#     map_to_output DSI-1
#     calibration_matrix 0 -1 1 1 0 0
# }
```

Then reload Sway:
```bash
swaymsg reload
```

### Step 3: Alternative libinput Configuration (If Step 2 doesn't work)

Create a udev rule for system-wide touch calibration:

```bash
# Create udev rule
sudo nano /etc/udev/rules.d/99-touchscreen-calibration.rules

# Add this content (adjust device name as needed):
SUBSYSTEM=="input", ATTRS{name}=="Raspberry Pi Foundation Touchscreen", ENV{LIBINPUT_CALIBRATION_MATRIX}="0 -1 1 1 0 0"
```

Reload udev rules:
```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
# May need to reboot for full effect
```

## Calibration Matrix Explanation

For your specific case (90° clockwise rotation):
- **Matrix: `0 -1 1 1 0 0`**
- This transforms coordinates from portrait (800x1280) to landscape (1280x800)

**Matrix format**: `[a b c d e f]` where:
- `a, b, d, e`: Scaling and rotation coefficients  
- `c, f`: Translation offsets

**Other rotation matrices** (if needed):
- No rotation: `1 0 0 0 1 0`
- 180°: `-1 0 1 0 -1 1`  
- 270°: `0 1 0 -1 0 1`

## Testing and Verification

### Create Touch Test Page

```bash
# Create test file
cat > ~/touch-test.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Touch Calibration Test</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: Arial, sans-serif; 
            background: #f0f0f0;
            overflow: hidden;
        }
        .test-area {
            width: 100vw;
            height: 100vh;
            position: relative;
            background: linear-gradient(45deg, #e0e0e0, #f0f0f0);
        }
        .corner-btn {
            position: absolute;
            width: 120px;
            height: 120px;
            background: #4CAF50;
            border: 3px solid #45a049;
            color: white;
            font-size: 16px;
            font-weight: bold;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 10px;
            transition: all 0.2s;
        }
        .corner-btn:hover { background: #45a049; transform: scale(1.1); }
        .corner-btn.active { background: #ff4444; }
        
        .top-left { top: 10px; left: 10px; }
        .top-right { top: 10px; right: 10px; }
        .bottom-left { bottom: 10px; left: 10px; }
        .bottom-right { bottom: 10px; right: 10px; }
        .center { 
            top: 50%; left: 50%; 
            transform: translate(-50%, -50%);
            width: 150px; height: 150px;
            border-radius: 50%;
        }
        
        .edge-test {
            position: absolute;
            width: 60px;
            height: 60px;
            background: #2196F3;
            border: 2px solid #1976D2;
            color: white;
            font-size: 12px;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .edge-top { top: 0; left: 50%; transform: translateX(-50%); }
        .edge-bottom { bottom: 0; left: 50%; transform: translateX(-50%); }
        .edge-left { left: 0; top: 50%; transform: translateY(-50%); }
        .edge-right { right: 0; top: 50%; transform: translateY(-50%); }
        
        .status {
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: rgba(0,0,0,0.8);
            color: white;
            padding: 20px;
            border-radius: 10px;
            font-size: 18px;
            display: none;
        }
    </style>
</head>
<body>
    <div class="test-area">
        <div class="corner-btn top-left" onclick="testTouch('TOP LEFT')">TOP<br>LEFT</div>
        <div class="corner-btn top-right" onclick="testTouch('TOP RIGHT')">TOP<br>RIGHT</div>
        <div class="corner-btn bottom-left" onclick="testTouch('BOTTOM LEFT')">BOTTOM<br>LEFT</div>
        <div class="corner-btn bottom-right" onclick="testTouch('BOTTOM RIGHT')">BOTTOM<br>RIGHT</div>
        <div class="corner-btn center" onclick="testTouch('CENTER')">CENTER</div>
        
        <div class="edge-test edge-top" onclick="testTouch('TOP EDGE')">TOP</div>
        <div class="edge-test edge-bottom" onclick="testTouch('BOTTOM EDGE')">BOT</div>
        <div class="edge-test edge-left" onclick="testTouch('LEFT EDGE')">L</div>
        <div class="edge-test edge-right" onclick="testTouch('RIGHT EDGE')">R</div>
    </div>
    
    <div class="status" id="status">Touch detected!</div>
    
    <script>
        function testTouch(location) {
            const status = document.getElementById('status');
            status.textContent = `✓ ${location} - Touch Working!`;
            status.style.display = 'block';
            
            // Flash the clicked element
            event.target.classList.add('active');
            setTimeout(() => {
                event.target.classList.remove('active');
            }, 200);
            
            setTimeout(() => {
                status.style.display = 'none';
            }, 1500);
        }
        
        // Track touch coordinates
        document.addEventListener('touchstart', function(e) {
            const touch = e.touches[0];
            console.log(`Touch at: ${touch.clientX}, ${touch.clientY}`);
        });
    </script>
</body>
</html>
EOF

# Open in Chromium for testing
chromium-browser --kiosk ~/touch-test.html
```

### Debugging Commands

```bash
# Monitor touch events in real-time
sudo libinput debug-events --device /dev/input/event1  # Adjust event number

# Check current input configuration
swaymsg -t get_inputs | jq '.[] | select(.type == "touch")'

# Verify display output configuration  
swaymsg -t get_outputs | jq '.[] | {name, rect, transform}'

# Test raw input events
sudo evtest /dev/input/event1  # Adjust event number
```

## Troubleshooting Common Issues

### Issue 1: Touch still misaligned
**Solutions**:
1. Try different calibration matrix values:
   - For counter-clockwise 90°: `0 1 0 -1 0 1`
   - For fine-tuning: Adjust the matrix values slightly

2. Check if multiple input configurations conflict:
   ```bash
   grep -r "calibration_matrix\|map_to_output" ~/.config/sway/
   ```

### Issue 2: Touch device not found
**Solutions**:
1. Check if touchscreen driver is loaded:
   ```bash
   dmesg | grep -i touch
   lsmod | grep touch
   ```

2. Verify device permissions:
   ```bash
   ls -la /dev/input/event*
   groups $USER  # Should include 'input' group
   ```

### Issue 3: Configuration doesn't persist
**Solutions**:
1. Ensure Sway config is properly saved and reloaded
2. Use udev rules method for system-wide persistence
3. Add configuration reload to startup scripts

### Issue 4: Partial touch response
**Solutions**:
1. Check for power management interference:
   ```bash
   cat /sys/class/input/input*/power/control
   # Set to 'on' if showing 'auto'
   echo 'on' | sudo tee /sys/class/input/input*/power/control
   ```

## Final Validation Checklist

- [ ] Corner taps register at correct locations
- [ ] Edge taps work properly (not ignored)
- [ ] Center tap works accurately  
- [ ] Multi-touch gestures work (if supported)
- [ ] Configuration persists after reboot
- [ ] Both Chromium windows respond correctly to touch
- [ ] No phantom touches or ghost cursors

## Optimized Sway Configuration

Complete input section for your `~/.config/sway/config`:

```bash
# Input configuration for DSI touchscreen
input "type:touch" {
    # Map to the DSI output
    map_to_output DSI-1
    
    # Transform coordinates for 90° rotation
    calibration_matrix 0 -1 1 1 0 0
    
    # Optional: Enable tap and gestures if supported
    tap enabled
    natural_scroll disabled
}

# Ensure display is properly configured
output DSI-1 {
    resolution 1280x800
    transform 90
}
```

This solution should resolve your touch coordinate misalignment issue by properly transforming the touch input to match your rotated display orientation.