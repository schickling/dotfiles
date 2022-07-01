{ modulesPath, ... }: {
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
    ./cachix.nix
  ];

  ec2.hvm = true;
  ec2.efi = true;

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  system.stateVersion = "22.05";
}
