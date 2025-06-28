{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";
    nixpkgsUnstable.url = "github:NixOS/nixpkgs/master";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server.url = "github:msteen/nixos-vscode-server";
    darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, flake-utils, darwin, vscode-server, deploy-rs, nixpkgs, nixpkgsUnstable, home-manager }:
    let
      # Helper function to create pkgsUnstable with unfree predicate
      mkPkgsUnstable = system: import inputs.nixpkgsUnstable {
        inherit system;
        config.allowUnfreePredicate = pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) [ "1password" "1password-cli" "claude-code" ];
      };

      # Helper function for home-manager configurations
      mkHomeManagerConfig = { system, modules }: inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        inherit modules;
        extraSpecialArgs = { 
          pkgsUnstable = mkPkgsUnstable system;
        };
      };

      # Helper function for Darwin system configurations
      mkDarwinConfig = { system, configPath, homeManagerPath }: darwin.lib.darwinSystem {
        inherit system;
        modules = [
          configPath
          ./nixpkgs/darwin/remote-builder.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.schickling = import homeManagerPath;
            home-manager.extraSpecialArgs = { 
              inherit nixpkgs; 
              pkgsUnstable = mkPkgsUnstable system;
            };
          }
        ];
        inputs = { inherit darwin nixpkgs; };
      };

      # Helper function for NixOS configurations
      mkNixosConfig = { system, configPath, homeManagerPath ? null, userName ? "schickling", extraModules ? [] }: inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          common = self.common;
          pkgsUnstable = mkPkgsUnstable system;
          inherit inputs;
        };
        modules = [
          ({ config = { nix.registry.nixpkgs.flake = nixpkgs; }; })
          configPath
        ] ++ extraModules ++ (if homeManagerPath != null then [
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { 
              pkgsUnstable = mkPkgsUnstable system;
            };
            home-manager.users.${userName} = import homeManagerPath;
          }
        ] else []);
      };
    in

    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {

          # nix develop
          # home-manager switch --flake .#mbp2020
          devShells = {
            default = with pkgs; mkShell {
              buildInputs = [
                pkgs.home-manager
                pkgs.nixos-rebuild # needed for remote deploys on macOS
              ];
            };
          };

        })
    // # <- concatenates Nix attribute sets
    {
      # TODO re-enable cachix across hosts

      homeConfigurations = {
        mbp2025 = mkHomeManagerConfig {
          system = "aarch64-darwin";
          modules = [ ./nixpkgs/home-manager/mbp2025.nix ];
        };

        mbp2021 = mkHomeManagerConfig {
          system = "aarch64-darwin";
          modules = [ ./nixpkgs/home-manager/mbp2021.nix ];
        };

        mbp2020 = mkHomeManagerConfig {
          system = "x86_64-darwin";
          modules = [ ./nixpkgs/home-manager/mbp2020.nix ];
        };

        mini2020 = mkHomeManagerConfig {
          system = "aarch64-darwin";
          modules = [ ./nixpkgs/home-manager/mini2020.nix ];
        };

        dev2 = mkHomeManagerConfig {
          system = "x86_64-linux";
          modules = [ ./nixpkgs/home-manager/dev2.nix ];
        };

        homepi = mkHomeManagerConfig {
          system = "aarch64-linux";
          modules = [ ./nixpkgs/home-manager/homepi.nix ];
        };

        gitpod = mkHomeManagerConfig {
          system = "x86_64-linux";
          modules = [ ./nixpkgs/home-manager/gitpod.nix ];
        };
      };

      # Apply by running `nix build .#darwinConfigurations.mbp2025.system; ./result/sw/bin/darwin-rebuild switch --flake .;`
      darwinConfigurations = {
        mbp2025 = mkDarwinConfig {
          system = "aarch64-darwin";
          configPath = ./nixpkgs/darwin/mbp2025/configuration.nix;
          homeManagerPath = ./nixpkgs/home-manager/mbp2025.nix;
        };

        mbp2021 = mkDarwinConfig {
          system = "aarch64-darwin";
          configPath = ./nixpkgs/darwin/mbp2021/configuration.nix;
          homeManagerPath = ./nixpkgs/home-manager/mbp2021.nix;
        };

        mbp2020 = mkDarwinConfig {
          system = "x86_64-darwin";
          configPath = ./nixpkgs/darwin/mbp2020/configuration.nix;
          homeManagerPath = ./nixpkgs/home-manager/mbp2020.nix;
        };

        mini2020 = mkDarwinConfig {
          system = "aarch64-darwin";
          configPath = ./nixpkgs/darwin/mini2020/configuration.nix;
          homeManagerPath = ./nixpkgs/home-manager/mini2020.nix;
        };
      };

      nixosConfigurations = {
        dev2 = mkNixosConfig {
          system = "x86_64-linux";
          configPath = ./nixpkgs/nixos/dev2/configuration.nix;
          homeManagerPath = ./nixpkgs/home-manager/dev2.nix;
          extraModules = [ vscode-server.nixosModule ];
        };

        nix-builder = mkNixosConfig {
          system = "aarch64-linux";
          configPath = ./nixpkgs/nixos/nix-builder/configuration.nix;
          homeManagerPath = ./nixpkgs/home-manager/nix-builder.nix;
          userName = "root";
        };

        homepi = mkNixosConfig {
          system = "aarch64-linux";
          configPath = ./nixpkgs/nixos/homepi/configuration.nix;
          homeManagerPath = ./nixpkgs/home-manager/homepi.nix;
          extraModules = [ vscode-server.nixosModule ];
        };
      };

      images = {
        # nix build .#images.homepi
        homepi = self.nixosConfigurations.homepi.config.system.build.sdImage;
      };

      deploy.nodes = {
        homepi = {
          # hostname = "192.168.1.8"; # local ip
          hostname = "homepi";
          profiles.system = {
            sshUser = "root";
            path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.homepi;
          };
        };

        dev2 = {
          hostname = "dev2";
          profiles.system = {
            sshUser = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.dev2;
          };
        };

        # NOTE this machine is currently dead
        nix-builder = {
          hostname = "nix-builder";
          profiles.system = {
            sshUser = "root";
            path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.nix-builder;
          };
        };
      };

      # checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

      common = {
        sshKeys = [
          "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLXMVzwr9BKB67NmxYDxedZC64/qWU6IvfTTh4HDdLaJe18NgmXh7mofkWjBtIy+2KJMMlB4uBRH4fwKviLXsSM= MBP2020@secretive.MacBook-Pro-Johannes.local"
          "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBM7UIxnOjfmhXMzEDA1Z6WxjUllTYpxUyZvNFpS83uwKj+eSNuih6IAsN4QAIs9h4qOHuMKeTJqanXEanFmFjG0= MM2021@secretive.Johannes’s-Mac-mini.local"
          "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPkfRqtIP8Lc7qBlJO1CsBeb+OEZN87X+ZGGTfNFf8V588Dh/lgv7WEZ4O67hfHjHCNV8ZafsgYNxffi8bih+1Q= MBP2021@secretive.Johannes’s-MacBook-Pro.local"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBY2vg6JN45hpcl9HH279/ityPEGGOrDjY3KdyulOUmX 1Password SSH"
        ];
      };
    };
}
