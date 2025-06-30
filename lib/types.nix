{ lib, ... }:

with lib;

{
  # Host configuration type
  hostConfig = types.submodule {
    options = {
      system = mkOption {
        type = types.enum [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
        description = "System architecture";
      };
      
      configPath = mkOption {
        type = types.path;
        description = "Path to system configuration";
      };
      
      homeManagerPath = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to home-manager configuration";
      };
      
      userName = mkOption {
        type = types.str;
        default = "schickling";
        description = "Primary user name";
      };
      
      extraModules = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional modules to include";
      };
    };
  };
  
  # Deploy configuration type
  deployConfig = types.submodule {
    options = {
      hostname = mkOption {
        type = types.str;
        description = "Deployment hostname";
      };
      
      sshUser = mkOption {
        type = types.str;
        default = "root";
        description = "SSH user for deployment";
      };
    };
  };
} 