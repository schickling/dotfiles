{ config, lib, pkgs, ... }:
{
  xdg.configFile."lazygit/config.yml".text = ''
    git:
      paging:
        colorArg: always
        pager: delta --paging=never --line-numbers --syntax-theme="Monokai Extended" --true-color=always
        useConfig: false
  '';
}