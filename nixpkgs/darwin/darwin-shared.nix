{ pkgs, config, lib, ... }:
{
  imports = [
    ./common.nix
    ./sdcard-autosave.nix
  ];

  # Shared Darwin configuration for all machines
  # Machine-specific configurations can be added to individual host entries in hosts.nix if needed
} 