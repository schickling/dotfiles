{ config, lib, pkgs, pkgsUnstable, ... }:

{
  imports = [
    ./home-manager.nix
    ./fish.nix
    ./common.nix
    ./git.nix
    ./lazygit.nix
    ./neovim.nix
    ./ssh.nix
    ./zellij.nix
  ];

  home.stateVersion = "20.09";
  home.username = "schickling";
  home.homeDirectory = "/home/schickling";

  services.gpg-agent = {
    enable = false;
    defaultCacheTtl = 1800;
  };

  # Common Git signing configuration for 1Password
  programs.git.signing.signByDefault = true;
  programs.git.signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBY2vg6JN45hpcl9HH279/ityPEGGOrDjY3KdyulOUmX"; # from 1Password
  programs.git.extraConfig.gpg.format = "ssh";
  programs.git.extraConfig.gpg.ssh.program = "/usr/local/bin/op-ssh-sign";

  programs.fish.interactiveShellInit = ''
    # `/usr/local/bin` is needed for biometric-support in `op` 1Password CLI
    set -x PATH $PATH /usr/local/bin 
  '';
} 