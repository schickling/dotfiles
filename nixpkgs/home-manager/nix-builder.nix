{ config, lib, pkgs, ... }:

{
  imports = [
    ./modules/home-manager.nix
    ./modules/fish.nix
    ./modules/common.nix
    ./modules/git.nix
    ./modules/neovim.nix
    ./modules/ssh.nix
  ];

  home.stateVersion = "20.09";

  home.username = "root";
  home.homeDirectory = "/root";

  home.packages = with pkgs; [
    fishPlugins.foreign-env
  ];
}
