{ config, lib, pkgs, ... }:

{
  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "20.09";

  programs.fish.interactiveShellInit = ''
    set -x SSH_AUTH_SOCK "$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";

    set -x PATH $PATH "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
  '';

  # http://czyzykowski.com/posts/gnupg-nix-osx.html
  # adds file to `~/.nix-profile/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac`
  home.packages = with pkgs; [
    pinentry_mac

    nodejs

    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/data/fonts/nerdfonts/default.nix
    # nerdfonts
  ];

  # TODO
  # https://aregsar.com/blog/2020/turn-on-key-repeat-for-macos-text-editors/
  # automate `defaults write com.google.chrome ApplePressAndHoldEnabled -bool false`
}
