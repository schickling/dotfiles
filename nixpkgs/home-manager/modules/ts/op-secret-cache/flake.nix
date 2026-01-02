{
  description = "op-secret-cache - Cache 1Password secrets locally for faster access";

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
          pname = "op-secret-cache-deps";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = [ pkgsUnstable.bun ];

          outputHashAlgo = "sha256";
          outputHashMode = "recursive";
          # NOTE: Update this hash when dependencies change
          # Run: nix build .#deps --rebuild 2>&1 | grep 'got:'
          outputHash = "sha256-PWxmEjd9sVEh7pZZe9u2AX9uF60kiMaI3iQ8Ndi3ecU=";

          buildPhase = ''
            export HOME=$(mktemp -d)
            bun install --frozen-lockfile || bun install
          '';

          installPhase = ''
            mkdir -p $out
            cp -r node_modules $out/

            # bun leaves dangling symlinks for optional dependencies
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

        packages.deps = deps;

        packages.default = pkgs.stdenv.mkDerivation {
          pname = "op-secret-cache";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = [
            # Use bun 1.3.1 for compile - later versions have sandbox issues
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
            bun build src/mod.ts --compile --outfile=op-secret-cache

            # Final verification
            if [ ! -s op-secret-cache ]; then
              echo "ERROR: Failed to create binary"
              exit 1
            fi

            echo "Binary created: $(ls -lh op-secret-cache)"

            # Generate shell completions
            echo "Generating shell completions..."
            ./op-secret-cache --log-level none --completions fish > op-secret-cache.fish
            ./op-secret-cache --log-level none --completions bash > op-secret-cache.bash
            ./op-secret-cache --log-level none --completions zsh > _op-secret-cache
          '';

          installPhase = ''
            mkdir -p $out/bin
            mkdir -p $out/share/fish/vendor_completions.d
            mkdir -p $out/share/bash-completion/completions
            mkdir -p $out/share/zsh/site-functions

            cp op-secret-cache $out/bin/op-secret-cache
            chmod +x $out/bin/op-secret-cache

            # Install shell completions
            cp op-secret-cache.fish $out/share/fish/vendor_completions.d/op-secret-cache.fish
            cp op-secret-cache.bash $out/share/bash-completion/completions/op-secret-cache
            cp _op-secret-cache $out/share/zsh/site-functions/_op-secret-cache
          '';

          meta = {
            description = "Cache 1Password secrets locally for faster access";
            mainProgram = "op-secret-cache";
          };
        };
      });
}
