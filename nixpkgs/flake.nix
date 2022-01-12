# Based on https://github.com/nix-community/home-manager#nix-flakes
{
  description = "Home Manager flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: {
    homeConfigurations = {
      mbp2021 = inputs.home-manager.lib.homeManagerConfiguration {
        system = "aarch64-darwin";
        homeDirectory = "/home/schickling";
        username = "schickling";
        configuration.imports = [
          ./home-manager/modules/home-manager.nix
          ./home-manager/modules/common.nix
          ./home-manager/modules/git.nix
          ./home-manager/mac.nix
        ];
      };

      dev2 = inputs.home-manager.lib.homeManagerConfiguration {
        system = "x86_64-linux";
        homeDirectory = "/home/schickling";
        username = "schickling";
        configuration.imports = [
          ./home-manager/modules/home-manager.nix
          ./home-manager/modules/common.nix
          ./home-manager/modules/git.nix
          ./home-manager/dev2.nix
        ];
      };

      gitpod = inputs.home-manager.lib.homeManagerConfiguration {
        system = "x86_64-linux";
        homeDirectory = "/home/gitpod";
        username = "gitpod";
        configuration.imports = [
          ./home-manager/modules/home-manager.nix
          ./home-manager/modules/fish.nix
          ./home-manager/modules/common.nix
          ./home-manager/modules/git.nix
          ./home-manager/gitpod.nix
        ];
      };

    };
  };
}
