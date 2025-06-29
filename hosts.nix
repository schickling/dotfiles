{
  # Darwin hosts
  darwin = {
    mbp2025 = {
      system = "aarch64-darwin";
      configPath = ./nixpkgs/darwin/mbp2025/configuration.nix;
      homeManagerPath = ./nixpkgs/home-manager/mbp2025.nix;
    };
    
    mbp2021 = {
      system = "aarch64-darwin";
      configPath = ./nixpkgs/darwin/mbp2021/configuration.nix;
      homeManagerPath = ./nixpkgs/home-manager/mbp2021.nix;
    };
    
    mbp2020 = {
      system = "x86_64-darwin";
      configPath = ./nixpkgs/darwin/mbp2020/configuration.nix;
      homeManagerPath = ./nixpkgs/home-manager/mbp2020.nix;
    };
    
    mini2020 = {
      system = "aarch64-darwin";
      configPath = ./nixpkgs/darwin/mini2020/configuration.nix;
      homeManagerPath = ./nixpkgs/home-manager/mini2020.nix;
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
    
    nix-builder = {
      system = "aarch64-linux";
      configPath = ./nixpkgs/nixos/nix-builder/configuration.nix;
      homeManagerPath = ./nixpkgs/home-manager/nix-builder.nix;
      userName = "root";
      deploy = {
        hostname = "nix-builder";
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
  };
} 