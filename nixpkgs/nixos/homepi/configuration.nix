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
    networkmanager.enable = true;
  };

  networking.nameservers = [ "8.8.8.8" ];

  # networking.firewall = {
  #   enable = true;
  #   # always allow traffic from your Tailscale network
  #   trustedInterfaces = [ "tailscale0" ];
  #   # allow the Tailscale UDP port through the firewall
  #   allowedUDPPorts = [ config.services.tailscale.port ];
  #   # allow you to SSH in over the public internet
  #   allowedTCPPorts = [ 22 ];
  #   # Needed by Tailscale to allow for exit nodes and subnet routing
  #   checkReversePath = "loose";
  # };

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
      "networkmanager"
      "docker"
      # "podman"
    ];
    openssh.authorizedKeys.keys = common.sshKeys;
  };

  virtualisation.docker = {
    enable = true;
    # Needed since Docker by default surpases firewall https://github.com/NixOS/nixpkgs/issues/111852#issuecomment-1031051463
    extraOptions = ''--iptables=false --ip6tables=false'';
  };

  # enable the tailscale daemon; this will do a variety of tasks:
  # 1. create the TUN network device
  # 2. setup some IP routes to route through the TUN
  services.tailscale.enable = true;

  # only allow access via tailscale
  # services.openssh.openFirewall = false;

  system.stateVersion = "21.11";
}
