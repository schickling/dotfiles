{ config, lib, pkgs, ... }:

{
  imports = [
    ./modules/home-manager.nix
    ./modules/fish.nix
    ./modules/common.nix
    ./modules/git.nix
    ./modules/neovim.nix
  ];

  home.stateVersion = "20.09";

  home.username = "gitpod";
  home.homeDirectory = "/home/gitpod";

  home.packages = with pkgs; [
    nodejs # Node 18
    (yarn.override { nodejs = nodejs-18_x; })

    fishPlugins.foreign-env
  ];

  # services.gpg-agent = {
  #   enable = false;
  #   defaultCacheTtl = 1800;
  # };


  # disable gpg signing on Gitpod since there's no easy way to forward my gpg-agent
  programs.git.signing.signByDefault = false;

}
