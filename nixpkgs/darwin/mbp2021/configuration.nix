{ pkgs, config, lib, ... }:
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  # environment.systemPackages =
  #   [ pkgs.vim
  #   ];

  imports = [
    # TODO remove when merged https://github.com/LnL7/nix-darwin/pull/228
    ./pam.nix
  ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;

  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
    auto-optimise-store = true

    # assuming the builder has a faster internet connection
    builders-use-substitutes = true

    experimental-features = nix-command flakes
  '';

  nix = {
    buildMachines = lib.filter (x: x.hostName != config.networking.hostName) [
      {
        systems = [ "aarch64-linux" "x86_64-linux" ];
        sshUser = "root";
        maxJobs = 4;
        # relies on `/var/root/.ssh/nix-builder` key to be there
        # TODO set this up via nix
        hostName = "oracle-nix-builder";
        supportedFeatures = [ "nixos-test" "benchmark" "kvm" "big-parallel" ];
      }
    ];
    distributedBuilds = config.nix.buildMachines != [ ];
  };

  # Setup 1Password CLI `op`
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "1password-cli"
  ];

  system.activationScripts.extraActivation.text = ''
    # For TouchID to work in `op` 1Password CLI, it needs to be at `/usr/local/bin`
    # (Hopefully this requirement will be lifted by 1Password at some point)
    # NOTE we don't install `op` via nix but simply copy the binary
    cp ${pkgs._1password}/bin/op /usr/local/bin/op

    # echo "auth sufficient pam_tid.so" > /etc/pam.d/sudo_touchid
  '';

  # system.activationScripts.extraActivation.text = ''
  # '';

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


  # TODO enable
  # system.defaults.NSGlobalDomain = {
  #   InitialKeyRepeat = 33; # unit is 15ms, so 500ms
  #   KeyRepeat = 2; # unit is 15ms, so 30ms
  #   NSDocumentSaveNewDocumentsToCloud = false;
  # };

  # TODO enable
  # fonts = {
  #   fontDir.enable = true;
  #   fonts = [
  #     (pkgs.nerdfonts.override {
  #       fonts = [
  #         "CascadiaCode"
  #         "FantasqueSansMono"
  #         "FiraCode"
  #         "FiraMono"
  #         "Hack" # no ligatures
  #         "Hasklig"
  #         "Inconsolata"
  #         "Iosevka"
  #         "JetBrainsMono"
  #         "VictorMono"
  #       ];
  #     })
  #   ];
  # };

  system.stateVersion = 4;
}
