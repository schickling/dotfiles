{ config, lib, pkgs, ... }:

{
  imports = [
    ./modules/darwin-common.nix
  ];

  # Host-specific packages
  home.packages = with pkgs; [
    nodejs
    yarn
  ];
}
