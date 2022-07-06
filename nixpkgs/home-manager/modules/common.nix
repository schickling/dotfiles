{ config, pkgs, pkgsUnstable, libs, ... }:
{

  # https://github.com/nix-community/nix-direnv#via-home-manager
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  home.packages = with pkgs; [
    gnupg
    tmux
    wget
    bat
    bottom
    fzf
    neofetch # fancy system + hardware info

    # Requires a patched font
    # https://github.com/ryanoasis/nerd-fonts/blob/master/readme.md#patched-fonts
    lsd
    tree
    # better du alternative
    du-dust
    # awscli
    graphviz
    git-crypt

    httpstat
    curlie

    # https://github.com/sindresorhus/fkill
    nodePackages.fkill-cli

    pkgsUnstable.youtube-dl
    speedtest-cli

    yarn
    python38
    jq
    go
    cloc
    docker
    tailscale

    ran # quick local webserver (`-r [folder]`)

    # compression
    zip
    pigz # parallel gzip
    lz4

    # docker-compose
    # Nix VSC
    rnix-lsp
    nixpkgs-fmt
    # needed for headless chrome
    # chromium

    git
    # github cli
    gitAndTools.gh

  ] ++ lib.optionals stdenv.isDarwin [
    coreutils # provides `dd` with --status=progress
  ] ++ lib.optionals stdenv.isLinux [
    iputils # provides `ping`, `ifconfig`, ...

    libuuid # `uuidgen` (already pre-installed on mac)
  ];

  programs.tmux = {
    enable = true;
    clock24 = true;
  };

  programs.dircolors = {
    enable = true;
  };

}
