{ config, lib, pkgs, pkgsUnstable, common, ... }:

{
  # Common user setup for development servers
  users.users.schickling = {
    isNormalUser = true;
    home = "/home/schickling";
    extraGroups = [
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keys = common.sshKeys;
  };

  # Docker configuration
  virtualisation.docker = {
    enable = true;
  };

  # Common firewall Docker workaround
  networking.firewall.extraCommands = ''
    iptables -N DOCKER-USER || true
    iptables -F DOCKER-USER
    iptables -A DOCKER-USER -i enp7s0 -m state --state RELATED,ESTABLISHED -j ACCEPT
    iptables -A DOCKER-USER -i enp7s0 -j DROP
  '';

  # VSCode server setup
  # https://github.com/msteen/nixos-vscode-server
  # Needs manual starting via `systemctl --user start auto-fix-vscode-server.service`
  services.vscode-server.enable = true;

  # Needed to get VSC server running (see https://nix.dev/guides/faq#how-to-run-non-nix-executables)
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Add any missing dynamic libraries for unpackaged programs
    # here, NOT in environment.systemPackages
  ];

} 