{ config, pkgs, lib, libs, ... }:
{
  programs.git = {
    enable = true;
    userName = "Johannes Schickling";
    userEmail = "schickling.j@gmail.com";

    signing.key = "8E9046ABA7CA018432E4A4897D614C236B9A75E6";

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
