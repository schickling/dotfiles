{ config, pkgs, lib, ... }:

{
  imports = [
    ../configuration-common.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_rpi4;
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

  boot.loader.raspberryPi = {
    enable = true;
    version = 4;
  };
  boot.loader.grub.enable = false;

  # Required for the Wireless firmware
  hardware.enableRedistributableFirmware = true;

  networking = {
    hostName = "homepi";
    networkmanager = {
      enable = true;
    };
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
  # };

  nix = {
    autoOptimiseStore = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  nix.package = pkgs.nixUnstable;

  # needed for nix-direnv
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true

    experimental-features = nix-command flakes
  '';

  users.users.homepi = {
    isNormalUser = true;
    home = "/home/homepi";
    extraGroups = [ "wheel" "networkmanager" "podman" ];
    openssh.authorizedKeys.keys = users.users.root.openssh.authorizedKeys.keys;
  };

  # enable the tailscale daemon; this will do a variety of tasks:
  # 1. create the TUN network device
  # 2. setup some IP routes to route through the TUN
  services.tailscale.enable = true;

  # only allow access via tailscale
  # services.openssh.openFirewall = false;

  system.stateVersion = "21.11";
}
