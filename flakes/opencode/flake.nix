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

        version = "1.0.85";
        tag = "v${version}";

        sources = {
          x86_64-linux = {
            url = "https://github.com/sst/opencode/releases/download/${tag}/opencode-linux-x64.zip";
            sha256 = "0k16j24zlfazdkjyqcdxh3viqsavmzr9h68a35fb9ld38nwa34zq";
          };
          aarch64-linux = {
            url = "https://github.com/sst/opencode/releases/download/${tag}/opencode-linux-arm64.zip";
            sha256 = "1c7zh30xxqqxzv5rsj1c8clmxr351qcykhwni4i3x1r6yp1a8ray";
          };
          x86_64-darwin = {
            url = "https://github.com/sst/opencode/releases/download/${tag}/opencode-darwin-x64.zip";
            sha256 = "0mxmphzkb9q1hmy84sflddy45gi5g7f2aih63c7iq29jdisj1ha2";
          };
          aarch64-darwin = {
            url = "https://github.com/sst/opencode/releases/download/${tag}/opencode-darwin-arm64.zip";
            sha256 = "0gjcy5xdw8h8xwrlfjzyb4nvjq9x4m41ry991vr98zyppd4cyzmq";
          };
        };

        platformInfo = sources.${system} or (throw "Unsupported system: ${system}");

        opencode = pkgs.stdenv.mkDerivation {
          pname = "opencode";
          inherit version;

          dontBuild = true;
          dontUnpack = true;
          dontStrip = true;

          src = pkgs.fetchurl {
            inherit (platformInfo) url sha256;
          };

          nativeBuildInputs = [ pkgs.unzip ]
            ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.patchelf ];

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            tmpdir=$(mktemp -d)
            unzip -q "$src" -d "$tmpdir"
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
