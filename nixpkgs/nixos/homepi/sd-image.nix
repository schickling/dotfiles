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
    nameservers = [ "8.8.8.8" ];
  };

  # Enable SSH in the boot process https://nixos.wiki/wiki/Creating_a_NixOS_live_CD#SSH
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];

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

  system.stateVersion = "21.11";
}
