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

  programs.fish.interactiveShellInit = ''
    # `/usr/local/bin` is needed for biometric-support in `op` 1Password CLI
    set -x PATH $PATH /usr/local/bin 

    # needed as workaround for VSC https://github.com/microsoft/vscode-remote-release/issues/6345#issuecomment-1570909663
    set -x SSH_TTY /dev/pts/0
  '';


  home.username = "schickling";
  home.homeDirectory = "/home/schickling";

  home.packages = with pkgs; [
    # VSC currently requires `NODE_MODULE_VERSION=108` which maps to Node 16 (see https://nodejs.org/en/download/releases/)
    nodejs-18_x

    fishPlugins.foreign-env
  ];

  services.gpg-agent = {
    enable = false;
    defaultCacheTtl = 1800;
  };

  programs.git.signing.signByDefault = true;
  programs.git.signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBY2vg6JN45hpcl9HH279/ityPEGGOrDjY3KdyulOUmX";
  programs.git.extraConfig.gpg.format = "ssh";
  programs.git.extraConfig.gpg.ssh.program = "/usr/local/bin/op-ssh-sign";
}
