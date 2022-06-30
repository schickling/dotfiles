{ config
, pkgs
, inputs
, ...
}: {
  time.timeZone = "CET";

  environment.systemPackages = with pkgs; [
    fish
    htop
  ];

  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true

      experimental-features = nix-command flakes
    '';
  };

  networking.hostName = "homepi";
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;

  users.groups.networkmanager.members = config.users.groups.wheel.members;
  users.mutableUsers = false;
  users.users.homepi = {
    name = "homepi";
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLXMVzwr9BKB67NmxYDxedZC64/qWU6IvfTTh4HDdLaJe18NgmXh7mofkWjBtIy+2KJMMlB4uBRH4fwKviLXsSM= MBP2020@secretive.MacBook-Pro-Johannes.local"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBM7UIxnOjfmhXMzEDA1Z6WxjUllTYpxUyZvNFpS83uwKj+eSNuih6IAsN4QAIs9h4qOHuMKeTJqanXEanFmFjG0= MM2021@secretive.Johannes’s-Mac-mini.local"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPkfRqtIP8Lc7qBlJO1CsBeb+OEZN87X+ZGGTfNFf8V588Dh/lgv7WEZ4O67hfHjHCNV8ZafsgYNxffi8bih+1Q= MBP2021@secretive.Johannes’s-MacBook-Pro.local"
    ];
  };
  users.defaultUserShell = pkgs.fish;

  security.sudo.wheelNeedsPassword = false;

  services.openssh.enable = true;
  services.openssh.extraConfig = ''
    # needed for gpg agent forwarding
    StreamLocalBindUnlink yes
    # needed for ssh agent forwarding
    AllowAgentForwarding yes
  '';

  system.stateVersion = "21.11";
}
