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

  programs.git.signing.signByDefault = false;
  # programs.git.signing.key = "key::ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPkfRqtIP8Lc7qBlJO1CsBeb+OEZN87X+ZGGTfNFf8V588Dh/lgv7WEZ4O67hfHjHCNV8ZafsgYNxffi8bih+1Q= MBP2021@secretive.mbp2021.local";
  # programs.git.extraConfig.gpg.format = "ssh";
}
