{ config, pkgs, lib, pkgsUnstable, ... }:

{
  services.atticd = {
    enable = true;
    package = pkgsUnstable.attic-server;
    environmentFile = "/run/atticd/env";

    settings = {
      listen = "[::]:8081";

      storage = {
        type = "local";
        path = "/var/lib/atticd/storage";
      };

      database.url = "sqlite:///var/lib/atticd/server.db?mode=rwc";

      chunking = {
        nar-size-threshold = 64 * 1024;
        min-size = 16 * 1024;
        avg-size = 64 * 1024;
        max-size = 256 * 1024;
      };
    };
  };

  # Copy pre-placed secret from /run/keys to atticd's runtime dir before service starts
  # The secret file is provisioned via macOS 1Password CLI and placed at /run/keys/attic-jwt-secret
  systemd.services.atticd = {
    serviceConfig = {
      ExecStartPre = lib.mkBefore [
        "+${pkgs.writeShellScript "atticd-copy-secret" ''
          mkdir -p /run/atticd
          cp /run/keys/attic-jwt-secret /run/atticd/env
          chmod 600 /run/atticd/env
          chown atticd:atticd /run/atticd/env
        ''}"
      ];
    };
  };

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 8081 ];
}
