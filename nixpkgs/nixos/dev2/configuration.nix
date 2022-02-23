{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use GRUB2 as the boot loader.
  # We don't use systemd-boot because Hetzner uses BIOS legacy boot.
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub = {
    enable = true;
    efiSupport = false;
    devices = [ "/dev/nvme0n1" "/dev/nvme1n1" ];
  };

  # Increase the amount of inotify watchers
  # Note that inotify watches consume 1kB on 64-bit machines.
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches"   = 1048576;   # default:  8192
    "fs.inotify.max_user_instances" =    1024;   # default:   128
    "fs.inotify.max_queued_events"  =   32768;   # default: 16384
  };

  time.timeZone = "CET";

  networking.hostName = "dev2";

  # The mdadm RAID1s were created with 'mdadm --create ... --homehost=hetzner',
  # but the hostname for each machine may be different, and mdadm's HOMEHOST
  # setting defaults to '<system>' (using the system hostname).
  # This results mdadm considering such disks as "foreign" as opposed to
  # "local", and showing them as e.g. '/dev/md/hetzner:root0'
  # instead of '/dev/md/root0'.
  # This is mdadm's protection against accidentally putting a RAID disk
  # into the wrong machine and corrupting data by accidental sync, see
  # https://bugzilla.redhat.com/show_bug.cgi?id=606481#c14 and onward.
  # We do not worry about plugging disks into the wrong machine because
  # we will never exchange disks between machines, so we tell mdadm to
  # ignore the homehost entirely.
  environment.etc."mdadm.conf".text = ''
    HOMEHOST <ignore>
  '';
  # The RAIDs are assembled in stage1, so we need to make the config
  # available there.
  boot.initrd.mdadmConf = config.environment.etc."mdadm.conf".text;

  # Network (Hetzner uses static IP assignments, and we don't use DHCP here)
  networking.useDHCP = false;
  networking.interfaces."enp7s0".ipv4.addresses = [
    {
      address = "195.201.193.171";
      prefixLength = 24;
    }
  ];
  networking.interfaces."enp7s0".ipv6.addresses = [
    {
      address = "2a01:4f8:13a:194a::1";
      prefixLength = 64;
    }
  ];
  networking.defaultGateway = "195.201.193.129";
  networking.defaultGateway6 = { address = "fe80::1"; interface = "enp7s0"; };
  networking.nameservers = [ "8.8.8.8" ];
  networking.firewall = {
    enable = true;
    # always allow traffic from your Tailscale network
    trustedInterfaces = [ "tailscale0" ];
    # allow the Tailscale UDP port through the firewall
    allowedUDPPorts = [ config.services.tailscale.port ];
    # allow you to SSH in over the public internet
    allowedTCPPorts = [ 22 ];
  };


  # Initial empty root password for easy login:
  # users.users.root.initialHashedPassword = "";
  # services.openssh.permitRootLogin = "prohibit-password";

  users.users.root.openssh.authorizedKeys.keys = [
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLXMVzwr9BKB67NmxYDxedZC64/qWU6IvfTTh4HDdLaJe18NgmXh7mofkWjBtIy+2KJMMlB4uBRH4fwKviLXsSM= MBP2020@secretive.MacBook-Pro-Johannes.local"
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBM7UIxnOjfmhXMzEDA1Z6WxjUllTYpxUyZvNFpS83uwKj+eSNuih6IAsN4QAIs9h4qOHuMKeTJqanXEanFmFjG0= MM2021@secretive.Johannes’s-Mac-mini.local"
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPkfRqtIP8Lc7qBlJO1CsBeb+OEZN87X+ZGGTfNFf8V588Dh/lgv7WEZ4O67hfHjHCNV8ZafsgYNxffi8bih+1Q= MBP2021@secretive.Johannes’s-MacBook-Pro.local"
  ];

  # only allow access via tailscale
  services.openssh.openFirewall = false;

  users.users.schickling = {
    isNormalUser = true;
    home = "/home/schickling";
    extraGroups = [ "wheel" "networkmanager" "podman" ];
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLXMVzwr9BKB67NmxYDxedZC64/qWU6IvfTTh4HDdLaJe18NgmXh7mofkWjBtIy+2KJMMlB4uBRH4fwKviLXsSM= MBP2020@secretive.MacBook-Pro-Johannes.local"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBM7UIxnOjfmhXMzEDA1Z6WxjUllTYpxUyZvNFpS83uwKj+eSNuih6IAsN4QAIs9h4qOHuMKeTJqanXEanFmFjG0= MM2021@secretive.Johannes’s-Mac-mini.local"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPkfRqtIP8Lc7qBlJO1CsBeb+OEZN87X+ZGGTfNFf8V588Dh/lgv7WEZ4O67hfHjHCNV8ZafsgYNxffi8bih+1Q= MBP2021@secretive.Johannes’s-MacBook-Pro.local"
    ];
  };

  services.openssh.enable = true;

  # needed for gpg agent forwarding
  services.openssh.extraConfig = ''StreamLocalBindUnlink yes'';

  users.defaultUserShell = pkgs.fish;

  # programs.gnupg.agent = {
  #   enable = true;
  #   pinentryFlavor = "tty";
  # };

  virtualisation.podman = {
    enable = true; 
    dockerCompat = true;
    dockerSocket.enable = true;
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "vscode-extension-ms-vscode-remote-remote-ssh"
  ];

  environment.systemPackages = with pkgs; [
    neovim
    vim
    tree
    jq
    bottom
    bat
    tailscale
    git
    gnumake
    killall
  ];

  nix.package = pkgs.nixUnstable;

  # needed for nix-direnv
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true

    experimental-features = nix-command flakes
  '';

  # enable the tailscale daemon; this will do a variety of tasks:
  # 1. create the TUN network device
  # 2. setup some IP routes to route through the TUN
  services.tailscale.enable = true; 

  # FIXME
  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "21.05"; # Did you read the comment?

}
