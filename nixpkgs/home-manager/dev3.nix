{ config, lib, pkgs, ... }:

{
  imports = [
    ./modules/linux-common.nix
  ];

  # Browser dependencies for Playwright
  home.packages = with pkgs; [
    playwright-test
  ];

  # Allow local HM eval to read files outside the store; system-wide restrict-eval stays enabled for CI/agents.
  home.file.".config/nix/nix.conf".text = ''
    restrict-eval = false
    allowed-uris = github: https://github.com/ https://cache.nixos.org/
  '';

  # Machine-specific overrides
  programs.fish.interactiveShellInit = lib.mkAfter ''
    # TODO: Check if this VSCode SSH workaround is still needed (see https://github.com/microsoft/vscode-remote-release/issues/6345#issuecomment-1570909663)
    set -x SSH_TTY /dev/pts/0
  '';
}
