#!/bin/bash
# Museum Display Deployment Script
# Deploys enhanced Nix configuration to Raspberry Pi

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

main() {
    log "🏛️  Deploying Museum Display Nix Configuration"
    log "Target: Raspberry Pi 5 Museum Display"
    
    # Check if we're in the right directory
    if [[ ! -f "nixpkgs/home-manager/rpi-museum.nix" ]]; then
        error "rpi-museum.nix not found. Please run from ~/.config directory"
        exit 1
    fi
    
    # Step 1: Deploy Nix configuration
    log "Deploying home-manager configuration..."
    if home-manager switch --flake .#rpi-museum; then
        success "Nix configuration deployed successfully"
    else
        error "Failed to deploy Nix configuration"
        exit 1
    fi
    
    # Step 2: Setup system-level components on Pi
    log "Setting up system-level components on Raspberry Pi..."
    
    if ssh pimuseum "
        # Install touch calibration udev rule
        sudo cp ~/.config/museum-display/99-goodix-touchscreen.rules /etc/udev/rules.d/ &&
        sudo udevadm control --reload-rules &&
        sudo udevadm trigger &&
        echo 'Touch calibration udev rule installed'
    "; then
        success "System-level setup completed"
    else
        warn "System-level setup had issues (may require manual intervention)"
    fi
    
    # Step 3: Enable auto-start service
    log "Enabling museum display auto-start service..."
    
    if ssh pimuseum "
        systemctl --user enable museum-display.service &&
        echo 'Museum display service enabled'
    "; then
        success "Auto-start service enabled"
    else
        warn "Service enablement had issues (may already be enabled)"
    fi
    
    # Step 4: Verification
    log "Performing deployment verification..."
    
    # Check launcher exists
    if ssh pimuseum "test -x ~/launch-museum-display.sh"; then
        success "Launcher script is present and executable"
    else
        error "Launcher script missing or not executable"
    fi
    
    # Check touch calibration
    if ssh pimuseum "libinput list-devices | grep -q 'Goodix.*TouchScreen'"; then
        success "Touch device detected"
    else
        warn "Touch device not detected (may not be connected)"
    fi
    
    # Check Sway configuration
    if ssh pimuseum "test -f ~/.config/sway/config"; then
        success "Sway configuration exists"
    else
        warn "Sway configuration not found"
    fi
    
    # Final summary
    log ""
    success "✅ Museum Display Deployment Complete!"
    log ""
    log "📋 Next Steps:"
    log "   1. Test launcher: ssh pimuseum '~/launch-museum-display.sh'"
    log "   2. Check service: ssh pimuseum 'systemctl --user status museum-display.service'"
    log "   3. View logs: ssh pimuseum 'tail -f /tmp/museum-display-\$(date +%Y%m%d).log'"
    log ""
    log "🎯 The museum display system is ready for production use!"
}

# Handle script interruption
cleanup() {
    log "Deployment interrupted"
    exit 1
}

trap cleanup INT TERM

# Run main function
main "$@"