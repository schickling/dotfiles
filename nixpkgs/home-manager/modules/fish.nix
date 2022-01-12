{ config, pkgs, libs, ... }:
{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set PATH ~/.cargo/bin ~/.local/bin $PATH
      set EDITOR nvim
    '';
    functions = {
      # flakify = ''
      #   if not test -e flake.nix
      #     wget https://raw.githubusercontent.com/pimeys/nix-prisma-example/main/flake.nix
      #     nvim flake.nix
      #   end
      #   if not test -e .envrc
      #     echo "use flake" > .envrc
      #     direnv allow
      #   end
      # '';
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
      # cw =
      #   "cargo watch -s 'clear; cargo check --tests --all-features --color=always 2>&1 | head -40'";
      # cwa =
      #   "cargo watch -s 'clear; cargo check --tests --features=all --color=always 2>&1 | head -40'";
      # ls = "exa --git --icons";
    };
  };
}