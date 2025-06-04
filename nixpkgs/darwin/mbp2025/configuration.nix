{ pkgs, config, lib, ... }:
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  # environment.systemPackages =
  #   [ pkgs.vim
  #   ];

  imports = [
  ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  nix = {
    package = pkgs.nix;

    # Currently disabled `nix.settings.auto-optimise-store` as it seems to fail with remote builders
    # TODO renable when fixed https://github.com/NixOS/nix/issues/7273
    settings.auto-optimise-store = false;

    extraOptions = ''
      # needed for nix-direnv
      keep-outputs = true
      keep-derivations = true

      # assuming the builder has a faster internet connection
      builders-use-substitutes = true

      experimental-features = nix-command flakes
    '';

  };

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
    mkdir -p /Users/schickling/.1password && ln -sfv /Users/schickling/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock /Users/schickling/.1password/agent.sock

    if [ -d "/Users/schickling/Library/Application Support/Code/User" ]; then
      ln -sfv /Users/schickling/.config/VSCode/settings.json "/Users/schickling/Library/Application Support/Code/User/settings.json"
      ln -sfv /Users/schickling/.config/VSCode/keybindings.json "/Users/schickling/Library/Application Support/Code/User/keybindings.json"
    fi
  '';

  security.pam.enableSudoTouchIdAuth = true;

  programs = {
    fish.enable = true;
  };

  environment.shells = [ pkgs.fish ];

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
      (pkgs.nerdfonts.override {
        fonts = [
          "FiraCode"
          "FiraMono"
          "JetBrainsMono"
          "SourceCodePro"
        ];
      })
    ];
  };

  system.stateVersion = 4;
}
