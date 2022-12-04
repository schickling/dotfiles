# NOTE this file isn't needed/used anymore (see ./configuration.nix instead)
# TODO remove this file soon
{ config
, pkgs
, inputs
, common
, lib
, ...
}: {
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
    # "${inputs.nixpkgs}/nixos/modules/profiles/base.nix"
    # "${inputs.nixpkgs}/nixos/modules/profiles/installation-device.nix"
    # "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image.nix"
    # "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/sd-image.nix"
  ];

  # boot.loader.grub.enable = false;
  # boot.loader.raspberryPi.enable = true;
  # boot.loader.raspberryPi.version = 4;
  # boot.kernelPackages = pkgs.linuxPackages_rpi4;

  # boot.consoleLogLevel = lib.mkDefault 7;

  # boot.kernelParams = [
  #   # Increase `cma` to 64M to allow to use all of the RAM.
  #   "cma=64M"
  #   "console=tty0"
  #   # To enable the serial console, uncomment the following line.
  #   # "console=ttyS0,115200n8" "console=ttyAMA0,115200n8"
  #   # Some Raspberry Pi 4 fail to boot correctly without the following. See issue #20.
  #   "8250.nr_uarts=1"
  # ];

  # Remove some kernel modules added for AllWinner SOCs that are not available for RPi's kernel. See https://git.io/JOlb3
  # boot.initrd.availableKernelModules = [
  #   # Allows early (earlier) modesetting for the Raspberry Pi
  #   "vc4"
  #   "bcm2835_dma"
  #   "i2c_bcm2835"
  # ];

  sdImage.compressImage = false;

  time.timeZone = "CET";

  nix = {
    # Currently disabled `nix.settings.auto-optimise-store` as it seems to fail with remote builders
    # TODO renable when fixed https://github.com/NixOS/nix/issues/7273
    settings.auto-optimise-store = false;

    extraOptions = ''
      # needed for nix-direnv
      keep-outputs = true
      keep-derivations = true

      experimental-features = nix-command flakes
    '';
  };

  networking = {
    hostName = "homepi";
    networkmanager.enable = true;
    firewall.enable = false;
    nameservers = [ "8.8.8.8" ];
  };

  # Enable SSH in the boot process https://nixos.wiki/wiki/Creating_a_NixOS_live_CD#SSH
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];

  users.users.root.openssh.authorizedKeys.keys = common.sshKeys;

  # The installer starts with a "nixos" user to allow installation, so add the SSH key to
  # that user. Note that the key is, at the time of writing, put in `/etc/ssh/authorized_keys.d`
  # users.extraUsers.nixos.openssh.authorizedKeys.keys = common.sshKeys;

  services.openssh = {
    enable = true;
    extraConfig = ''
      # needed for gpg agent forwarding
      StreamLocalBindUnlink yes
      # needed for ssh agent forwarding
      AllowAgentForwarding yes
    '';
  };

  system.stateVersion = "22.05";
}
