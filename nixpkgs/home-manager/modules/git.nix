{ config, pkgs, lib, libs, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Johannes Schickling";
        email = "schickling.j@gmail.com";
      };
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

      # Allow HTTPS submodules in CI (e.g. Vercel) while keeping SSH locally.
      url."git@github.com:".insteadOf = "https://github.com/";
    };

    lfs = {
      enable = true;
    };
  };

}
