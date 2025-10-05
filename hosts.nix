{
  # Darwin hosts
  darwin = {
    mbp2025 = {
      system = "aarch64-darwin";
      configPath = ./nixpkgs/darwin/darwin-shared.nix;
      homeManagerPath = ./nixpkgs/home-manager/modules/darwin-common.nix;
    };
    
    mbp2021 = {
      system = "aarch64-darwin";
      configPath = ./nixpkgs/darwin/darwin-shared.nix;
      homeManagerPath = ./nixpkgs/home-manager/modules/darwin-common.nix;
    };
    
    mbp2020 = {
      system = "x86_64-darwin";
      configPath = ./nixpkgs/darwin/darwin-shared.nix;
      homeManagerPath = ./nixpkgs/home-manager/modules/darwin-common.nix;
    };
    
    mini2020 = {
      system = "aarch64-darwin";
      configPath = ./nixpkgs/darwin/darwin-shared.nix;
      homeManagerPath = ./nixpkgs/home-manager/modules/darwin-common.nix;
    };
  };

  # NixOS hosts
  nixos = {
    dev3 = {
      system = "x86_64-linux";
      configPath = ./nixpkgs/nixos/dev3/configuration.nix;
      homeManagerPath = ./nixpkgs/home-manager/dev3.nix;
      extraModules = [ "vscode-server" ];
      deploy = {
        hostname = "dev3";
        sshUser = "root";
      };
    };
    
    homepi = {
      system = "aarch64-linux";
      configPath = ./nixpkgs/nixos/homepi/configuration.nix;
      homeManagerPath = ./nixpkgs/home-manager/homepi.nix;
      extraModules = [ "vscode-server" ];
      deploy = {
        hostname = "homepi";
        sshUser = "root";
      };
    };
  };

  # Home-manager only hosts
  homeManager = {
    dev3 = {
      system = "x86_64-linux";
      modules = [ ./nixpkgs/home-manager/dev3.nix ];
    };
    
    homepi = {
      system = "aarch64-linux";
      modules = [ ./nixpkgs/home-manager/homepi.nix ];
    };
    
    rpi-museum = {
      system = "aarch64-linux";
      modules = [ ./nixpkgs/home-manager/rpi-museum.nix ];
    };
  };
} 
