{ pkgs, config, lib, ... }:
{
  imports = [
    ../common.nix
    ./sdcard-autosave.nix
  ];
}
