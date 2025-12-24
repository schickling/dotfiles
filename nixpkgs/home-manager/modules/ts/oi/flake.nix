{
  description = "oi - AI-assisted git commit CLI built with Effect";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgsUnstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Pin to nixpkgs with bun 1.3.1 which works in nix sandbox
    # See: https://github.com/oven-sh/bun/issues/24645
    nixpkgsBun131.url = "github:NixOS/nixpkgs/1666250dbe4141e4ca8aaf89b40a3a51c2e36144";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgsUnstable, nixpkgsBun131, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        pkgsUnstable = import nixpkgsUnstable { inherit system; };
        pkgsBun131 = import nixpkgsBun131 { inherit system; };

        # Fixed-output derivation to fetch dependencies
        deps = pkgs.stdenv.mkDerivation {
          pname = "oi-deps";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = [ pkgsUnstable.bun ];

          outputHashAlgo = "sha256";
          outputHashMode = "recursive";
          outputHash = "sha256-D+m+MDQf85RTpAfzQbnE7sAj+Uk07r/Sm4E1oWHa9Nc=";

          buildPhase = ''
            export HOME=$(mktemp -d)
            bun install --frozen-lockfile || bun install
          '';

          installPhase = ''
            mkdir -p $out
            cp -r node_modules $out/

            # bun leaves a dangling .bin/download-msgpackr-prebuilds symlink because the
            # msgpackr optional dependency resolves to the scoped platform package only.
            # Nix's fixup phase rejects broken links, so prune them ahead of time.
            find -L $out -xtype l -delete
          '';
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgsUnstable.bun
            pkgsUnstable.oxlint
          ];
        };

        packages.default = pkgs.stdenv.mkDerivation {
          pname = "oi";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = [
            # Use bun 1.3.1 for compile - later versions have sandbox issues
            # See: https://github.com/oven-sh/bun/issues/24645
            pkgsBun131.bun
            pkgsUnstable.oxlint
          ];

          # Don't strip - corrupts bun binaries
          dontStrip = true;

          buildPhase = ''
            export HOME=$(mktemp -d)
            export TMPDIR=$(mktemp -d)

            # Copy pre-fetched deps
            cp -r ${deps}/node_modules .
            chmod -R u+w node_modules

            # Lint
            echo "Running oxlint..."
            oxlint src/

            # Build standalone binary
            echo "Building standalone binary with bun $(bun --version)..."
            bun build src/mod.ts --compile --outfile=oi

            # Final verification
            if [ ! -s oi ]; then
              echo "ERROR: Failed to create binary"
              exit 1
            fi

            echo "Binary created: $(ls -lh oi)"

            # Generate shell completions (suppress log output)
            echo "Generating shell completions..."
            ./oi --log-level none --completions fish > oi.fish
            ./oi --log-level none --completions bash > oi.bash
            ./oi --log-level none --completions zsh > _oi
          '';

          installPhase = ''
            mkdir -p $out/bin
            mkdir -p $out/share/fish/vendor_completions.d
            mkdir -p $out/share/bash-completion/completions
            mkdir -p $out/share/zsh/site-functions

            cp oi $out/bin/oi
            chmod +x $out/bin/oi

            # Install shell completions
            cp oi.fish $out/share/fish/vendor_completions.d/oi.fish
            cp oi.bash $out/share/bash-completion/completions/oi
            cp _oi $out/share/zsh/site-functions/_oi
          '';

          meta = {
            description = "AI-assisted git commit CLI built with Effect";
            mainProgram = "oi";
          };
        };
      });
}
