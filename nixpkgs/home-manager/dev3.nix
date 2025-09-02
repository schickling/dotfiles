{ config, lib, pkgs, ... }:

{
  imports = [
    ./modules/linux-common.nix
  ];

  # Machine-specific overrides
  programs.fish.interactiveShellInit = lib.mkAfter ''
    # TODO: Check if this VSCode SSH workaround is still needed (see https://github.com/microsoft/vscode-remote-release/issues/6345#issuecomment-1570909663)
    set -x SSH_TTY /dev/pts/0
  '';
}
