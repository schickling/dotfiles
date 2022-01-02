{ config, pkgs, libs, ... }:
{
  home.sessionPath = [
    "$HOME/.npm-global-packages/bin"
    # "$HOME/.vscode-server/bin/e7d7e9a9348e6a8cc8c03f877d39cb72e5dfb1ff/bin"
  ];

  home.sessionVariables = {
    # NIX_PATH = "nixpkgs=$HOME/Repositories/nix/nix-dotfiles/home-manager/compat";
    EDITOR = "nvim";
  };


  # https://github.com/nix-community/nix-direnv#via-home-manager
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  home.packages = with pkgs; [
    gnupg
    tmux
    wget
    bat
    tree
    awscli
    graphviz
    git-crypt

    youtube-dl

    # nodejs
    # TODO improve: node 14 needed for remote vsc server
    nodejs-14_x
    neovim
    python38
    jq
    go
    cloc
    docker
    # docker-compose
    # Nix VSC
    rnix-lsp
    nixpkgs-fmt
    # github cli
    gitAndTools.gh
    # needed for headless chrome
    # chromium
  ];

  programs.tmux = {
    enable = true;
    clock24 = true;
  };

}
