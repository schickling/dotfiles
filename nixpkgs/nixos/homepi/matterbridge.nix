{ config, pkgs, lib, ... }:

{
  # Matterbridge - Matter bridge for Home Assistant
  # Exposes HA entities via Matter protocol to HomeKit, Google Home, Alexa, etc.
  # Web UI available at http://homepi:8283
  virtualisation.oci-containers.containers.matterbridge = {
    image = "luligu/matterbridge:latest";
    autoStart = true;
    extraOptions = [ "--network=host" ]; # Required for mDNS/Matter
    volumes = [
      "/var/lib/matterbridge:/root/.matterbridge"
    ];
    environment = {
      TZ = "Europe/Berlin";
    };
  };

  # Ensure config directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/matterbridge 0755 root root -"
  ];
}
