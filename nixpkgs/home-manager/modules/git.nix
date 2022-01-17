{ config, pkgs, libs, ... }:
{
  programs.git = {
    enable = true;
    userName = "Johannes Schickling";
    userEmail = "schickling.j@gmail.com";
    signing.signByDefault = true;
    signing.key = "8E9046ABA7CA018432E4A4897D614C236B9A75E6";

    delta = {
      enable = true;
      options = {
        syntax-theme = "solarized-dark";
        minus-style = "#fdf6e3 #dc322f";
        plus-style = "#fdf6e3 #859900";
        side-by-side = false;
      };
    };

    extraConfig = {
      pull.rebase = true;
      init.defaultBranch = "main";
      github.user = "schickling";

      core.editor = "nvim";
      core.fileMode = false;
      core.ignorecase = false;
    };
  };
}
