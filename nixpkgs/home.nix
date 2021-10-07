{ config, lib, pkgs, ... }:

{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "schickling";
  home.homeDirectory = "/home/schickling";

  # I've disabled this option as I manually manage it (by temporarily having the option below
  # and having copied the file contents to `~/.config/fish/config/nixos/home-manager-gen.fish).
  # Also see https://github.com/nix-community/home-manager/blob/db00b39a9abec04245486a01b236b8d9734c9ad0/modules/programs/fish.nix#L339
  # programs.fish.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.sessionPath = [
    "$HOME/.npm-global-packages/bin"
    # "$HOME/.vscode-server/bin/e7d7e9a9348e6a8cc8c03f877d39cb72e5dfb1ff/bin"
  ];

  # environment.variables.PATH = [
  #   "~/.npm-global-packages/bin"
  # ];

  home.packages = [
    pkgs.gnupg
    pkgs.awscli
    pkgs.graphviz
    pkgs.git-crypt
    pkgs.nodejs
    pkgs.neovim
    pkgs.python38
    pkgs.go
    pkgs.cloc
    pkgs.docker
    pkgs.docker-compose
    pkgs.rnix-lsp
    # github cli
    pkgs.gitAndTools.gh
    # needed for headless chrome
    pkgs.chromium
  ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "vscode-extension-ms-vscode-remote-remote-ssh"
  ];

  programs.git = {
    enable = true;
    userName  = "Johannes Schickling";
    userEmail = "schickling.j@gmail.com";
    signing.signByDefault = true;
    signing.key = "8E9046ABA7CA018432E4A4897D614C236B9A75E6";
  };

  services.gpg-agent = {
    enable = false;
    defaultCacheTtl = 1800;
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.05";
}
