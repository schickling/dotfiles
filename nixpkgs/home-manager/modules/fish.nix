{ config, pkgs, libs, ... }:
{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set PATH ~/.local/bin ~/.cargo/bin ~/.deno/bin $GOPATH/bin ~/.npm-global-packages/bin $PATH

      # Setup terminal, and turn on colors
      set -x TERM xterm-256color

      # Enable color in grep
      set -x GREP_OPTIONS '--color=auto'
      set -x GREP_COLOR '3;33'

      # language settings
      set -x LANG en_US.UTF-8
      set -x LC_CTYPE "en_US.UTF-8"
      set -x LC_MESSAGES "en_US.UTF-8"
      set -x LC_COLLATE C

      set EDITOR nvim

      # Enable direnv
      if command -v direnv &>/dev/null
          eval (direnv hook fish)
      end
    '';
    functions = {
      # TODO doesn't work yet
      _git_fast = ''
        function _git_fast --argument-names 'message'
          if begin not type -q commitizen; and test -z $message; end
            echo "No commit message provided or `commitizen` not installed"
            exit 1
          end

          set -x WIP_BRANCH (git symbolic-ref --short HEAD)
          git pull origin $WIP_BRANCH
          git add -A
          if test -z $message
            git cz
          else
            git commit -m $message
          end
          and git push origin $WIP_BRANCH
        end

      '';
    };
    plugins = [{
      name = "bobthefish";
      src = pkgs.fetchFromGitHub {
        owner = "oh-my-fish";
        repo = "theme-bobthefish";
        rev = "e69150081b0e576ebb382487c1ff2cb35e78bb35";
        sha256 = "sha256-/x1NlbhxRZjrsk4C0mkSQi4zzpOaxL1O1vvzDHhGQk0=";
      };
    }];
    shellAliases = {
      v = "nvim";
      l = "lsd";
      gf = "_git_fast";
      fz = "fzf --preview 'bat --style=numbers --color=always --line-range :500 {}'";
      # cw =
      #   "cargo watch -s 'clear; cargo check --tests --all-features --color=always 2>&1 | head -40'";
      # cwa =
      #   "cargo watch -s 'clear; cargo check --tests --features=all --color=always 2>&1 | head -40'";
      # ls = "exa --git --icons";
    };

    shellAbbrs = {
      s = "ssh";
      g = "git";
      gs = "git status -s";
      gd = "git diff";
      gp = "git pull";
      gps = "git push";
      gcm = "git commit";

      findport = "sudo lsof -iTCP -sTCP:LISTEN -n -P | grep";
    };
  };
}
