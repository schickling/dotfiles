{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.05";
    nixpkgsUnstable.url = "github:NixOS/nixpkgs/master";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server.url = "github:msteen/nixos-vscode-server";
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, flake-utils, darwin, vscode-server, deploy-rs, nixpkgs, nixpkgsUnstable, home-manager }:


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
        mbp2021 = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
          modules = [ ./nixpkgs/home-manager/mbp2021.nix ];
          # extraModules = [ ./nixpkgs/home-manager/mac.nix ];
          extraSpecialArgs = { pkgsUnstable = inputs.nixpkgsUnstable.legacyPackages.aarch64-darwin; };
          # system = "aarch64-darwin";
          # configuration = { };
          # homeDirectory = "/home/schickling";
          # username = "schickling";
        };

        mbp2020 = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages.x86_64-darwin;
          modules = [ ./nixpkgs/home-manager/mbp2020.nix ];
          # extraModules = [ ./nixpkgs/home-manager/mac.nix ];
          extraSpecialArgs = { pkgsUnstable = inputs.nixpkgsUnstable.legacyPackages.x86_64-darwin; };
          # system = "aarch64-darwin";
          # configuration = { };
          # homeDirectory = "/home/schickling";
          # username = "schickling";
        };

        mini2020 = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
          modules = [ ./nixpkgs/home-manager/mini2020.nix ];
          # extraModules = [ ./nixpkgs/home-manager/mac.nix ];
          extraSpecialArgs = { pkgsUnstable = inputs.nixpkgsUnstable.legacyPackages.aarch64-darwin; };
          # system = "aarch64-darwin";
          # configuration = { };
          # homeDirectory = "/home/schickling";
          # username = "schickling";
        };

        dev2 = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
          modules = [ ./nixpkgs/home-manager/dev2.nix ];
          extraSpecialArgs = { pkgsUnstable = inputs.nixpkgsUnstable.legacyPackages.x86_64-linux; };
        };

        homepi = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages.aarch64-linux;
          modules = [ ./nixpkgs/home-manager/homepi.nix ];
          extraSpecialArgs = { pkgsUnstable = inputs.nixpkgsUnstable.legacyPackages.aarch64-linux; };
        };

        gitpod = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
          modules = [ ./nixpkgs/home-manager/gitpod.nix ];
          extraSpecialArgs = { pkgsUnstable = inputs.nixpkgsUnstable.legacyPackages.x86_64-linux; };
        };

      };

      darwinConfigurations = {
        # nix build .#darwinConfigurations.mbp2021.system
        # ./result/sw/bin/darwin-rebuild switch --flake .
        # also requires running `chsh -s /run/current-system/sw/bin/fish` once
        mbp2021 = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./nixpkgs/darwin/mbp2021/configuration.nix
            # ./nixpkgs/darwin/mbp2021/sdcard-autosave.nix
            ./nixpkgs/darwin/remote-builder.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.schickling = import ./nixpkgs/home-manager/mbp2021.nix;
              home-manager.extraSpecialArgs = { inherit nixpkgs; pkgsUnstable = inputs.nixpkgsUnstable.legacyPackages.aarch64-darwin; };
            }
          ];
          inputs = { inherit darwin nixpkgs; };
        };

        # nix build .#darwinConfigurations.mbp2020.system
        # ./result/sw/bin/darwin-rebuild switch --flake .
        # also requires running `chsh -s /run/current-system/sw/bin/fish` once
        mbp2020 = darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          modules = [
            ./nixpkgs/darwin/mbp2020/configuration.nix
            ./nixpkgs/darwin/remote-builder.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.schickling = import ./nixpkgs/home-manager/mbp2020.nix;
              home-manager.extraSpecialArgs = { inherit nixpkgs; pkgsUnstable = inputs.nixpkgsUnstable.legacyPackages.x86_64-darwin; };
            }
          ];
          inputs = { inherit darwin nixpkgs; };
        };

        # nix build .#darwinConfigurations.mini2020.system
        # ./result/sw/bin/darwin-rebuild switch --flake .
        # also requires running `chsh -s /run/current-system/sw/bin/fish` once
        mini2020 = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./nixpkgs/darwin/mini2020/configuration.nix
            ./nixpkgs/darwin/remote-builder.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.schickling = import ./nixpkgs/home-manager/mini2020.nix;
              home-manager.extraSpecialArgs = { inherit nixpkgs; pkgsUnstable = inputs.nixpkgsUnstable.legacyPackages.aarch64-darwin; };
            }
          ];
          inputs = { inherit darwin nixpkgs; };
        };
      };

      nixosConfigurations = {

        # On actual machine: sudo nixos-rebuild switch --flake .#dev2
        # On other machine: nix run github:serokell/deploy-rs .#dev2
        dev2 = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            common = self.common;
            pkgsUnstable = import inputs.nixpkgsUnstable {
              system = "x86_64-linux";
              config.allowUnfreePredicate = pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) [ "1password" "1password-cli" ];
            };
            inherit inputs;
          };
          modules = [
            ({ config = { nix.registry.nixpkgs.flake = nixpkgs; }; }) # Avoids nixpkgs checkout when running `nix run nixpkgs#hello`
            vscode-server.nixosModule
            ./nixpkgs/nixos/dev2/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = { pkgsUnstable = inputs.nixpkgsUnstable.legacyPackages.x86_64-linux; };
              # TODO load home-manager dotfiles also for root user
              home-manager.users.schickling = import ./nixpkgs/home-manager/dev2.nix;
            }
          ];
        };

        nix-builder = inputs.nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { common = self.common; pkgsUnstable = inputs.nixpkgsUnstable.legacyPackages.aarch64-linux; inherit inputs; };
          modules = [
            ({ config = { nix.registry.nixpkgs.flake = nixpkgs; }; }) # Avoids nixpkgs checkout when running `nix run nixpkgs#hello`
            ./nixpkgs/nixos/nix-builder/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = { pkgsUnstable = inputs.nixpkgsUnstable.legacyPackages.aarch64-linux; };
              home-manager.users.root = import ./nixpkgs/home-manager/nix-builder.nix;
            }
          ];
        };

        # On machine:
        # sudo nixos-rebuild switch --flake .#homepi
        # From remote machine:
        # nixos-rebuild switch --flake ".#homepi" --target-host "homepi" --use-remote-sudo --show-trace
        homepi = inputs.nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { common = self.common; pkgsUnstable = inputs.nixpkgsUnstable.legacyPackages.aarch64-linux; inherit inputs; };
          modules = [
            ({ config = { nix.registry.nixpkgs.flake = nixpkgs; }; }) # Avoids nixpkgs checkout when running `nix run nixpkgs#hello`
            vscode-server.nixosModule
            ./nixpkgs/nixos/homepi/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = { pkgsUnstable = inputs.nixpkgsUnstable.legacyPackages.aarch64-linux; };
              # TODO load home-manager dotfiles also for root user
              home-manager.users.schickling = import ./nixpkgs/home-manager/homepi.nix;
            }
          ];

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
