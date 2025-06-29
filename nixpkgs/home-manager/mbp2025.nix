{ config, lib, pkgs, pkgsUnstable, ... }:

{
  imports = [
    ./modules/darwin-common.nix
  ];

  # Host-specific packages
  home.packages = with pkgs; [
    nodejs_24
    pkgsUnstable.uv
    ollama
  ];
}
