{ pkgs, config, lib, ... }:
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  # environment.systemPackages =
  #   [ pkgs.vim
  #   ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;

  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
    auto-optimise-store = true

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
    distributedBuilds = true;
  };


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
