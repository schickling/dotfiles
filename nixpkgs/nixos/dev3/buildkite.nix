{ pkgs, pkgsUnstable, config, self-signed-ca, lib, ... }:

let
  # Tokens are copied from the Buildkite UI to the paths below and must be chowned root:keys (g+r).
  # To restart agents manually: sudo systemctl restart buildkite-agent-overtone.service buildkite-agent-livestore.service
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
    docker
    pkgsUnstable.devenv
    # TODO also set up direnv shell hook (if possible)
    direnv
  ];
in
{
  # Buildkite agent requirements: allow needed URIs for flakes/caches and let agent users manage caches.
  nix.settings.allowed-uris = lib.mkAfter [
    "github:" # allow flake inputs from GitHub while keeping restricted eval on
    "https://github.com/"
    "https://cache.nixos.org/"
  ];
  nix.settings.trusted-users = lib.mkAfter [
    "schickling"
    "buildkite-agent-overtone"
    "buildkite-agent-livestore"
  ];

  services.buildkite-agents = builtins.mapAttrs (_: agent: {
    enable = true;
    inherit (agent) tags tokenPath;
    inherit runtimePackages;
    privateSshKeyPath = agent.privateSshKeyPath;

    # TODO set up `tracing-backend`
    # See https://buildkite.com/docs/agent/v3/configuration
    extraConfig = ''
      spawn=10
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
  systemd.services = lib.mapAttrs'
    (name: agent: {
      name = "buildkite-agent-${name}";
      value = {
        confinement.enable = true;
        confinement.packages = config.services.buildkite-agents.${name}.runtimePackages;
        serviceConfig = {
          BindReadOnlyPaths = [
            agent.tokenPath
            config.services.buildkite-agents.${name}.privateSshKeyPath
            agent.envFile
            "${config.environment.etc."ssl/certs/ca-certificates.crt".source}:/etc/ssl/certs/ca-certificates.crt"
            # Provide DNS configuration inside the confinement
            "/etc/resolv.conf"
            # Provide user/group database so git/ssh can resolve the agent uid/gid
            "/etc/passwd"
            "/etc/group"
            # Provide local host mappings (e.g., localhost)
            "/etc/hosts"
            # Provide /usr/bin/env for shebangs inside the confinement
            "${pkgs.coreutils}/bin/env:/usr/bin/env"
            "/etc/machine-id"
            "/nix/store"
          ];
          BindPaths = [
            config.services.buildkite-agents.${name}.dataDir
            "/nix/var/nix/daemon-socket/socket"
            # Needed so docker CLI inside jobs can talk to the host daemon
            "/var/run/docker.sock"
          ];
          # Let the agent user talk to docker without relaxing confinement
          SupplementaryGroups = [ "docker" ];
          # PrivateUsers remaps UIDs/GIDs and breaks access to the host docker.sock; disable to allow docker CLI.
          PrivateUsers = lib.mkForce false;
        };
      };
    })
    agents;

}
