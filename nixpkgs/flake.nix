# Based on https://github.com/nix-community/home-manager#nix-flakes
{
  description = "Home Manager flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, ... }@inputs: {
    homeConfigurations = {
      mbp2021 = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
        modules = [
          ./home-manager/modules/home-manager.nix
          ./home-manager/modules/fish.nix
          ./home-manager/modules/common.nix
          ./home-manager/modules/git.nix
          ./home-manager/mac.nix
          {
            home = {
              homeDirectory = "/home/schickling";
              username = "schickling";
            };
          }
        ];
      };

      dev2 = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          ./home-manager/modules/home-manager.nix
          ./home-manager/modules/fish.nix
          ./home-manager/modules/common.nix
          ./home-manager/modules/git.nix
          ./home-manager/dev2.nix
          {
            home = {
              homeDirectory = "/home/schickling";
              username = "schickling";
            };
          }
        ];
      };

      gitpod = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          ./home-manager/modules/home-manager.nix
          ./home-manager/modules/fish.nix
          ./home-manager/modules/common.nix
          ./home-manager/modules/git.nix
          ./home-manager/gitpod.nix
          {
            home = {
              homeDirectory = "/home/gitpod";
              username = "gitpod";
            };
          }
        ];
      };

    };

    systemConfigurations = {

      homepiImage = inputs.nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          ./nixos/homepi/sd-image.nix
        ];
      };

    };

    images = {
      homepi = self.systemConfigurations.homepiImage.config.system.build.sdImage;
    };
  };
}
