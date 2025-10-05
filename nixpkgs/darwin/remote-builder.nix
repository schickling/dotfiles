{ pkgs, config, lib, ... }:
{

  nix = {
    # Use dev3 as the remote builder. Filter out self to avoid recursion
    # when this module is used on the builder itself.
    buildMachines = lib.filter (x: x.hostName != config.networking.hostName) [
      {
        # dev3 supports cross builds via binfmt (aarch64-linux) and native x86_64-linux
        systems = [ "aarch64-linux" "x86_64-linux" ];
        sshUser = "root";
        maxJobs = 4;
        hostName = "dev3";
        supportedFeatures = [ "nixos-test" "benchmark" "kvm" "big-parallel" ];
      }
    ];
    distributedBuilds = config.nix.buildMachines != [ ];
  };

}
