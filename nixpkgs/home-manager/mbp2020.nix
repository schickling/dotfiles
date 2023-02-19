{ config, lib, pkgs, ... }:

{
  imports = [
    ./modules/home-manager.nix
    ./modules/fish.nix
    ./modules/common.nix
    ./modules/git.nix
    ./modules/neovim.nix
  ];

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
  # system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled = false;

  # programs.git.signing.signByDefault = false;
  # programs.git.signing.signByDefault = true;
  # programs.git.signing.key = "key::ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPkfRqtIP8Lc7qBlJO1CsBeb+OEZN87X+ZGGTfNFf8V588Dh/lgv7WEZ4O67hfHjHCNV8ZafsgYNxffi8bih+1Q= MBP2021@secretive.mbp2021.local";
  # programs.git.extraConfig.gpg.format = "ssh";

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "1password-cli"
  ];
  
  programs.home-manager.enable = true;
}
