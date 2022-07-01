{ config
, pkgs
, inputs
, common
, ...
}: {
  imports = [
    "${inputs.nixpkgsStable}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
  ];

  time.timeZone = "CET";

  nix = {
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true

      experimental-features = nix-command flakes
    '';
  };

  networking = {
    hostName = "homepi";
    networkmanager.enable = true;
    firewall.enable = false;
  };

  users.groups.networkmanager.members = config.users.groups.wheel.members;
  users.mutableUsers = false;
  users.users.homepi = {
    name = "homepi";
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = common.sshKeys;
  };
  users.defaultUserShell = pkgs.fish;

  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    extraConfig = ''
      # needed for gpg agent forwarding
      StreamLocalBindUnlink yes
      # needed for ssh agent forwarding
      AllowAgentForwarding yes
    '';
  };

  system.stateVersion = "21.11";
}
