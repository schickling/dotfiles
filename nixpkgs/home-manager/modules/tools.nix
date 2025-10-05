{ config, lib, pkgs, ... }:
{
  # GitHub CLI (gh)
  # Manages non-secret settings (config.yml) only. Do NOT manage hosts.yml
  # because it contains tokens; let `gh auth login` create/maintain it locally.
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "nvim";
      prompt = "enabled";
      aliases = { co = "pr checkout"; };
    };
  };

  # Ghostty
  # Provision config via XDG with inline content (no repo read).
  # If your Home Manager channel later provides `programs.ghostty`, prefer that.
  xdg.configFile."ghostty/config".text = ''
    # Ghostty theme
    theme = Catppuccin Macchiato

    # Font family
    font-family = JetBrains Mono
    font-style = Regular
    font-style-italic = Regular Italic
    font-style-bold = Bold
    font-style-bold-italic = Bold Italic

    # Font size
    font-size = 13

    # Opacity of split windows
    unfocused-split-opacity = 0.97  

    # Set the background-opacity to be fully opaque
    background-opacity = 1.0

    # Cursor style
    # cursor-style-blink = true
    cursor-style = bar

    # Clipboard settings
    clipboard-read = allow
    clipboard-write = allow

    # Allow option to work as alt on macos
    macos-option-as-alt = true

    # Window settings
    window-colorspace = display-p3
    window-padding-color = background
    window-padding-balance = true
    window-padding-x = 5
    window-padding-y = 5

    # Unbind CMD+... keys so they will be forwarded to Zellij
    # keybind = cmd+t=unbind
    # keybind = cmd+n=unbind
    # keybind = cmd+c=unbind
    # keybind = cmd+w=unbind
    # keybind = cmd+opt+left=unbind
    # keybind = cmd+opt+right=unbind
    # keybind = cmd+1=unbind
    # keybind = cmd+2=unbind
    # keybind = cmd+3=unbind
    # keybind = cmd+4=unbind
    # keybind = cmd+5=unbind
    # keybind = cmd+6=unbind
    # keybind = cmd+7=unbind
    # keybind = cmd+8=unbind
    # keybind = cmd+9=unbind
  '';


  # lsd (ls deluxe)
  # Modern config schema requires structured values for color/icons.
  programs.lsd = {
    enable = true;
    settings = {
      color = {
        when = "auto";
        theme = "default";
      };
      icons = {
        when = "auto";
        theme = "fancy";
        separator = " ";
      };
      sorting = { "dir-grouping" = "first"; };
    };
  };

  # bat
  # Compact theme + style; adjust to preference.
  programs.bat = {
    enable = true;
    config = {
      theme = "Monokai Extended";
      # Minimal styling; adjust to preference (e.g., "full")
      style = "plain";
    };
  };

  # ripgrep
  # Sensible defaults: search hidden files, smart case, skip .git.
  programs.ripgrep = {
    enable = true;
    arguments = [
      "--hidden"
      "--smart-case"
      "--glob" "!.git"
    ];
  };
}
