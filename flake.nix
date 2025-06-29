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
      # Import builders and utilities
      builders = import ./lib/builders.nix { inherit inputs; };
      hosts = import ./hosts.nix;
      
      # Helper to resolve extra modules
      resolveExtraModules = extraModules: map (name: 
        if name == "vscode-server" then vscode-server.nixosModule
        else name
      ) extraModules;
    in

    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = builders.mkPkgs system;
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

      homeConfigurations = 
        # Darwin home configurations
        (nixpkgs.lib.mapAttrs (name: config: builders.mkHomeManagerConfig {
          inherit (config) system;
          modules = [ config.homeManagerPath ];
        }) hosts.darwin) //
        
        # Linux home configurations  
        (nixpkgs.lib.mapAttrs (name: config: builders.mkHomeManagerConfig {
          inherit (config) system modules;
        }) hosts.homeManager);

      # Apply by running `nix build .#darwinConfigurations.mbp2025.system; ./result/sw/bin/darwin-rebuild switch --flake .;`
      darwinConfigurations = nixpkgs.lib.mapAttrs (name: config: builders.mkDarwinConfig {
        inherit (config) system configPath homeManagerPath;
      }) hosts.darwin;

      nixosConfigurations = nixpkgs.lib.mapAttrs (name: config: builders.mkNixosConfig {
        inherit (config) system configPath homeManagerPath;
        userName = config.userName or "schickling";
        extraModules = resolveExtraModules (config.extraModules or []);
        commonConfig = self.common;
      }) hosts.nixos;

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
