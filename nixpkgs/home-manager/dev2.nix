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

  home.username = "schickling";
  home.homeDirectory = "/home/schickling";

  home.packages = with pkgs; [
    # VSC currently requires `NODE_MODULE_VERSION=93` which maps to Node 16 (see https://nodejs.org/en/download/releases/)
    nodejs-16_x

    fishPlugins.foreign-env
  ];

  services.gpg-agent = {
    enable = false;
    defaultCacheTtl = 1800;
  };

  # TODO enable ssh-based signing via forwarded 1password ssh agent
  programs.git.signing.signByDefault = false;
  programs.git.signing.key = "key::ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBY2vg6JN45hpcl9HH279/ityPEGGOrDjY3KdyulOUmX";
  programs.git.extraConfig.gpg.format = "ssh";
}
