{ pkgs, self-signed-ca, ... }:
{
  services = {
    buildkite-agents.agent = {
      enable = true;
      tags = {
        os = "nixos";
        nix = "true";
      };
      # token copied from Buildkite UI to `/run/keys/buildkite-agent-token` and `sudo chown root:keys /run/keys/buildkite-agent-token`
      tokenPath = "/run/keys/buildkite-agent-token";
      # manually set up via 
      # ```
      # sudo su
      # mkdir -p /run/keys/overtonebot-ssh-key
      # ssh-keygen -t rsa -b 4096 -f /run/keys/overtonebot-ssh-key/id_rsa -N ""
      # chown -R root:keys /run/keys/overtonebot-ssh-key
      # chmod g+r /run/keys/overtonebot-ssh-key/id_rsa
      # ```
      # needs to be added to GitHub (either as a deploy key or personal key)
      # `journalctl -u buildkite-agent-agent.service` to see logs
      privateSshKeyPath = "/run/keys/overtonebot-ssh-key/id_rsa";
      runtimePackages = with pkgs; [
        bash
        curl
        gcc
        gnutar
        gzip
        ncurses
        nix
        # TODO also set up direnv shell hook (if possible)
        direnv
      ];

      # TODO set up `tracing-backend`
      # See https://buildkite.com/docs/agent/v3/configuration
      extraConfig = ''
        spawn=5
      '';

      hooks.environment = ''
        export NIX_PATH="nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"

        export CAROOT="${self-signed-ca}"

        if test -f /secrets/buildkite.sh; then
          source /secrets/buildkite.sh
        fi
      '';
    };

  };

}
