{ pkgs, config, lib, pkgsUnstable, ... }:
{
  imports = [
    ../modules/onepassword.nix
  ];

  # We use Determinate Systems' Nix installer on macOS and keep nix-darwin's
  # own Nix management disabled to avoid conflicts over files in /etc.
  nix.enable = false; # Nix managed outside of nix-darwin (Determinate Systems)

  # IMPORTANT: /etc/nix/nix.custom.conf is created by Determinate Systems' installer
  # (see header in that file). Managing the same path from nix-darwin causes
  # activation to abort with "Unexpected files in /etc" if the file already
  # exists and is not a nix store symlink. We therefore do NOT declare
  # environment.etc."nix/nix.custom.conf" here.
  # The current DS-managed file already contains the desired cache settings:
  #   extra-substituters = https://devenv.cachix.org
  #   extra-trusted-public-keys = devenv.cachix.org-1:...
  # If these need to change in the future, either update the DS-managed file
  # manually or migrate ownership of that path to nix-darwin (rename existing
  # file to *.before-nix-darwin and declare environment.etc accordingly).

  # Unfree packages are configured centrally in flake.nix

  system.activationScripts.extraActivation.text = ''
    # Make `gitx` available in the terminal
    ln -sfv /Applications/GitX.app/Contents/Resources/gitx /usr/local/bin/gitx

    # VSCode settings symlinks - with conditional check for directory existence
    if [ -d "$HOME/Library/Application Support/Code/User" ]; then
      ln -sfv ~/.config/VSCode/settings.json ~/Library/Application\ Support/Code/User/settings.json
      ln -sfv ~/.config/VSCode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
    fi
  '';

  security.pam.services.sudo_local.touchIdAuth = true;

  programs = {
    fish.enable = true;
  };

  environment.shells = [ pkgs.fish ];

  # Set primary user for system defaults
  system.primaryUser = "schickling";

  users.users.schickling = {
    home = "/Users/schickling";
    shell = "${pkgs.fish}/bin/fish";
  };
  users.users.root = {
    home = "/var/root";
    shell = "${pkgs.fish}/bin/fish";
  };

  # can be read via `defaults read NSGlobalDomain`
  system.defaults.NSGlobalDomain = {
    InitialKeyRepeat = 15; # unit is 15ms, so 500ms
    KeyRepeat = 2; # unit is 15ms, so 30ms
    NSDocumentSaveNewDocumentsToCloud = false;
    ApplePressAndHoldEnabled = false;
    AppleShowScrollBars = "WhenScrolling";
    AppleShowAllExtensions = true;
  };
  system.defaults.dock.autohide = true;

  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;

  fonts = {
    packages = [
      pkgs.inter
      pkgs.nerd-fonts.fira-code
      pkgs.nerd-fonts.fira-mono
      pkgs.nerd-fonts.jetbrains-mono
      pkgs.nerd-fonts.sauce-code-pro
    ];
  };

  system.stateVersion = 4;
} 
