{ config, lib, pkgs, ... }:

{
  imports = [
    ./modules/linux-common.nix
  ];

  # Gitpod-specific overrides
  home.username = lib.mkForce "gitpod";
  home.homeDirectory = lib.mkForce "/home/gitpod";

  # Disable git signing on Gitpod since there's no easy way to forward 1Password
  programs.git.signing.signByDefault = lib.mkForce false;
}
