{
  description = "SST opencode CLI packaged with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        version = "1.0.132";
        tag = "v${version}";

        sources = {
          x86_64-linux = {
            url = "https://github.com/sst/opencode/releases/download/${tag}/opencode-linux-x64.tar.gz";
            sha256 = "1gqjhpgci82rs0j780a00h6af05bbbgbqnp30gnqbply12w9gmj0";
            format = "tar";
          };
          aarch64-linux = {
            url = "https://github.com/sst/opencode/releases/download/${tag}/opencode-linux-arm64.tar.gz";
            sha256 = "10qx7yhn61irzxp153lnc9ib78lija2y9if67jkc946g3cy3v16f";
            format = "tar";
          };
          x86_64-darwin = {
            url = "https://github.com/sst/opencode/releases/download/${tag}/opencode-darwin-x64.zip";
            sha256 = "06ry5c5vr5wg4i0mk70knkjdwi4clivz5202rkpa3b7fn1szv91m";
            format = "zip";
          };
          aarch64-darwin = {
            url = "https://github.com/sst/opencode/releases/download/${tag}/opencode-darwin-arm64.zip";
            sha256 = "14k9ym8pwjs2pgahkyw2afyzr8dq76q9vsfl107hmwygxz81nhl1";
            format = "zip";
          };
        };

        platformInfo = sources.${system} or (throw "Unsupported system: ${system}");
        archiveFormat = platformInfo.format or "zip";

        opencode = pkgs.stdenv.mkDerivation {
          pname = "opencode";
          inherit version;

          dontBuild = true;
          dontUnpack = true;
          dontStrip = true;

          src = pkgs.fetchurl {
            inherit (platformInfo) url sha256;
          };

          nativeBuildInputs =
            pkgs.lib.optional (archiveFormat == "zip") pkgs.unzip
            ++ pkgs.lib.optional (archiveFormat == "tar") pkgs.gnutar
            ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.patchelf ];

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            tmpdir=$(mktemp -d)
            if [ "${archiveFormat}" = "zip" ]; then
              unzip -q "$src" -d "$tmpdir"
            else
              tar -xzf "$src" -C "$tmpdir"
            fi
            cp "$tmpdir/opencode" "$out/bin/opencode"
            chmod +x "$out/bin/opencode"

            ${pkgs.lib.optionalString pkgs.stdenv.isLinux ''
              origSize=$(stat -c%s "$tmpdir/opencode")
              ${pkgs.patchelf}/bin/patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
                "$out/bin/opencode"
              patchedSize=$(stat -c%s "$out/bin/opencode")
              if [ "$patchedSize" -lt "$origSize" ]; then
                tail -c +$((patchedSize + 1)) "$tmpdir/opencode" >> "$out/bin/opencode"
              fi
            ''}

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Self-hosted open-source AI coding agent";
            homepage = "https://github.com/sst/opencode";
            license = licenses.mit;
            maintainers = [ ];
            platforms = builtins.attrNames sources;
            mainProgram = "opencode";
          };
        };
      in {
        packages.opencode = opencode;
        packages.default = opencode;

        devShells.default = pkgs.mkShell {
          packages = [ opencode ];
        };
      });
}
