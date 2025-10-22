{ config, lib, pkgs, ... }:
{

  # Inspired by https://romanzipp.com/blog/ghostty-zellij-fish-shell
  programs.zellij = {
    enable = true;
    # enableFishIntegration = true;
  };

  # Provide a reusable layout for GWT worktrees.
  # It defines two tabs:
  # - Agent: runs Codex with elevated permissions
  # - Git: two panes, left Claude (all permissions) and right LazyGit
  xdg.configFile."zellij/layouts/gwt-worktree.kdl".text = ''
    // GWT worktree layout
    // - Tab 1 (Agent): runs Codex with full permissions
    // - Tab 2 (Git): vertical split → left Claude (all permissions), right LazyGit
    // Includes tab/status bars (via default_tab_template) so tabs remain visible.
    layout {
      // Provide a standard tab scaffolding with tab-bar + status-bar
      default_tab_template {
        pane size=1 borderless=true {
          plugin location="zellij:tab-bar"
        }
        children
        pane size=2 borderless=true {
          plugin location="zellij:status-bar"
        }
      }

      tab name="Agent" {
        // Use fish -lc to evaluate aliases/direnv in a login-like shell context
        pane command="fish" {
          args "-lc" "codex --sandbox danger-full-access --config model_reasoning_effort=high --ask-for-approval never"
        }
      }

      tab name="Git" {
        // Vertical split: left Claude, right LazyGit
        pane split_direction="vertical" {
          pane command="fish" {
            args "-lc" "claude --dangerously-skip-permissions"
          }
          pane command="fish" {
            args "-lc" "lazygit --screen-mode half"
          }
        }
      }
    }
  '';

  xdg.configFile."zellij/config.kdl".text = ''
    theme "catppuccin-macchiato"

    show_startup_tips false

    // Ensure the web server is started so sessions can be shared when opted-in.
    // Note: we do NOT set a global default_layout; GWT invokes its layout explicitly.
    web_server true

    pane_frames false

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
