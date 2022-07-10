{ config, pkgs, inputs, lib, common, ... }:

{
  imports = [
    ./hardware-configuration.nix # Include the results of the hardware scan.
    # ./tailscale.nix
    ../configuration-common.nix
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
  ];

  boot = {
    # TODO re-enable when fixed https://github.com/NixOS/nixpkgs/issues/154163
    # kernelPackages = pkgs.linuxPackages_rpi4;
    tmpOnTmpfs = true;
    initrd.availableKernelModules = [ "usbhid" "usb_storage" ];
    # ttyAMA0 is the serial console broken out to the GPIO
    kernelParams = [
      "8250.nr_uarts=1"
      "console=ttyAMA0,115200"
      "console=tty1"
      # A lot GUI programs need this, nearly all wayland applications
      "cma=128M"
    ];
    # loader = {
    #   raspberryPi = { enable = true; version = 4; };
    #   grub.enable = false;
    # };
  };

  # Required for the Wireless firmware
  # hardware.enableRedistributableFirmware = true;

  sdImage.compressImage = false;

  # fileSystems = lib.mkForce {
  #   # There is no U-Boot on the Pi 4, thus the firmware partition needs to be mounted as /boot.
  #   "/boot" = {
  #     device = "/dev/disk/by-label/FIRMWARE";
  #     fsType = "vfat";
  #   };
  #   "/" = {
  #     device = "/dev/disk/by-label/NIXOS_SD";
  #     fsType = "ext4";
  #   };
  # };

  networking = {
    hostName = "homepi";
    nameservers = [ "8.8.8.8" ];

    firewall = {
      enable = true;
      # enable = false; # I've found it's easiest to disable the firewall during Homekit pairing

      # always allow traffic from your Tailscale network
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [
        config.services.tailscale.port # allow the Tailscale UDP port through the firewall
        5353 # Needed for Homekit Secure Video - (Bonjour Multicast DNS - https://support.apple.com/en-us/HT202944)
      ];
      allowedTCPPorts = [
        22 # allow you to SSH in locally or over the public internet
        1400 # Sonos https://www.home-assistant.io/integrations/sonos/#network-requirements
        21063 # Homekit Bridge HA https://www.home-assistant.io/integrations/homekit/#port
        { from = 30000; to = 50000; } # Random port range of Scrypted https://github.com/koush/scrypted/blob/a511130c2934b0a51b16bd1297df972248cc1619/plugins/homekit/src/hap-utils.ts#L100
      ];

      checkReversePath = "loose"; # Needed by Tailscale to allow for exit nodes and subnet routing

      # Needed to stop Docker from exposing ports despite the firewall
      # See https://github.com/NixOS/nixpkgs/issues/111852
      extraCommands = ''
        iptables -N DOCKER-USER || true
        iptables -F DOCKER-USER
        iptables -A DOCKER-USER -i enp7s0 -m state --state RELATED,ESTABLISHED -j ACCEPT
        iptables -A DOCKER-USER -i enp7s0 -j DROP
      '';
    };
  };


  nix = {
    autoOptimiseStore = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    # needed for nix-direnv
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true

      experimental-features = nix-command flakes
    '';
  };

  users.users.schickling = {
    isNormalUser = true;
    home = "/home/schickling";
    extraGroups = [
      "wheel"
      "docker"
      # "podman"
    ];
    openssh.authorizedKeys.keys = common.sshKeys;
  };

  virtualisation.docker = {
    enable = true;
    # Needed since Docker by default surpases firewall https://github.com/NixOS/nixpkgs/issues/111852#issuecomment-1031051463
    # extraOptions = ''--iptables=false --ip6tables=false'';
  };

  # enable the tailscale daemon; this will do a variety of tasks:
  # 1. create the TUN network device
  # 2. setup some IP routes to route through the TUN
  services.tailscale.enable = true;

  system.stateVersion = "21.11";
}
