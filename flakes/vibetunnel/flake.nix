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
          version = "1.0.0-beta.15.1";

          src = pkgs.fetchurl {
            url = "https://registry.npmjs.org/vibetunnel/-/vibetunnel-1.0.0-beta.15.1.tgz";
            sha256 = "sha256-cPRwIci0F/rgWuKtQ9Wqi8Ao1rFXJdbE7qNb/yG8X8A=";
          };

          npmDepsHash = "sha256-+DcR5EHpwxOS3fSmXUzKDi/Xz5hadCJ6+YKuZvBCfPg=";

          npmFlags = [ "--omit=dev" "--include=optional" "--ignore-scripts" ];

          # No build script
          dontNpmBuild = true;

          NIX_CFLAGS_COMPILE = pkgs.lib.optionalString pkgs.stdenv.isDarwin "-D_DARWIN_C_SOURCE";

          # Use the local package-lock.json
          postPatch = ''
            cp ${./package.json} package.json
            cp ${./package-lock.json} package-lock.json
          '';

          # Run postinstall to extract prebuilds
          postInstall = ''
            cd $out/lib/node_modules/vibetunnel
            ${pkgs.nodejs_22}/bin/node scripts/postinstall-npm.js || true
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
