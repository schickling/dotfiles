{ config, pkgs, inputs, lib, common, ... }:

{
  imports = [
    ./hardware-configuration.nix # Include the results of the hardware scan.
    # ./tailscale.nix
    ../configuration-common.nix
    ../server-common.nix
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
    # Using Google's public IPv4 DNS server for reliable DNS resolution  
    nameservers = [ "8.8.8.8" ];

    # Machine-specific firewall settings (extends common firewall from configuration-common.nix)
    firewall = {
      # enable = false; # I've found it's easiest to disable the firewall during Homekit pairing

      allowedUDPPorts = [
        5353 # Needed for Homekit Secure Video - (Bonjour Multicast DNS - https://support.apple.com/en-us/HT202944)
      ];
      allowedTCPPorts = [
        1400 # Sonos https://www.home-assistant.io/integrations/sonos/#network-requirements
        21063 # Homekit Bridge HA https://www.home-assistant.io/integrations/homekit/#port
        8123 # Home Assistant
      ];
      allowedTCPPortRanges = [
        { from = 30000; to = 50000; } # Random port range of Scrypted https://github.com/koush/scrypted/blob/a511130c2934b0a51b16bd1297df972248cc1619/plugins/homekit/src/hap-utils.ts#L100
      ];

      # Machine-specific Docker workaround (homepi uses eth0 and potentially wlan0)
      extraCommands = ''
        iptables -N DOCKER-USER || true
        iptables -F DOCKER-USER
        # Block external access via ethernet
        iptables -A DOCKER-USER -i eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
        iptables -A DOCKER-USER -i eth0 -j DROP
        # Block external access via WiFi (if used)
        iptables -A DOCKER-USER -i wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
        iptables -A DOCKER-USER -i wlan0 -j DROP
      '';
    };
  };


  # Machine-specific nix configuration (extends common nix from configuration-common.nix)
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Machine-specific user groups (extends common user from server-common.nix)
  users.users.schickling.extraGroups = [
    "wheel"
    "docker"
    # "podman"
  ];

  # Machine-specific Docker configuration (extends common Docker from server-common.nix)
  # virtualisation.docker.extraOptions = ''--iptables=false --ip6tables=false'';

  system.stateVersion = "21.11";
}
