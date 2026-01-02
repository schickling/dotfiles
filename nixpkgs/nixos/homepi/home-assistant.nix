{ config, pkgs, lib, ... }:

{
  # Home Assistant via Docker (declarative OCI container)
  environment.etc."home-assistant/configuration.yaml".source = ./home-assistant-configuration.yaml;

  virtualisation.oci-containers = {
    backend = "docker";
    containers.home-assistant = {
      image = "ghcr.io/home-assistant/home-assistant:stable";
      autoStart = true;
      extraOptions = [
        "--network=host"
        "--privileged"  # Required for USB/Bluetooth device access
      ];
      volumes = [
        "/var/lib/home-assistant:/config"
        "/etc/home-assistant/configuration.yaml:/config/configuration.yaml:ro"
        "/etc/localtime:/etc/localtime:ro"
        "/run/dbus:/run/dbus:ro"  # For Bluetooth support
      ];
      environment = {
        TZ = "Europe/Berlin";
      };
    };
  };

  # Ensure config directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/home-assistant 0755 root root -"
  ];

  # D-Bus for Bluetooth integration
  services.dbus.enable = true;
}
