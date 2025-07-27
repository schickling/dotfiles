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
    dev2 = {
      system = "x86_64-linux";
      configPath = ./nixpkgs/nixos/dev2/configuration.nix;
      homeManagerPath = ./nixpkgs/home-manager/dev2.nix;
      extraModules = [ "vscode-server" ];
      deploy = {
        hostname = "dev2";
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
    gitpod = {
      system = "x86_64-linux";
      modules = [ ./nixpkgs/home-manager/gitpod.nix ];
    };
    
    dev2 = {
      system = "x86_64-linux";
      modules = [ ./nixpkgs/home-manager/dev2.nix ];
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