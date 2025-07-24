{ config, pkgs, lib, libs, ... }:
{
  programs.git = {
    enable = true;
    userName = "Johannes Schickling";
    userEmail = "schickling.j@gmail.com";

    delta = {
      enable = true;
      options = {
        syntax-theme = "Solarized (dark)";
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

      # Enable rerere (reuse recorded resolution) to automatically resolve
      # merge conflicts using previously recorded resolutions
      rerere.enabled = true;
      # Automatically stage resolved conflicts when rerere applies a resolution
      rerere.autoupdate = true;
    };
  };
}
