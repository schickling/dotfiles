{ pkgs, pkgsUnstable, config, self-signed-ca, ... }:

let
  # Tokens are copied from the Buildkite UI to the paths below and must be chowned root:keys (g+r).
  agents = {
    overtone = {
      tokenPath = "/run/keys/buildkite-overtone-token";
      envFile = "/run/keys/buildkite-overtone-env";
      # Generated on dev3 (not in git):
      # sudo ssh-keygen -t ed25519 -N '' -f /run/keys/buildkite-overtone-ssh/id_rsa
      # sudo chown -R root:keys /run/keys/buildkite-overtone-ssh && sudo chmod 640 /run/keys/buildkite-overtone-ssh/id_rsa
      privateSshKeyPath = "/run/keys/buildkite-overtone-ssh/id_rsa";
      tags = {
        os = "nixos";
        nix = "true";
        pipeline = "overtone";
      };
    };
    livestore = {
      tokenPath = "/run/keys/buildkite-livestore-token";
      envFile = "/run/keys/buildkite-livestore-env";
      # Generated on dev3 (not in git):
      # sudo ssh-keygen -t ed25519 -N '' -f /run/keys/buildkite-livestore-ssh/id_rsa
      # sudo chown -R root:keys /run/keys/buildkite-livestore-ssh && sudo chmod 640 /run/keys/buildkite-livestore-ssh/id_rsa
      privateSshKeyPath = "/run/keys/buildkite-livestore-ssh/id_rsa";
      tags = {
        os = "nixos";
        nix = "true";
        pipeline = "livestore";
      };
    };
  };

  runtimePackages = with pkgs; [
    bash
    curl
    gcc
    gnutar
    gzip
    ncurses
    nix
    pkgsUnstable.devenv
    # TODO also set up direnv shell hook (if possible)
    direnv
  ];
in
{
  services.buildkite-agents = builtins.mapAttrs (_: agent: {
    enable = true;
    inherit (agent) tags tokenPath;
    inherit runtimePackages;
    privateSshKeyPath = agent.privateSshKeyPath;

    # TODO set up `tracing-backend`
    # See https://buildkite.com/docs/agent/v3/configuration
    extraConfig = ''
      spawn=5
    '';

    hooks.environment = ''
      export NIX_PATH="nixpkgs=${pkgs.path}"

      export CAROOT="${self-signed-ca}"

      # Keep normal branches/tags; drop PRs
      # This helps in submodule scenarios (e.g. Overtone <> LiveStore) where certain submodule branches were deleted
      export BUILDKITE_GIT_FETCH_FLAGS="-v --prune"

      if test -f ${agent.envFile}; then
        # shellcheck disable=SC1091
        source ${agent.envFile}
      fi
    '';

    hooks.pre-checkout = ''
      #!/usr/bin/env bash
      set -euo pipefail
      # Normalize ownership so git clean/checkout cannot fail on root-owned artifacts (e.g. wa-sqlite dist).
      chown -R "$BUILDKITE_AGENT_NAME":"$BUILDKITE_AGENT_NAME" "$BUILDKITE_BUILD_CHECKOUT_PATH" 2>/dev/null || true
      chmod -R u+w "$BUILDKITE_BUILD_CHECKOUT_PATH" 2>/dev/null || true
    '';
  }) agents;

  # Run each agent inside a confined chroot; only the Nix store, daemon socket,
  # data dir and credentials are mounted (read-only where possible).
  # Source: https://nixos.wiki/wiki/Buildkite
  systemd.services = builtins.mapAttrs
    (name: agent: {
      confinement.enable = true;
      confinement.packages = config.services.buildkite-agents.${name}.runtimePackages;
      serviceConfig = {
        BindReadOnlyPaths = [
          agent.tokenPath
          config.services.buildkite-agents.${name}.privateSshKeyPath
          agent.envFile
          "${config.environment.etc."ssl/certs/ca-certificates.crt".source}:/etc/ssl/certs/ca-certificates.crt"
          "/etc/machine-id"
          "/nix/store"
        ];
        BindPaths = [
          config.services.buildkite-agents.${name}.dataDir
          "/nix/var/nix/daemon-socket/socket"
        ];
      };
    })
    agents;

}
