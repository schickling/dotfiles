{ config, lib, pkgs, ... }:

{

  # Inspired by https://romanzipp.com/blog/ghostty-zellij-fish-shell
  programs.zellij = {
    enable = true;
    # enableFishIntegration = true;
  };

  # Install the plugin
  home.file.".config/zellij/plugins/auto-tabname.wasm".source = ./zellij-auto-tabname/auto-tabname.wasm;
  
  # Create plugin permission cache to auto-grant permissions
  home.file.".cache/zellij/permission_cache".text = ''
    {
      "/Users/schickling/.config/zellij/plugins/auto-tabname.wasm": {
        "ReadApplicationState": true,
        "ChangeApplicationState": true
      }
    }
  '';

  # Create layout with plugin + built-in tab-bar
  xdg.configFile."zellij/layouts/default.kdl".text = ''
    layout {
      default_tab_template {
        // Our plugin (1 line, invisible)
        pane size=1 borderless=true {
          plugin location="file:${config.home.homeDirectory}/.config/zellij/plugins/auto-tabname.wasm"
        }
        // CRITICAL: Add the built-in tab-bar plugin
        pane size=1 borderless=true {
          plugin location="zellij:tab-bar"
        }
        children
      }
      
      tab name="Main" focus=true
    }
  '';

  xdg.configFile."zellij/config.kdl".text = ''
    theme "catppuccin-macchiato"
    
    // Load the default layout
    default_layout "default"

    keybinds {
      normal {
        bind "Super c" { Copy; }
        bind "Super Alt Left" { GoToPreviousTab; }
        bind "Super Alt Right" { GoToNextTab; }
        bind "Super w" { CloseTab; }
        bind "Super n" { NewTab; }
        bind "Super t" { NewTab; }
        bind "Super \\" { NewPane "Right"; }
        bind "Super 1" { GoToTab 1; }
        bind "Super 2" { GoToTab 2; }
        bind "Super 3" { GoToTab 3; }
        bind "Super 4" { GoToTab 4; }
        bind "Super 5" { GoToTab 5; }
        bind "Super 6" { GoToTab 6; }
        bind "Super 7" { GoToTab 7; }
        bind "Super 8" { GoToTab 8; }
        bind "Super 9" { GoToTab 9; }
      }
    }
  '';
}
