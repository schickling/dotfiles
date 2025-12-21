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

        version = "1.0.184";
        tag = "v${version}";

        sources = {
          x86_64-linux = {
            url = "https://github.com/sst/opencode/releases/download/${tag}/opencode-linux-x64.tar.gz";
            sha256 = "10dssy93xiyfw0dpizsv8pvhj8zlzvdr9k654yy4insfc8qf4m3b";
            format = "tar";
          };
          aarch64-linux = {
            url = "https://github.com/sst/opencode/releases/download/${tag}/opencode-linux-arm64.tar.gz";
            sha256 = "0pgnb58z7cxx1svgiamgxq18qwvs91wk44dwcm2ac2ir2f1crmm3";
            format = "tar";
          };
          x86_64-darwin = {
            url = "https://github.com/sst/opencode/releases/download/${tag}/opencode-darwin-x64.zip";
            sha256 = "13gjqqqvpjf2zz9m8z245jjf1jjjnplnswjyn35p1k6cjgbcln06";
            format = "zip";
          };
          aarch64-darwin = {
            url = "https://github.com/sst/opencode/releases/download/${tag}/opencode-darwin-arm64.zip";
            sha256 = "1zr5dpjb6wzwazd632c6k1saa5ig1hmakfpmd1prbrqmlm78cfs9";
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
