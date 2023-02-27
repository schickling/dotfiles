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

  programs.ssh.extraConfig =
    ''
      # 1Password
      # IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
      IdentityAgent "~/.1password/agent.sock"
    '';

  home.homeDirectory = "/Users/schickling";
  home.username = "schickling";

  home.stateVersion = "20.09";

  programs.fish.interactiveShellInit = ''
    # set -x SSH_AUTH_SOCK "$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
    set -x SSH_AUTH_SOCK "$HOME/.1password/agent.sock"

    set -x PATH $PATH "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

    # nix-darwin binaries
    set -x PATH $PATH "/run/current-system/sw/bin/"

    # `/usr/local/bin` is needed for biometric-support in `op` 1Password CLI
    set -x PATH $PATH /usr/local/bin 
  '';

  # http://czyzykowski.com/posts/gnupg-nix-osx.html
  # adds file to `~/.nix-profile/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac`
  home.packages = with pkgs; [
    pinentry_mac

    nodejs # Node 18
    (yarn.override { nodejs = nodejs-18_x; })

    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/data/fonts/nerdfonts/default.nix
    # nerdfonts
  ];

  # TODO
  # https://aregsar.com/blog/2020/turn-on-key-repeat-for-macos-text-editors/
  # automate `defaults write com.google.chrome ApplePressAndHoldEnabled -bool false`

  programs.git.signing.signByDefault = true;
  programs.git.signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBY2vg6JN45hpcl9HH279/ityPEGGOrDjY3KdyulOUmX";
  programs.git.extraConfig.gpg.format = "ssh";
  programs.git.extraConfig.gpg.ssh.program = "/usr/local/bin/op-ssh-sign";

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "1password-cli"
  ];

  programs.home-manager.enable = true;
}
