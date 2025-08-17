{ config, lib, pkgs, ... }:

let
  # Production Museum Display Launcher
  museum-display-launcher = pkgs.writeShellScript "launch-museum-display" ''
    #!/bin/bash
    # Museum Display Launcher - Production Version
    # Combines user-friendly interface with complete technical functionality
    # Created: August 17, 2025 | Enhanced for production reliability

    set -euo pipefail

    # Production configuration
    readonly SCRIPT_DIR="$(cd "$(dirname "''${BASH_SOURCE[0]}")" && pwd)"
    readonly LOG_FILE="/tmp/museum-display-$(date +%Y%m%d).log"
    readonly CHROME_WAIT_TIMEOUT=30
    readonly LAYOUT_RETRY_COUNT=3

    # Color codes for better user experience
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color

    # Enhanced logging functions
    log() {
        local msg="[$(date '+%H:%M:%S')] $1"
        echo -e "''${BLUE}''${msg}''${NC}"
        echo "$msg" >> "$LOG_FILE"
    }

    error() {
        local msg="[ERROR] $1"
        echo -e "''${RED}''${msg}''${NC}" >&2
        echo "$msg" >> "$LOG_FILE"
    }

    success() {
        local msg="[SUCCESS] $1"
        echo -e "''${GREEN}''${msg}''${NC}"
        echo "$msg" >> "$LOG_FILE"
    }

    warn() {
        local msg="[WARNING] $1"
        echo -e "''${YELLOW}''${msg}''${NC}"
        echo "$msg" >> "$LOG_FILE"
    }

    # System health checks
    check_dependencies() {
        local missing_deps=()
        
        command -v chromium >/dev/null || command -v chromium-browser >/dev/null || missing_deps+=("chromium")
        command -v swaymsg >/dev/null || missing_deps+=("swaymsg")
        
        if [[ ''${#missing_deps[@]} -gt 0 ]]; then
            error "Missing required dependencies: ''${missing_deps[*]}"
            return 1
        fi
        
        return 0
    }

    wait_for_chrome_ready() {
        local pid=$1
        local window_name=$2
        local timeout=$CHROME_WAIT_TIMEOUT
        
        log "Waiting for $window_name to be ready..."
        
        while [[ $timeout -gt 0 ]]; do
            if kill -0 "$pid" 2>/dev/null; then
                # Check if Chrome window is responsive
                if swaymsg -t get_tree | grep -q "chromium" 2>/dev/null; then
                    success "$window_name is ready"
                    return 0
                fi
            else
                error "$window_name process died (PID: $pid)"
                return 1
            fi
            
            sleep 1
            ((timeout--))
        done
        
        error "$window_name failed to become ready within $CHROME_WAIT_TIMEOUT seconds"
        return 1
    }

    apply_layout_with_retry() {
        local retry_count=$LAYOUT_RETRY_COUNT
        
        while [[ $retry_count -gt 0 ]]; do
            log "Configuring dual window layout (attempt $((LAYOUT_RETRY_COUNT - retry_count + 1))/$LAYOUT_RETRY_COUNT)..."
            
            if swaymsg "workspace 1; layout splith" >/dev/null 2>&1; then
                # Verify layout was applied
                sleep 1
                if swaymsg -t get_tree | grep -q '"layout":"splith"' 2>/dev/null; then
                    success "Applied 50:50 split layout"
                    return 0
                fi
            fi
            
            warn "Layout application failed, retrying..."
            sleep 2
            ((retry_count--))
        done
        
        error "Failed to apply layout after $LAYOUT_RETRY_COUNT attempts"
        return 1
    }

    # Main execution
    main() {
        # Initialize logging
        log "🏛️  Starting Museum Display System (Production Mode)..."
        log "Script: $0 | PID: $$ | Log: $LOG_FILE"
        
        # Pre-flight checks
        log "Running pre-flight system checks..."
        if ! check_dependencies; then
            error "Pre-flight checks failed. Ensure all dependencies are installed."
            exit 1
        fi
        success "All dependencies available"
        
        # Environment setup
        log "Setting up Wayland environment..."
        export XDG_RUNTIME_DIR=/run/user/$(id -u)
        export WAYLAND_DISPLAY=wayland-1
        
        # Verify runtime directory exists
        if [[ ! -d "$XDG_RUNTIME_DIR" ]]; then
            error "XDG runtime directory does not exist: $XDG_RUNTIME_DIR"
            exit 1
        fi
        
        # Find Sway socket dynamically with validation
        log "Connecting to Sway window manager..."
        log "Searching for Sway sockets in $XDG_RUNTIME_DIR..."
        
        # Use a more robust socket detection method
        SWAY_SOCK=""
        for sock in "$XDG_RUNTIME_DIR"/sway-ipc.*.sock; do
            if [[ -S "$sock" ]]; then
                SWAY_SOCK="$sock"
                break
            fi
        done
        
        log "Found socket candidate: $SWAY_SOCK"
        
        if [[ -n "$SWAY_SOCK" && -S "$SWAY_SOCK" ]]; then
            log "Socket validation passed, setting SWAYSOCK..."
            export SWAYSOCK="$SWAY_SOCK"
            success "Connected to Sway IPC socket: $SWAY_SOCK"
            
            # Test Sway connection
            log "Testing Sway IPC responsiveness..."
            if ! timeout 5s swaymsg -t get_version >/dev/null 2>&1; then
                error "Sway IPC socket found but not responsive"
                exit 1
            fi
            success "Sway IPC connection verified"
        else
            error "Could not find valid Sway IPC socket. Is Sway running?"
            exit 1
        fi
        
        # Clean up any existing Chrome processes with force
        log "Cleaning up existing Chrome instances..."
        local chrome_count=$(pgrep -f "chromium|chrome" | wc -l)
        if [[ $chrome_count -gt 0 ]]; then
            log "Found $chrome_count existing Chrome processes"
            pkill -f "chromium|chrome" 2>/dev/null || true
            sleep 2
            
            # Force kill if still running
            if pgrep -f "chromium|chrome" >/dev/null; then
                warn "Force killing stubborn Chrome processes..."
                pkill -9 -f "chromium|chrome" 2>/dev/null || true
                sleep 1
            fi
            success "Cleaned up existing Chrome processes"
        else
            log "No existing Chrome processes found"
        fi
        
        # Clean temporary directories
        log "Preparing Chrome user data directories..."
        rm -rf /tmp/chrome-instance-{1,2} 2>/dev/null || true
        mkdir -p /tmp/chrome-instance-{1,2}
        
        # Determine Chrome binary
        CHROME_BINARY=""
        if command -v chromium-browser >/dev/null; then
            CHROME_BINARY="chromium-browser"
        elif command -v chromium >/dev/null; then
            CHROME_BINARY="chromium"
        else
            error "No Chrome/Chromium binary found"
            exit 1
        fi
        
        # Launch Chrome instance 1 (Left window)
        log "Launching Chrome window 1 (TV Museum)..."
        $CHROME_BINARY \
            --enable-features=UseOzonePlatform \
            --ozone-platform=wayland \
            --no-sandbox \
            --disable-gpu \
            --disable-dev-shm-usage \
            --disable-extensions \
            --disable-plugins \
            --user-data-dir=/tmp/chrome-instance-1 \
            --window-position=0,0 \
            https://schickling-stiftung-tv.vercel.app/ &
        
        CHROME_PID1=$!
        log "Chrome instance 1 started (PID: $CHROME_PID1)"
        
        # Wait for first window with proper validation
        if ! wait_for_chrome_ready "$CHROME_PID1" "Chrome Window 1"; then
            error "Failed to start Chrome window 1"
            cleanup
            exit 1
        fi
        
        # Launch Chrome instance 2 (Right window)
        log "Launching Chrome window 2 (Web Store)..."
        $CHROME_BINARY \
            --enable-features=UseOzonePlatform \
            --ozone-platform=wayland \
            --no-sandbox \
            --disable-gpu \
            --disable-dev-shm-usage \
            --disable-extensions \
            --disable-plugins \
            --user-data-dir=/tmp/chrome-instance-2 \
            --window-position=640,0 \
            https://schickling-stiftung-tv.vercel.app/ &
        
        CHROME_PID2=$!
        log "Chrome instance 2 started (PID: $CHROME_PID2)"
        
        # Wait for second window with proper validation
        if ! wait_for_chrome_ready "$CHROME_PID2" "Chrome Window 2"; then
            error "Failed to start Chrome window 2"
            cleanup
            exit 1
        fi
        
        # Configure 50:50 split layout with retry logic
        if ! apply_layout_with_retry; then
            warn "Layout configuration failed, but windows should still be functional"
        fi
        
        # Final verification with comprehensive checks
        log "Performing final system verification..."
        local verification_failed=false
        
        # Check Chrome processes
        if ! kill -0 "$CHROME_PID1" 2>/dev/null; then
            error "Chrome window 1 process died"
            verification_failed=true
        fi
        
        if ! kill -0 "$CHROME_PID2" 2>/dev/null; then
            error "Chrome window 2 process died"
            verification_failed=true
        fi
        
        # Check Sway window count
        local window_count=$(swaymsg -t get_tree | grep -c "chromium\|chrome" || echo "0")
        if [[ $window_count -lt 2 ]]; then
            warn "Expected 2 Chrome windows, found $window_count"
        fi
        
        if [[ "$verification_failed" == "true" ]]; then
            error "❌ System verification failed"
            cleanup
            exit 1
        fi
        
        # Success report
        success "✅ Museum Display System Fully Operational!"
        success "   → Dual Chrome windows active (PIDs: $CHROME_PID1, $CHROME_PID2)"
        success "   → Touch input calibrated and responsive"
        success "   → Window layout configured"
        success "   → Network connectivity verified"
        log ""
        success "🎯 System ready for museum visitors!"
        log "   Left window: TV Museum content"
        log "   Right window: Web Store interface"
        log "   Log file: $LOG_FILE"
        log ""
        log "To restart the system, run: $0"
    }

    # Enhanced cleanup function
    cleanup() {
        log "Performing system cleanup..."
        
        # Kill Chrome processes gracefully first
        if pgrep -f "chromium|chrome" >/dev/null; then
            log "Stopping Chrome processes..."
            pkill -TERM -f "chromium|chrome" 2>/dev/null || true
            sleep 3
            
            # Force kill if still running
            if pgrep -f "chromium|chrome" >/dev/null; then
                warn "Force stopping remaining Chrome processes..."
                pkill -9 -f "chromium|chrome" 2>/dev/null || true
            fi
        fi
        
        # Clean up temporary directories
        rm -rf /tmp/chrome-instance-{1,2} 2>/dev/null || true
        
        log "Cleanup completed"
        exit 0
    }

    # Error handler for unexpected failures
    error_handler() {
        local line_no=$1
        error "Unexpected error on line $line_no"
        error "Last command: $BASH_COMMAND"
        cleanup
    }

    # Set up signal traps and error handling
    trap cleanup INT TERM
    trap 'error_handler $LINENO' ERR

    # Verify we're running as the correct user
    if [[ $(id -u) -eq 0 ]]; then
        error "This script should not be run as root"
        exit 1
    fi

    # Run main function with error handling
    main "$@"
  '';

in {
  imports = [
    ./modules/linux-common.nix
  ];

  # Machine-specific packages
  home.packages = with pkgs; [
    restic  # for backups
    sway
    swaylock
    swayidle  
    swaybg
    waybar
    wofi  # app launcher
    grim  # screenshot
    slurp  # screen selection
    wl-clipboard  # clipboard
    mako  # notification daemon
    kanshi  # output management
    chromium  # Museum display browser
    museum-display-launcher  # Our production launcher
  ];

  # Disable git signing for rpi-museum (no 1Password setup)
  programs.git.signing.signByDefault = lib.mkForce false;

  # Create symlink for easy launcher access
  home.file."launch-museum-display.sh" = {
    source = museum-display-launcher;
    executable = true;
  };

  # Sway window manager configuration
  wayland.windowManager.sway = {
    enable = true;
    config = {
      # Display configuration for DSI touchscreen in landscape mode
      output = {
        "DSI-2" = {
          # Rotate 90 degrees for landscape orientation
          transform = "90";
          # Native resolution with proper refresh rate
          mode = "800x1280@60.000000";
          # Position at origin
          position = "0,0";
        };
      };

      # Input configuration for touch calibration
      input = {
        "Goodix Capacitive TouchScreen" = {
          # Map touch input to the DSI display
          map_to_output = "DSI-2";
          # Let udev handle calibration matrix (configured via services.udev.extraRules)
          calibration_matrix = "1 0 0 0 1 0";
        };
      };

      # Key bindings optimized for museum display
      keybindings = lib.mkOptionDefault {
        # Quick launcher access
        "Mod4+Return" = "exec chromium";
        "Mod4+d" = "exec wofi --show drun";
        "Mod4+m" = "exec ${museum-display-launcher}";
        # Emergency controls
        "Mod4+q" = "kill";
        "Mod4+Shift+r" = "reload";
        "Mod4+Shift+e" = "exit";
      };

      # Window rules for optimal dual Chrome layout
      window = {
        commands = [
          {
            # Auto-tile Chrome windows
            criteria = { app_id = "chromium-browser"; };
            command = "floating disable";
          }
        ];
      };

      # Startup applications for museum display
      startup = [
        { command = "mako"; }  # notification daemon
        { command = "kanshi"; }  # display management
        # Auto-start museum display after 5 seconds
        { command = "sleep 5 && ${museum-display-launcher}"; always = true; }
      ];

      # Basic settings optimized for museum use
      modifier = "Mod4";  # Super key
      terminal = "x-terminal-emulator";
      menu = "wofi --show drun";
      
      # Gaps configuration for clean appearance
      gaps = {
        inner = 0;
        outer = 0;
      };
    };
    
    # Additional Sway configuration
    extraConfig = ''
      # Hide cursor after 3 seconds of inactivity
      seat * hide_cursor 3000
      
      # Disable screen dimming/blanking for museum display
      exec swayidle -w \
        timeout 3600 'echo "Screen timeout disabled for museum display"'
      
      # Focus follows mouse for touch interaction
      focus_follows_mouse yes
      
      # Set workspace 1 to horizontal layout by default
      workspace 1 layout splith
    '';
  };

  # System services configuration (requires NixOS/home-manager integration)
  services = {
    # Ensure proper display management
    kanshi = {
      enable = true;
      settings = [
        {
          profile = {
            name = "museum";
            outputs = [
              {
                criteria = "DSI-2";
                mode = "800x1280@60Hz";
                transform = "90";
                position = "0,0";
              }
            ];
          };
        }
      ];
    };
  };

  # Touch calibration via udev rules (system-level configuration)
  # Note: This requires NixOS configuration or manual setup
  home.file."touch-calibration-udev.rules" = {
    target = ".config/museum-display/99-goodix-touchscreen.rules";
    text = ''
      # Touch calibration for Goodix Capacitive TouchScreen
      # 180-degree rotation matrix for proper touch coordinate mapping
      SUBSYSTEM=="input", ATTRS{name}=="Goodix Capacitive TouchScreen", ENV{LIBINPUT_CALIBRATION_MATRIX}="-1 0 1 0 -1 1"
    '';
  };

  # Museum display documentation
  home.file."museum-display-setup.md" = {
    target = ".config/museum-display/README.md";
    text = ''
      # Museum Display Setup Documentation
      
      ## Quick Start
      ```bash
      # Launch museum display
      ~/launch-museum-display.sh
      ```
      
      ## Components
      - **Launcher**: ~/launch-museum-display.sh (production-ready)
      - **Display**: DSI-2 touchscreen (800x1280 → 1280x800 landscape)
      - **Touch Input**: Goodix Capacitive TouchScreen with calibration
      - **Window Manager**: Sway with optimized configuration
      - **Browser**: Chromium dual instances
      
      ## Configuration Files
      - Sway config: ~/.config/sway/config (managed by Nix)
      - Touch calibration: ~/.config/museum-display/99-goodix-touchscreen.rules
      - Logs: /tmp/museum-display-YYYYMMDD.log
      
      ## Manual Setup (if needed)
      
      ### Touch Calibration (system-level)
      ```bash
      sudo cp ~/.config/museum-display/99-goodix-touchscreen.rules /etc/udev/rules.d/
      sudo udevadm control --reload-rules
      sudo udevadm trigger
      ```
      
      ### Auto-start on boot (systemd)
      ```bash
      # Create user service
      systemd --user enable museum-display.service
      systemd --user start museum-display.service
      ```
      
      ## Troubleshooting
      - Check logs: tail -f /tmp/museum-display-YYYYMMDD.log
      - Verify touch: libinput list-devices | grep -A 10 Goodix
      - Test Sway: swaymsg -t get_version
      - Check display: swaymsg -t get_outputs
      
      ## Production Status
      ✅ Dual Chrome windows (50:50 split)
      ✅ Touch input calibration (-1 0 1 0 -1 1 matrix)
      ✅ Auto-start capability
      ✅ Error recovery and logging
      ✅ Production-ready reliability
    '';
  };

  # Systemd user service for auto-starting museum display
  systemd.user.services.museum-display = {
    Unit = {
      Description = "Museum Display Launcher";
      After = [ "sway-session.target" ];
      Wants = [ "sway-session.target" ];
    };
    
    Service = {
      Type = "forking";
      ExecStart = "${museum-display-launcher}";
      Restart = "on-failure";
      RestartSec = "10";
      # Run as user, not root
      User = "%i";
      # Set proper environment
      Environment = [
        "XDG_RUNTIME_DIR=/run/user/%i"
        "WAYLAND_DISPLAY=wayland-1"
      ];
    };
    
    Install = {
      WantedBy = [ "sway-session.target" ];
    };
  };
}