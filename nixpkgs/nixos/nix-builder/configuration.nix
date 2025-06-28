{ lib, nixpkgs, common, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../configuration-common.nix
  ];

  boot.cleanTmpDir = true;

  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

  hardware.enableAllFirmware = true;

  hardware.opengl.enable = lib.mkForce false;

  networking.hostName = "nix-builder";
  
  # Machine-specific firewall settings (extends common firewall from configuration-common.nix)
  networking.firewall.allowedTCPPorts = [ 25565 ];
  networking.firewall.allowedUDPPorts = [ 25565 ];

  system.stateVersion = lib.mkForce "21.11";

  # Machine-specific SSH settings (extends common SSH from configuration-common.nix)
  services.openssh.permitRootLogin = "yes";

  # NOTE this machine only has a root user
  users.users.root.openssh.authorizedKeys.keys = common.sshKeys ++ [
    # NOTE for Nix remote builds to work best the SSH process needs to be entirely "hands-off" so I can't use Secretive for it
    # Using a manually generated key instead for now.
    # TODO hopefully this can be improved somehow (e.g. using Tailscale's SSH feature)
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDRllH+H0YP5wnsYIRGoOmRiNChvWFsjKoX62AoTUl0AUkFNwiqrdBoFrEAd7dK8gbyPkzFqeERYiKeOawAOJjLagtyGv/7qq0ikhbbB77G4yd8F3UxfLvdGQ2Tia7qXmOMjNbQNSvfBD/AXhUmia7K+Z5wmEndvwQUoVT22Zje0Mr6Nla7poyf8EZIXotnA7VkdfmOtazLrBP6o10rzuR2ZHXmDYaj/PsrAuYQgVIQ5gBaiVsPL7HCwKMyD3JuJGxSPNV9hSn2H16SD3CHon7w9uiW61Q7sEGCn0NhFqu9TtT09CYnN+SLwlHWP5Wb4ZYQy8qrN95lJ2oAYlPM8ec4lBAfhLxW4Q120bxB9UBZ7IsnJu8mdHjhdTF+Wzb2Xau7vXGCAfGzoukq+TJ4pUY0kQoj0V2J91dzRgi746YOXDb7IZuCEzydJaFZSYoWkhdyYA7bu7YWTVd70otJ+fZbySnK3S/xkDtXJtlHt6R7Tf5woxPKVuyZmD8KW+Qbxbc= schickling@mbp2021.local"
  ];

  nixpkgs.config.allowUnfree = true;
}
