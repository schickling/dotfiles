{ config, lib, pkgs, ... }:
{
  # pnpm configuration via home-manager
  xdg.configFile."pnpm/rc".text = ''
    # Enable global virtual store for better disk space efficiency
    # This creates a single global store that all projects share
    # enable-global-virtual-store=true
    # TODO re-enable when fixed github.com/pnpm/pnpm/issues/9739
    enable-global-virtual-store=false
  '';
}
