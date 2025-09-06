{ inputs }:

let
  # Centralized list of allowed unfree packages
  allowedUnfreePackages = [ "1password" "1password-cli" "claude-code" ];
  
  # Helper function to create unfree predicate
  mkUnfreePredicate = lib: pkg: builtins.elem (lib.getName pkg) allowedUnfreePackages;
  
  # Helper function to create pkgs with unfree predicate
  mkPkgs = system: import inputs.nixpkgs {
    inherit system;
    config.allowUnfreePredicate = mkUnfreePredicate inputs.nixpkgs.lib;
  };
  
  # Helper function to create pkgsUnstable with unfree predicate
  mkPkgsUnstable = system: import inputs.nixpkgsUnstable {
    inherit system;
    config.allowUnfreePredicate = mkUnfreePredicate inputs.nixpkgs.lib;
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
      inherit (inputs) vibetunnel codex;
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
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.schickling = import homeManagerPath;
        home-manager.extraSpecialArgs = { 
          inherit (inputs) nixpkgs vibetunnel codex; 
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
          inherit (inputs) vibetunnel codex;
        };
        home-manager.users.${userName} = import homeManagerPath;
      }
    ] else []);
  };
} 