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

  # Enable Tailscale SSH for web console access on all servers
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    extraUpFlags = [ "--ssh" ];
  };

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

  # Eternal Terminal server on all NixOS servers
  services.eternal-terminal = {
    enable = true;
    # defaults: port = 2022; verbosity = 0; silent = false; logSize = 20MB
  };

  # Only expose ET on Tailscale interface to keep parity with SSH exposure
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = lib.mkAfter [ 2022 ];

} 
