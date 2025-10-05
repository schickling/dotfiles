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
    vibetunnel = {
      url = "path:./flakes/vibetunnel";
      inputs.nixpkgs.follows = "nixpkgsUnstable";
    };
    codex = {
      url = "path:./flakes/codex";
      inputs.nixpkgs.follows = "nixpkgsUnstable";
    };
    opencode = {
      url = "path:./flakes/opencode";
      inputs.nixpkgs.follows = "nixpkgsUnstable";
    };
  };

  outputs = inputs @ { self, flake-utils, darwin, vscode-server, deploy-rs, nixpkgs, nixpkgsUnstable, home-manager, vibetunnel, codex, opencode }:
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
          # home-manager switch --flake /Users/schickling/.dotfiles/.#mbp2025
          devShells = {
            default = with pkgs; mkShell {
              buildInputs = [
                pkgs.home-manager
                pkgs.nixos-rebuild # needed for remote deploys on macOS
              ];
              
              shellHook = ''
                # Disable global npm installs to enforce Nix-managed dependencies
                # This prevents accidental global installs that would bypass Nix's reproducible environment
                npm config set global false
                
                # Require virtual environment for pip installs and disable user installs
                # This prevents both system-wide and user-local Python packages, enforcing isolated environments
                export PIP_REQUIRE_VIRTUALENV=true
                export PIP_USER=false
              '';
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

        dev3 = {
          hostname = "dev3";
          profiles.system = {
            sshUser = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.dev3;
          };
        };


      };

      # checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

      common = {
        sshKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBY2vg6JN45hpcl9HH279/ityPEGGOrDjY3KdyulOUmX 1Password SSH"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMrYafhnbSO2w68ANOTdIIF9evk1oZT3yF1jw+XJxQhc dev3"
        ];
      };
    };
}
