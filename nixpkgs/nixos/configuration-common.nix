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

}
