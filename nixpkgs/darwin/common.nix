{ pkgs, config, lib, ... }:
{
  nix.enable = false; # Disable nix-darwin's Nix management (using Determinate Systems installer)

  # Setup 1Password CLI `op`
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "1password-cli"
    "claude-code"
  ];

  system.activationScripts.extraActivation.text = ''
    # For TouchID to work in `op` 1Password CLI, it needs to be at `/usr/local/bin`
    # (Hopefully this requirement will be lifted by 1Password at some point)
    # NOTE we don't install `op` via nix but simply copy the binary
    mkdir -p /usr/local/bin
    cp ${pkgs._1password-cli}/bin/op /usr/local/bin/op
    # cp ${pkgs._1password-cli}/bin/op-ssh-sign /usr/local/bin/op-ssh-sign
    cp /Applications/1Password.app/Contents/MacOS/op-ssh-sign /usr/local/bin/op-ssh-sign

    # Make `gitx` available in the terminal
    ln -sfv /Applications/GitX.app/Contents/Resources/gitx /usr/local/bin/gitx

    # https://developer.1password.com/docs/ssh/get-started#step-4-configure-your-ssh-or-git-client
    mkdir -p ~/.1password && ln -sfv ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ~/.1password/agent.sock

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