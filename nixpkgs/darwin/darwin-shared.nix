{ pkgs, config, lib, ... }:
{
  options = {
    # Central source for authorized keys (populated from flake common.sshKeys)
    myAuthorizedKeys.sshKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of authorized public keys for user schickling";
    };
  };
  imports = [
    ./common.nix
    ./sdcard-autosave.nix
  ];

  config = {

  # Shared Darwin configuration for all machines
  #   Tailscale IPs so SSH is reachable exclusively over the tailnet.
  # - nix-darwin 25.05 does not expose a services.openssh module; defining a
  #   launchd daemon is the most direct, declarative way.
  launchd.daemons.sshd-nix = {
    # Provide a reasonable PATH for launchd service
    path = [ pkgs.coreutils pkgs.openssh pkgs.gnugrep pkgs.gnused ];
    serviceConfig = {
      Label = "dev.nix.sshd";
      ProgramArguments = [ "/usr/sbin/sshd" "-D" ];
      KeepAlive = true;
      RunAtLoad = true;
      ProcessType = "Interactive";
      StandardErrorPath = "/var/log/sshd-nix.err.log";
      StandardOutPath = "/var/log/sshd-nix.out.log";
    };
  };

  # Harden the system sshd configuration (used by /usr/sbin/sshd)
  # Notes:
  # - Key-only auth (no passwords, no interactive prompts).
  # - We do not bind sshd to specific addresses; we use PF rules to allow only Tailscale sources so the daemon
  #   does not listen on LAN or localhost at all. This is the simplest way to
  #   achieve "Tailscale-only" access without adding PF firewall rules.
  # - We intentionally avoid ListenAddress to prevent drift when Tailscale IPs rotate.
  environment.etc."ssh/sshd_config.d/10-nix.conf".text = ''
    PermitRootLogin no
    PasswordAuthentication no
    KbdInteractiveAuthentication no
    UseDNS no
    # Allow SSH agent forwarding so dev3 can forward its 1Password agent
    AllowAgentForwarding yes
    # AllowUsers schickling
  '';

  # Access control approach
  # - We intentionally use PF rules (below) to restrict SSH to Tailscale ranges,
  #   avoiding hard-coding device IPs that can change.
  # - Alternative future option: switch to the non-sandboxed Tailscale daemon
  #   and use Tailscale SSH (no sshd needed), controlled via tailnet ACLs.

  # Ensure SSH host keys exist before starting sshd. Without these, sshd exits
  # immediately with: "sshd: no hostkeys available -- exiting."
  system.activationScripts.ensureSshHostKeys.text = ''
    if [ ! -e /etc/ssh/ssh_host_ed25519_key ] || [ ! -e /etc/ssh/ssh_host_rsa_key ]; then
      echo "[nix-darwin] Generating missing SSH host keys..."
      /usr/bin/ssh-keygen -A || true
    fi
  '';

  # PF anchor to allow SSH only from Tailscale ranges, block others. This avoids
  # hard-coding per-device IPs that can change. Ranges are stable protocol-level:
  # - IPv4: 100.64.0.0/10 (CGNAT block used by Tailscale)
  # - IPv6: fd7a:115c:a1e0::/48 (Tailscale ULA prefix)
  environment.etc."pf.anchors/dev.tailscale_ssh".text = ''
    # Allow SSH from Tailscale
    table <tailscale_v4> persist { 100.64.0.0/10 }
    table <tailscale_v6> persist { fd7a:115c:a1e0::/48 }

    pass in quick inet proto tcp from <tailscale_v4> to (self) port 22 keep state
    pass in quick inet6 proto tcp from <tailscale_v6> to (self) port 22 keep state

    # Block everyone else from reaching sshd
    block in quick proto tcp to (self) port 22
  '';

  # LaunchDaemon to enable PF and load our anchor under the com.apple anchor path.
  # Using com.apple/* ensures our dynamically loaded anchor participates in the
  # default ruleset without modifying /etc/pf.conf.
  # We intentionally avoid ListenAddress to prevent drift when Tailscale IPs rotate.
  launchd.daemons.pf-tailssh = {
    path = [ pkgs.coreutils ];
    serviceConfig = {
      Label = "dev.nix.pf.tailssh";
      ProgramArguments = [ "/bin/sh" "-lc" ''/sbin/pfctl -E >/dev/null 2>&1 || true; /sbin/pfctl -a com.apple/500.TailscaleSSH -f /etc/pf.anchors/dev.tailscale_ssh'' ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardErrorPath = "/var/log/pf-tailssh.err.log";
      StandardOutPath = "/var/log/pf-tailssh.out.log";
    };
  };

  # Authorized keys for user 'schickling' via AuthorizedKeysCommand
  # Keep StrictModes enabled by avoiding symlinked ~/.ssh/authorized_keys.
  # Keys are sourced from flake's common.sshKeys via builders.nix.
  environment.etc."ssh/nix_authorized_keys.d/schickling".text =
    lib.concatStringsSep "\n" (config.myAuthorizedKeys.sshKeys ++ [""]);
  };
}

