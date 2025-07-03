{ config, lib, pkgs, ... }:

let
  zellijAutoTabnamePlugin = (import ./flake.nix).outputs.packages.${pkgs.stdenv.system}.default;
in
{
  # Build and install the plugin
  home.file.".config/zellij/plugins/auto-tabname.wasm".source = "${zellijAutoTabnamePlugin}/zellij-auto-tabname.wasm";
}