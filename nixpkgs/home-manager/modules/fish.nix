{ config, pkgs, libs, ... }:
{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set PATH /nix/var/nix/profiles/default/bin ~/.cargo/bin ~/.deno/bin $GOPATH/bin ~/.npm-global-packages/bin $PATH

      # Setup terminal, and turn on colors
      if test -z "$TERM"
        set -x TERM xterm-256color
      end

      # Enable color in grep
      set -x GREP_OPTIONS '--color=auto'
      set -x GREP_COLOR 'mt=3;33'

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

      # Call the function when a new terminal session starts
      # if test "$TERM" = "xterm-ghostty"; and not set -q ZELLIJ
      #   zellij attach || zellij
      # end

      # Enable zoxice `z` (https://github.com/ajeetdsouza/zoxide)
      if command -v zoxide &>/dev/null
        zoxide init fish | source
      end

      # `just` completions
      if command -v just &>/dev/null
        # TODO make this case insensitive
        if test -f Justfile
          complete -c just -a (just --summary)
        end
      end

      # `process-compose` completion wrapper for `pc` alias
      complete -c pc -w process-compose

      # TODO remove once implemented https://github.com/pnpm/pnpm/issues/4520
      # NOTE the below seems rather slow compared to the Yarn autocompletions
      # Possibly give this a try instead: https://github.com/g-plane/pnpm-shell-completion/blob/main/pnpm-shell-completion.fish
      ###-begin-pnpm-completion-###
      function _pnpm_completion
        set cmd (commandline -o)
        set cursor (commandline -C)
        set words (count $cmd)

        set completions (eval env DEBUG=\"" \"" COMP_CWORD=\""$words\"" COMP_LINE=\""$cmd \"" COMP_POINT=\""$cursor\"" pnpm completion -- $cmd)

        if [ "$completions" = "__tabtab_complete_files__" ]
          set -l matches (commandline -ct)*
          if [ -n "$matches" ]
            __fish_complete_path (commandline -ct)
          end
        else
          for completion in $completions
            echo -e $completion
          end
        end
      end

      complete -f -d 'pnpm' -c pnpm -a "(_pnpm_completion)"
      ###-end-pnpm-completion-###
    '';
    functions = {

      o = ''
        if test (count $argv) -eq 0
          open .
        else
          open $argv
        end
      '';

      hm = ''
        pushd ~/.config
        home-manager switch --flake .#$argv[1]
        popd
      '';

      whatsmyip = ''
        curl ifconfig.me
      '';

      fixgpg = ''
        ssh $argv 'killall gpg-agent'
        rm ~/.ssh/sockets/*
        killall gpg-agent
        echo 'test' | gpg --clearsign
        ssh $argv 'ls /run/user/1000/gnupg/'
        ssh $argv 'echo 'test' | gpg --clearsign'
      '';

      fixssh = ''
        ssh $argv 'rm "~/.ssh/sockets/*"'
        rm ~/.ssh/sockets/*
        killall ssh-agent
        ssh $argv 'echo SSH_AUTH_SOCK: $SSH_AUTH_SOCK'
        ssh -tt $argv 'ssh git@github.com'
      '';

      mvbackup = ''
        mv $argv[1] $argv[1].bk-$(date +%Y%m%d-%H%M%S)
      '';

      mvrestore = ''
        original_file_name = echo $argv[1] | sed 's/\.bk(-.*)?//'
        mv $argv[1] 
      '';

      # This is a workaround needed to "fix" VSC on NixOS which is self-updating
      fixremotevsc = ''
        ssh $argv 'for DIR in ~/.vscode-server/bin/*; rm $DIR/node; ln -s (which node) $DIR/node; end'
      '';

      _git_fast = ''
        if begin not type -q commitizen; and test -z $argv[1]; end
          echo "No commit message provided or `commitizen` not installed"
          exit 1
        end

        set -x WIP_BRANCH (git symbolic-ref --short HEAD)
        git pull origin $WIP_BRANCH
        git add -A
        if test -z $argv[1]
          git cz
        else
          git commit -m $argv[1]
        end
        and git push origin $WIP_BRANCH

      '';

      # Create and navigate to a playground project directory in ~/code/playground/YYYY/mmm/project-name
      mkplay = ''
        if test (count $argv) -eq 0
          echo "Usage: mkplay <project-name>"
          return 1
        end

        set project_name $argv[1]
        set year (date +%Y)
        set month (date +%b | tr '[:upper:]' '[:lower:]')
        set play_dir ~/code/playground/$year/$month/$project_name

        mkdir -p $play_dir
        cd $play_dir
        echo "Created and navigated to: $play_dir"
      '';
    };
    plugins = [
      {
        name = "bobthefish";
        src = pkgs.fetchFromGitHub {
          owner = "oh-my-fish";
          repo = "theme-bobthefish";
          rev = "e69150081b0e576ebb382487c1ff2cb35e78bb35";
          sha256 = "sha256-/x1NlbhxRZjrsk4C0mkSQi4zzpOaxL1O1vvzDHhGQk0=";
        };
      }
      {
        name = "fish-docker";
        src = pkgs.fetchFromGitHub {
          owner = "halostatue";
          repo = "fish-docker";
          rev = "e925cd39231398b3842db1106af7acb4ec68dc79";
          sha256 = "sha256-vFWSa4TlygBylWSqFFH195KZM3dE2G3RZjOMTkEhKW8=";
        };
      }
    ];
    shellAliases = {
      v = "nvim";
      p = "pnpm";
      pc = "process-compose";
      l = "lsd";
      gf = "_git_fast";
      fz = "fzf --preview 'bat --style=numbers --color=always --line-range :500 {}'";
      cdg = "cd (git rev-parse --show-toplevel)";
      # cw =
      #   "cargo watch -s 'clear; cargo check --tests --all-features --color=always 2>&1 | head -40'";
      # cwa =
      #   "cargo watch -s 'clear; cargo check --tests --features=all --color=always 2>&1 | head -40'";
      # ls = "exa --git --icons";
    };

    shellAbbrs = {
      s = "ssh";

      # git
      g = "git";
      gs = "git status -s";
      ga = "git add";
      gl = "git log --pretty=format:'%C(yellow)%h %Cred%ar %Cblue%an%Cgreen%d %Creset%s' --date=short";
      gd = "git diff";
      gp = "git pull";
      gps = "git push";
      gcm = "git commit";
      gco = "git checkout";
      gcl = "git clone";

      d = "docker";
      dc = "docker compose";

      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";

      findport = "sudo lsof -iTCP -sTCP:LISTEN -n -P | grep";
    };
  };
}
