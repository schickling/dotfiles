{ config, pkgs, pkgsUnstable, libs, ... }:
{

  # https://github.com/nix-community/nix-direnv#via-home-manager
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  home.packages = with pkgs; [
    fish
    gnupg
    tmux
    wget
    bat
    bottom
    glances # alternative to `bottom` but written in Python (so it's slower)
    fzf
    zellij
    lazydocker
    lazygit
    rename
    neofetch # fancy system + hardware info
    tealdeer # fast tldr
    zoxide # habitual `cd`

    # Requires a patched font
    # https://github.com/ryanoasis/nerd-fonts/blob/master/readme.md#patched-fonts
    lsd
    tree
    # better du alternative
    du-dust
    ripgrep
    graphviz
    git-crypt

    httpstat
    curlie


    pkgsUnstable.yt-dlp
    speedtest-cli

    # https://github.com/sindresorhus/fkill
    nodePackages.fkill-cli
    # nodePackages.pnpm

    pkgsUnstable.bun

    # NOTE `nodejs` is installed on various machines separately, as a specific version is needed for remote VSC
    # TODO figure out how to install a specific version of nodejs only for VSC
    # nodejs # Node 18
    # (yarn.override { nodejs = nodejs-18_x; })


    python39
    xh # httpie alternative / https://github.com/ducaale/xh
    jq
    go
    cloc
    docker
    pkgsUnstable.tailscale

    caddy # quick local webserver

    # compression
    zip
    pigz # parallel gzip
    lz4

    # Nix VSC
    nil
    nixpkgs-fmt
    # needed for headless chrome
    # chromium

    git
    # github cli
    gitAndTools.gh

  ] ++ lib.optionals stdenv.isDarwin [
    coreutils # provides `dd` with --status=progress
    wifi-password
  ] ++ lib.optionals stdenv.isLinux [
    iputils # provides `ping`, `ifconfig`, ...
    file
    lsof

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
