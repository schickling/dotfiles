{ config, lib, pkgs, pkgsUnstable, ... }:

{
  imports = [
    ./home-manager.nix
    ./fish.nix
    ./common.nix
    ./git.nix
    ./neovim.nix
    ./ssh.nix
    ./zellij.nix
  ];

  programs.ssh.extraConfig = ''
    # 1Password
    IdentityAgent "~/.1password/agent.sock"
  '';

  home.homeDirectory = "/Users/schickling";
  home.username = "schickling";
  home.stateVersion = "20.09";

  programs.fish.interactiveShellInit = ''
    set -x SSH_AUTH_SOCK "$HOME/.1password/agent.sock"
    set -x PATH $PATH "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
    set -x PATH $PATH "/run/current-system/sw/bin/"
    set -x PATH $PATH "$HOME/.config/bin"
    set -x PATH $PATH /usr/local/bin 
  '';

  # Common Git signing configuration
  programs.git.signing.signByDefault = true;
  programs.git.signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBY2vg6JN45hpcl9HH279/ityPEGGOrDjY3KdyulOUmX"; # from 1Password
  programs.git.extraConfig.gpg.format = "ssh";
  programs.git.extraConfig.gpg.ssh.program = "/usr/local/bin/op-ssh-sign";

  programs.home-manager.enable = true;
} 