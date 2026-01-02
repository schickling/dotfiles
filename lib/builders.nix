{ inputs }:

let
  # Centralized list of allowed unfree packages
  allowedUnfreePackages = [ "1password" "1password-cli" "claude-code" "amp" ];

  # Helper function to create unfree predicate
  mkUnfreePredicate = lib: pkg: builtins.elem (lib.getName pkg) allowedUnfreePackages;

  # Overlay to fix packages that fail to build under binfmt/QEMU emulation
  binfmtFixesOverlay = final: prev: {
    # Fish tests fail on aarch64-linux when built via binfmt/QEMU emulation on x86_64.
    # Timing-sensitive pexpect tests (torn_escapes.py, noshebang.fish) fail under QEMU.
    # Tracking issue: https://github.com/NixOS/nixpkgs/issues/475953
    # Remove this overlay once the issue is closed.
    fish = prev.fish.overrideAttrs (old: {
      doCheck = false;
    });
  };

  # Helper function to create pkgs with unfree predicate
  mkPkgs = system: import inputs.nixpkgs {
    inherit system;
    config.allowUnfreePredicate = mkUnfreePredicate inputs.nixpkgs.lib;
    overlays = [ binfmtFixesOverlay ];
  };

  # Helper function to create pkgsUnstable with unfree predicate
  mkPkgsUnstable = system: import inputs.nixpkgsUnstable {
    inherit system;
    config.allowUnfreePredicate = mkUnfreePredicate inputs.nixpkgs.lib;
    overlays = [ binfmtFixesOverlay ];
  };
in
{
  inherit allowedUnfreePackages mkUnfreePredicate mkPkgs mkPkgsUnstable;

  # Helper function for home-manager configurations
  mkHomeManagerConfig = { system, modules }: inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = mkPkgs system;
    inherit modules;
    extraSpecialArgs = {
      pkgsUnstable = mkPkgsUnstable system;
      inherit (inputs) vibetunnel amp codex opencode oi op-secret-cache;
    };
  };

  # Helper function for Darwin system configurations
  mkDarwinConfig = { system, configPath, homeManagerPath }: inputs.darwin.lib.darwinSystem {
    inherit system;
    specialArgs = {
      pkgsUnstable = mkPkgsUnstable system;
    };
    modules = [
      configPath
      ../nixpkgs/darwin/remote-builder.nix
      inputs.home-manager.darwinModules.home-manager
      {
        myAuthorizedKeys.sshKeys = inputs.self.common.sshKeys;
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.schickling = import homeManagerPath;
        home-manager.extraSpecialArgs = {
          inherit (inputs) nixpkgs vibetunnel amp codex opencode oi op-secret-cache;
          pkgsUnstable = mkPkgsUnstable system;
        };
      }
    ];
    inputs = { inherit (inputs) darwin nixpkgs; };
  };

  # Helper function for NixOS configurations
  mkNixosConfig = { system, configPath, homeManagerPath ? null, userName ? "schickling", extraModules ? [], commonConfig }: inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = {
      common = commonConfig;
      pkgsUnstable = mkPkgsUnstable system;
      inherit inputs;
    };
    modules = [
      ({ config = { nix.registry.nixpkgs.flake = inputs.nixpkgs; }; })
      configPath
    ] ++ extraModules ++ (if homeManagerPath != null then [
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "backup";
        home-manager.extraSpecialArgs = {
          pkgsUnstable = mkPkgsUnstable system;
          inherit (inputs) vibetunnel amp codex opencode oi op-secret-cache;
        };
        home-manager.users.${userName} = import homeManagerPath;
      }
    ] else []);
  };
} 
