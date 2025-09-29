{ config, lib, pkgs, pkgsUnstable, common, ... }:

let
  self-signed-ca = pkgs.callPackage ./self-signed-ca.nix { };
in
{
  imports = [
    ./hardware-configuration.nix
    (import ./buildkite.nix { self-signed-ca = self-signed-ca; inherit pkgs; })
    ../configuration-common.nix
    ../server-common.nix
    ../../modules/onepassword.nix
  ];
  # Use systemd-boot as the boot loader with UEFI support.
  # systemd-boot is more reliable than GRUB for UEFI on newer servers like AX102.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.swraid.enable = true;
  boot.kernelParams = ["boot.shell_on_fail"];

  # Add similar kernel optimizations as dev2
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Increase the amount of inotify watchers
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 1048576; # default:  8192
    "fs.inotify.max_user_instances" = 1024; # default:   128
    "fs.inotify.max_queued_events" = 32768; # default: 16384
  };

  networking.hostName = "dev3";
  
  # The mdadm RAID1s were created with 'mdadm --create ... --homehost=hetzner',
  # Same configuration as dev2 but using environment.etc instead of boot.swraid.mdadmConf
  environment.etc."mdadm.conf".text = ''
    HOMEHOST <ignore>
  '';

  # Network (Hetzner uses static IP assignments, dual stack IPv4 + IPv6 for dev3)
  networking.useDHCP = false;
  networking.interfaces."enp6s0".ipv4.addresses = [
    {
      address = "148.251.133.181";
      prefixLength = 27;
    }
  ];
  networking.interfaces."enp6s0".ipv6.addresses = [
    {
      address = "2a01:4f8:210:32a1::1";
      prefixLength = 64;
    }
  ];
  networking.defaultGateway = "148.251.133.161";
  networking.defaultGateway6 = { address = "fe80::1"; interface = "enp6s0"; };
  # Using Google's public DNS servers for reliable DNS resolution (both IPv4 and IPv6)
  networking.nameservers = [ "8.8.8.8" "2001:4860:4860::8888" "2001:4860:4860::8844" ];

  # Machine-specific firewall settings (extends common firewall from configuration-common.nix)
  networking.firewall = {
    extraCommands = ''
      iptables -N DOCKER-USER || true
      iptables -F DOCKER-USER
      iptables -A DOCKER-USER -i enp6s0 -m state --state RELATED,ESTABLISHED -j ACCEPT
      iptables -A DOCKER-USER -i enp6s0 -j DROP
    '';
  };

  # Certificate configuration
  security.pki.certificateFiles = [ "${self-signed-ca}/rootCA.pem" ];

  environment.sessionVariables = {
    CAROOT = "${self-signed-ca}";
  };

  # Enable Tailscale exit node capability (extends server-common config)
  services.tailscale = {
    extraUpFlags = [ "--ssh" "--advertise-exit-node" ];
  };

  # only allow access via tailscale
  services.openssh.openFirewall = false;

  # Machine-specific user groups (extends common user from server-common.nix)
  users.users.schickling.extraGroups = [
    "wheel"
    "networkmanager" 
    "docker"
  ];

  system.stateVersion = "25.05";
}
