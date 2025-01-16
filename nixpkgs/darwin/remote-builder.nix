{ pkgs, config, lib, ... }:
let 
  rootSSHConfig = pkgs.writeText "root-ssh-config" ''
    Host dev2
      ForwardAgent yes
      HostName dev2
      StrictHostKeyChecking=accept-new
      User root
      IdentitiesOnly yes
      IdentityFile /var/root/.ssh/nix-remote-builder/dev2
  '';
in
{

  nix = {
    buildMachines = lib.filter (x: x.hostName != config.networking.hostName) [
      {
        # requires `boot.binfmt.emulatedSystems = [ "aarch64-linux" ];` in dev2's configuration.nix
        systems = [ "aarch64-linux" "x86_64-linux" ];
        sshUser = "root";
        maxJobs = 4;
        hostName = "dev2";
        supportedFeatures = [ "nixos-test" "benchmark" "kvm" "big-parallel" ];
      }
    ];
    distributedBuilds = config.nix.buildMachines != [ ];
  };

  # Root SSH config (setup needed for Nix remote builders)
  # system.activationScripts.extraActivation.text = ''
  #   mkdir -m 0700 -p /var/root/.ssh
  #   cp ${rootSSHConfig} /var/root/.ssh/config
  #   chmod 0600 /var/root/.ssh/config
  #   chown -R 0:0 /var/root/.ssh
  # '';
}