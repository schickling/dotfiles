{ config, pkgs, lib, libs, ... }:
{
  programs.ssh = {

    enable = true;
    enableDefaultConfig = false;

    # https://github.com/nix-community/home-manager/blob/master/modules/programs/ssh.nix
    matchBlocks = {
      "*" = {
        controlMaster = "auto";
        controlPersist = "8760h";
        controlPath = "~/.ssh/sockets/%r@%h-%p";
        extraOptions = {
          # https://man7.org/linux/man-pages/man5/sshd_config.5.html#:~:text=domain%20socket%20files.-,StreamLocalBindUnlink,-Specifies%20whether%20to
          StreamLocalBindUnlink = "yes";
        };
      };




      "homepi-root" = {
        hostname = "homepi";
        user = "root";
        forwardAgent = true;
      };

      "homepi" = {
        hostname = "homepi";
        user = "schickling";
        forwardAgent = true;
      };

      "pimuseum1" = {
        hostname = "pimuseum1";
        user = "pi";
        forwardAgent = true;
      };

      "pimuseum2" = {
        hostname = "pimuseum2";
        user = "pi";
        forwardAgent = true;
      };

      "mini2020" = {
        hostname = "mini2020";
        user = "schickling";
        forwardAgent = true;
      };

      # dev2 removed

      # Force 1Password SSH key usage (dev3 resolves via Tailscale which can interfere with key selection)
      "dev3" = {
        hostname = "dev3";
        user = "schickling";
        forwardAgent = true;
        identitiesOnly = true;
        extraOptions = {
          IdentityAgent = "~/.1password/agent.sock";
        };
      };

      # Same 1Password SSH key enforcement for root access
      "dev3-root" = {
        hostname = "dev3";
        user = "root";
        forwardAgent = true;
        identitiesOnly = true;
        extraOptions = {
          IdentityAgent = "~/.1password/agent.sock";
        };
      };

      # MacBook over Tailscale (MagicDNS)
      "mbp2025" = {
        hostname = "mbp2025";
        user = "schickling";
        identitiesOnly = true;
        extraOptions = {
          IdentityAgent = "~/.1password/agent.sock";
        };
      };

    };
  };
}
