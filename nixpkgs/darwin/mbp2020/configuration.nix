{ pkgs, config, lib, ... }:
{
  imports = [
    ../common.nix
  ];

  # Machine-specific configuration
  fonts.fontDir.enable = true;
}
