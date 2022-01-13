{ config, lib, pkgs, ... }:

{
  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  # home.stateVersion = "21.05";
  home.stateVersion = "20.09";

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "gitpod";
  home.homeDirectory = "/home/gitpod";

  home.packages = with pkgs; [
    nodejs

    fishPlugins.foreign-env
  ];

  # services.gpg-agent = {
  #   enable = false;
  #   defaultCacheTtl = 1800;
  # };

}
