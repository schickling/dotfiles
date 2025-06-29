{ config, lib, pkgs, ... }:

{
  imports = [
    ./modules/linux-common.nix
  ];

  # Machine-specific packages
  home.packages = with pkgs; [
    restic  # for backups
  ];

  # Disable git signing for homepi (no 1Password setup)
  programs.git.signing.signByDefault = lib.mkForce false;
}
