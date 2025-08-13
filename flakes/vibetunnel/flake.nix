{
  description = "VibeTunnel CLI packaged with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        vibetunnel = pkgs.buildNpmPackage {
          pname = "vibetunnel";
          version = "1.0.0-beta.13";

          src = pkgs.fetchurl {
            url = "https://registry.npmjs.org/vibetunnel/-/vibetunnel-1.0.0-beta.13.tgz";
            sha256 = "sha256-8Hjt6wfBL1vn+w8/DD7dkc0W/hCUuKVCL0QxUsyOUHs=";
          };

          npmDepsHash = "sha256-Sc1jOJvhGgS08/Epn3+jtqdVzVqQu9gaTk3rAUjr7i0=";

          # Skip optional dependencies to avoid PAM build issues
          npmFlags = [ "--no-optional" ];

          # No build script
          dontNpmBuild = true;

          # Use the local package-lock.json
          postPatch = ''
            cp ${./package-lock.json} package-lock.json
          '';

          # Run postinstall to extract prebuilds
          postInstall = ''
            cd $out/lib/node_modules/vibetunnel
            ${pkgs.nodejs_22}/bin/node scripts/postinstall.js || true
          '';
        };
      in {
        packages.vibetunnel = vibetunnel;
        packages.default = vibetunnel;

        devShells.default = pkgs.mkShell { 
          packages = [ vibetunnel ]; 
        };
      });
}