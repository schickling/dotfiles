{ config, lib, pkgs , ... }:

{

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "schickling";
  home.homeDirectory = "/home/schickling";

  # I've disabled this option as I manually manage it (by temporarily having the option below
  # and having copied the file contents to `~/.config/fish/config/nixos/home-manager-gen.fish).
  # Also see https://github.com/nix-community/home-manager/blob/db00b39a9abec04245486a01b236b8d9734c9ad0/modules/programs/fish.nix#L339
  # programs.fish.enable = true;


  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "vscode-extension-ms-vscode-remote-remote-ssh"
  ];

  services.gpg-agent = {
    enable = false;
    defaultCacheTtl = 1800;
  };

}
