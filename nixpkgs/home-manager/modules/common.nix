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
    fzf
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


    pkgsUnstable.youtube-dl
    speedtest-cli

    # https://github.com/sindresorhus/fkill
    nodePackages.fkill-cli
    nodePackages.pnpm

    # NOTE `nodejs` is installed on various machines separately, as a specific version is needed for remote VSC
    # TODO figure out how to install a specific version of nodejs only for VSC
    # nodejs # Node 18
    # (yarn.override { nodejs = nodejs-18_x; })

    # https://github.com/mozilla/sops
    sops # secrets management

    python38
    jq
    go
    cloc
    docker
    pkgsUnstable.tailscale

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
    wifi-password
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

  # https://wiki.archlinux.org/title/XDG_Base_Directory
  xdg = {
    enable = true;
    configHome = "${config.home.homeDirectory}/.config";
    cacheHome = "${config.home.homeDirectory}/.cache";
    dataHome = "${config.home.homeDirectory}/.local/share";
    stateHome = "${config.home.homeDirectory}/.local/state";
  };

}
