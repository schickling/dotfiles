{ config, pkgs, lib, libs, ... }:
{
  programs.git = {
    enable = true;
    userName = "Johannes Schickling";
    userEmail = "schickling.j@gmail.com";

    delta = {
      enable = true;
      options = {
        syntax-theme = "solarized-dark";
        side-by-side = true;
      };
    };

    extraConfig = {
      pull.rebase = true;
      init.defaultBranch = "main";
      github.user = "schickling";

      push.autoSetupRemote = true;

      core.editor = "nvim";
      core.fileMode = false;
      core.ignorecase = false;
    };
  };
}
