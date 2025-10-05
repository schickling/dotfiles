{ config, lib, pkgs, ... }:

/*
  Home Manager module: Zellij Web (browser access to sessions)

  Nix-idiomatic configuration with HM options under `services.zellijWeb`.
  - Starts a user-level systemd service on login
  - Binds on 127.0.0.1 by default (reverse-proxied via Caddy/Tailscale)
*/

let
  inherit (lib) mkIf mkOption types;
  cfg = config.services.zellijWeb;
in
{
  options.services.zellijWeb = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable the Zellij Web server user service.";
    };

    ip = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Bind address for the Zellij Web server (use 127.0.0.1 when reverse-proxying).";
    };

    port = mkOption {
      type = types.port;
      default = 8082;
      description = "Port for the Zellij Web server.";
    };

    # TLS is terminated by Caddy; Zellij listens on localhost HTTP only.
  };

  config = mkIf cfg.enable {
    systemd.user.services.zellij-web = {
      Unit = {
        Description = "Zellij Web (browser access to sessions)";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = ''${pkgs.zellij}/bin/zellij web --start --ip ${lib.escapeShellArg cfg.ip} --port ${toString cfg.port}'';
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
