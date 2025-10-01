## Home Manager Changes

- When modifying any files under `nixpkgs/home-manager/`, always rebuild the active profile to verify the configuration: `home-manager switch --flake .#$(hostname)`. Example: `home-manager switch --flake .#dev3`.
- Favor running the switch from the repo root so relative paths inside the flake resolve correctly.

- Prefer making changes via the Nix files and applying them instead of modifying files (e.g. configs) directly.
