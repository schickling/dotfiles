{ config, lib, pkgs, pkgsUnstable, common, ... }:

{
  time.timeZone = "CET";

  security.sudo.wheelNeedsPassword = false;

  users.users.root.openssh.authorizedKeys.keys = common.sshKeys;

  services.openssh = {
    enable = true;
    extraConfig = ''
      # needed for gpg agent forwarding
      StreamLocalBindUnlink yes
      # needed for ssh agent forwarding
      AllowAgentForwarding yes
    '';
  };

  users.defaultUserShell = pkgs.fish;
  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    neovim
    vim
    direnv
    tree
    jq
    bottom
    bat
    pkgsUnstable.tailscale
    git
    gnumake
    killall
  ];

  # Common IP forwarding settings (needed for Tailscale)
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  # Common Nix configuration
  nix = {
    settings = {
      auto-optimise-store = true;
      substituters = lib.mkAfter [ "https://devenv.cachix.org" ];
      trusted-public-keys = lib.mkAfter [ "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=" ];
    };

    extraOptions = ''
      # needed for nix-direnv
      keep-outputs = true
      keep-derivations = true

      experimental-features = nix-command flakes
    '';
  };

  # Enable Tailscale on all machines
  services.tailscale.enable = true;

  # Common firewall settings
  networking.firewall = {
    enable = true;
    # always allow traffic from your Tailscale network
    trustedInterfaces = [ "tailscale0" ];
    # allow the Tailscale UDP port through the firewall
    allowedUDPPorts = [ config.services.tailscale.port ];
    # allow you to SSH in over the public internet
    allowedTCPPorts = [ 22 ];
    # Needed by Tailscale to allow for exit nodes and subnet routing
    checkReversePath = "loose";
  };

}
