{ config, lib, pkgs, ... }:
{

  # Inspired by https://romanzipp.com/blog/ghostty-zellij-fish-shell
  programs.zellij = {
    enable = true;
    # enableFishIntegration = true;
  };

  xdg.configFile."zellij/config.kdl".text = ''
    theme "catppuccin-macchiato"

    keybinds {
      // stop ⌥→ from spawning a floating pane
      unbind "Alt f"

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
