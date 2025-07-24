{ config, lib, pkgs, ... }:
{
  # Temporary workaround for claude-code (https://github.com/anthropics/claude-code/issues/2110)
  home.file.".config/direnv/direnv.toml".text = "";

  programs.zsh = {
    enable = true;
    # From https://github.com/anthropics/claude-code/issues/2110#issuecomment-2996564886
    envExtra = ''
      if command -v direnv >/dev/null; then
        if [[ ! -z "$CLAUDECODE" ]]; then
          eval "$(direnv hook zsh)"
          eval "$(DIRENV_LOG_FORMAT= direnv export zsh)"  # Need to trigger "hook" manually

          # If the .envrc is not allowed, allow it
          direnv status --json | jq -e ".state.foundRC.allowed==0" >/dev/null || direnv allow >/dev/null 2>&1
        fi
      fi
    '';
  };
}