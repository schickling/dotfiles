{ config, pkgs, pkgsUnstable, lib, amp, codex, opencode, oi, op-secret-cache, ... }:
let
  hostSystem = pkgs.stdenv.hostPlatform.system;
in
{

  # https://github.com/nix-community/nix-direnv#via-home-manager
  programs.direnv = {
    enable = true;
    package = pkgsUnstable.direnv;
    nix-direnv.enable = true;
  };

  home.packages = with pkgs; [
    fish
    gnupg
    tmux
    wget
    eternal-terminal
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
    glow # nice markdown reader
    zoxide # habitual `cd`

    # Requires a patched font
    # https://github.com/ryanoasis/nerd-fonts/blob/master/readme.md#patched-fonts
    lsd
    tree
    # better du alternative
    dust
    ripgrep
    graphviz

    ollama

    pkgsUnstable.claude-code
  ] ++ lib.optionals (hostSystem != "aarch64-linux") [
    # AI coding tools - skip on aarch64-linux due to cross-compilation issues
    amp.packages.${hostSystem}.default
    codex.packages.${hostSystem}.default
    opencode.packages.${hostSystem}.default
    oi.packages.${hostSystem}.default
    # 1Password secret cache - skip on aarch64-linux due to cross-compilation issues
    op-secret-cache.packages.${hostSystem}.default
  ] ++ [

    httpstat
    curlie


    pkgsUnstable.yt-dlp
    speedtest-cli

    # https://github.com/sindresorhus/fkill
    nodePackages.fkill-cli
    # nodePackages.pnpm

    pkgsUnstable.bun
    pkgsUnstable.biome
    # TODO: Revert to stable nodejs_24 once https://github.com/NixOS/nixpkgs/issues/423244 is fixed
    # (nodejs_24 fails to build on Darwin with sandbox enabled)
    pkgsUnstable.nodejs_24

    # NOTE `nodejs` is installed on various machines separately, as a specific version is needed for remote VSC
    # TODO figure out how to install a specific version of nodejs only for VSC
    # nodejs # Node 18

    python314
    pkgsUnstable.uv
    xh # httpie alternative / https://github.com/ducaale/xh
    jq
    go
    cloc
    docker
    pkgsUnstable.devenv
    process-compose

    pkgsUnstable.tailscale

    caddy # quick local webserver

    # compression
    zip
    unzip
    pigz # parallel gzip
    lz4

    # Nix VSC
    nil
    nixpkgs-fmt
    # needed for headless chrome
    # chromium

    git
    # github cli
    gh
    jujutsu

  ] ++ lib.optionals stdenv.isDarwin [
    coreutils # provides `dd` with --status=progress

    pinentry_mac # needed for GPG (get rid of this soon)
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

  # Disable HM manpages to avoid the upstream options.json builtins.toFile warning; re-enable once fixed or if we need `man home-configuration.nix` again. https://github.com/nix-community/home-manager/issues/7935
  manual.manpages.enable = false;

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      "true-color" = "always";
      side-by-side = true;
      # Delta assumes a light palette otherwise and the colors wash out in dark terminals.
      dark = true;
    };
  };

  # Make npm use XDG-configured user config file
  home.sessionVariables = {
    NPM_CONFIG_USERCONFIG = "${config.home.homeDirectory}/.config/npm/npmrc";
  };

}
