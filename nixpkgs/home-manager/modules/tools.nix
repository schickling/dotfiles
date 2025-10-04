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
  # Provision config via XDG. Source-of-truth is the repo file.
  # If your Home Manager channel later provides `programs.ghostty`, prefer that.
  xdg.configFile."ghostty/config".text = builtins.readFile ../../../ghostty/config;

  # lsd (ls deluxe)
  # Minimal, portable defaults for icons/colors/sorting.
  programs.lsd = {
    enable = true;
    settings = {
      icons = "auto";
      color = "auto";
      sorting = { dir_grouping = "first"; };
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
