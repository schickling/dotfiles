# homepi NixOS Deployment

Raspberry Pi 4 running NixOS (aarch64-linux).

## Principles

- **Declarative configuration**: All system state is defined in Nix files, not manual setup
- **No imperative changes**: Avoid `docker run`, `apt install`, or manual config edits on the device
- **Reproducible**: Same flake input = same system output
- **Version controlled**: All changes go through git, enabling rollbacks and history

## Services

- **Home Assistant**: Smart home automation (`ghcr.io/home-assistant/home-assistant:stable`)
- **Matterbridge**: Exposes HA entities to HomeKit via Matter protocol (`luligu/matterbridge`)

## Deploy

Uses dev3 as remote builder via Nix's distributed builds (configured in `nix.custom.conf`).

```fish
# Build (automatically offloads aarch64-linux builds to dev3)
nix build .#nixosConfigurations.homepi.config.system.build.toplevel

# Copy to homepi and activate
nix copy --to ssh://root@homepi ./result
ssh root@homepi "$(readlink ./result)/bin/switch-to-configuration switch"
```

## Verify

```fish
ssh root@homepi "nixos-version && docker ps"
```

## Fresh Install (SD Card Flashing)

For a completely fresh install:

```fish
# 1. Build SD image
nix build .#nixosConfigurations.homepi.config.system.build.sdImage

# 2. Flash to SD card (macOS)
diskutil unmountDisk /dev/diskN
sudo dd if=result/sd-image/*.img of=/dev/rdiskN bs=4M status=progress
diskutil eject /dev/diskN
```

## Notes

- AI coding tools (amp, codex, opencode, oi) are excluded on aarch64-linux due to cross-compilation issues with patchelf under QEMU binfmt
- homepi connects via Tailscale for remote access
