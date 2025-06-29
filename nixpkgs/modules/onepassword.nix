{ config, lib, pkgs, pkgsUnstable, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in
{
  # Darwin-specific 1Password setup
  system.activationScripts.onePasswordSetup = lib.mkIf isDarwin {
    text = ''
      # For TouchID to work in `op` 1Password CLI, it needs to be at `/usr/local/bin`
      # (Hopefully this requirement will be lifted by 1Password at some point)
      # NOTE we don't install `op` via nix but simply copy the binary
      mkdir -p /usr/local/bin
      cp ${pkgs._1password-cli}/bin/op /usr/local/bin/op
      cp /Applications/1Password.app/Contents/MacOS/op-ssh-sign /usr/local/bin/op-ssh-sign
      
      # Setup 1Password agent socket
      # https://developer.1password.com/docs/ssh/get-started#step-4-configure-your-ssh-or-git-client
      mkdir -p ~/.1password && ln -sfv ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ~/.1password/agent.sock
    '';
  };

  # Linux-specific 1Password setup
  system.activationScripts.onePasswordSetupLinux = lib.mkIf isLinux {
    text = ''
      mkdir -p /usr/local/bin
      cp ${pkgsUnstable._1password-cli}/bin/op /usr/local/bin/op
      cp ${pkgsUnstable._1password-gui}/share/1password/op-ssh-sign /usr/local/bin/op-ssh-sign
    '';
  };
} 