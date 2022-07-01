{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    nixpkgsStable.url = "github:NixOS/nixpkgs/release-22.05";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs @ { self, flake-utils, nixpkgs, nixpkgsStable, home-manager }:


    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {

          devShell = with pkgs; pkgs.mkShell {
            buildInputs = [
              packer
              # NOTE currently disabled as it's broken on darwin
              # awscli # needed for some packer workflows
            ];
          };

        })
    // # <- concatenates Nix attribute sets
    {

      homeConfigurations = {
        mbp2021 = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgsStable.legacyPackages.aarch64-darwin;
          modules = [
            ./nixpkgs/home-manager/modules/home-manager.nix
            ./nixpkgs/home-manager/modules/fish.nix
            ./nixpkgs/home-manager/modules/common.nix
            ./nixpkgs/home-manager/modules/git.nix
            ./nixpkgs/home-manager/mac.nix
            {
              home = {
                homeDirectory = "/home/schickling";
                username = "schickling";
              };
            }
          ];
        };

        dev2 = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgsStable.legacyPackages.x86_64-linux;
          modules = [
            ./nixpkgs/home-manager/modules/home-manager.nix
            ./nixpkgs/home-manager/modules/fish.nix
            ./nixpkgs/home-manager/modules/common.nix
            ./nixpkgs/home-manager/modules/git.nix
            ./nixpkgs/home-manager/dev2.nix
            {
              home = {
                homeDirectory = "/home/schickling";
                username = "schickling";
              };
            }
          ];
        };

        gitpod = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgsStable.legacyPackages.x86_64-linux;
          modules = [
            ./nixpkgs/home-manager/modules/home-manager.nix
            ./nixpkgs/home-manager/modules/fish.nix
            ./nixpkgs/home-manager/modules/common.nix
            ./nixpkgs/home-manager/modules/git.nix
            ./nixpkgs/home-manager/gitpod.nix
            {
              home = {
                homeDirectory = "/home/gitpod";
                username = "gitpod";
              };
            }
          ];
        };

      };

      nixosConfigurations = {

        # sudo nixos-rebuild switch --flake .#dev2
        dev2 = inputs.nixpkgsStable.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { common = self.common; inherit inputs; };
          # TODO load home-manager dotfiles also for root user
          modules = [ ./nixpkgs/nixos/dev2/configuration.nix ];
        };

        # sudo nixos-rebuild switch --flake .#homepi
        homepi = inputs.nixpkgsStable.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { common = self.common; inherit inputs; };
          modules = [ ./nixpkgs/nixos/homepi/configuration.nix ];
        };

        homepiImage = inputs.nixpkgsStable.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { common = self.common; inherit inputs; };
          modules = [ ./nixpkgs/nixos/homepi/sd-image.nix ];
        };

      };

      images = {
        # nix build .#images.homepi
        homepi = self.nixosConfigurations.homepiImage.config.system.build.sdImage;
      };

      common = {
        sshKeys = [
          "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLXMVzwr9BKB67NmxYDxedZC64/qWU6IvfTTh4HDdLaJe18NgmXh7mofkWjBtIy+2KJMMlB4uBRH4fwKviLXsSM= MBP2020@secretive.MacBook-Pro-Johannes.local"
          "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBM7UIxnOjfmhXMzEDA1Z6WxjUllTYpxUyZvNFpS83uwKj+eSNuih6IAsN4QAIs9h4qOHuMKeTJqanXEanFmFjG0= MM2021@secretive.Johannes’s-Mac-mini.local"
          "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPkfRqtIP8Lc7qBlJO1CsBeb+OEZN87X+ZGGTfNFf8V588Dh/lgv7WEZ4O67hfHjHCNV8ZafsgYNxffi8bih+1Q= MBP2021@secretive.Johannes’s-MacBook-Pro.local"
        ];
      };
    };
}
