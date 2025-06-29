{ config, lib, pkgs, ... }:

{
  imports = [
    ./modules/home-manager.nix
    ./modules/fish.nix
    ./modules/common.nix
    ./modules/git.nix
    ./modules/neovim.nix
    ./modules/ssh.nix
    ./modules/zellij.nix
  ];

  home.stateVersion = "20.09";

  home.username = "schickling";
  home.homeDirectory = "/home/schickling";

  home.packages = with pkgs; [
    # NOTE node needed for remote vsc server
    nodejs

    fishPlugins.foreign-env

    restic
  ];

  services.gpg-agent = {
    enable = false;
    defaultCacheTtl = 1800;
  };

  # programs.git.signing.signByDefault = true;
}
