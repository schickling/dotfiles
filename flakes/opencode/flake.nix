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

        version = "0.14.5";
        tag = "v${version}";

        sources = {
          x86_64-linux = {
            url = "https://github.com/sst/opencode/releases/download/${tag}/opencode-linux-x64.zip";
            sha256 = "c1a2745b7fa0802905196903f39095502f3c19322a46d1f07b957a6e9033e336";
          };
          aarch64-linux = {
            url = "https://github.com/sst/opencode/releases/download/${tag}/opencode-linux-arm64.zip";
            sha256 = "ddf72ef28beda8fe6b92aeb49a8cd5848a4f933a3030e2c486a886adbcf1e453";
          };
          x86_64-darwin = {
            url = "https://github.com/sst/opencode/releases/download/${tag}/opencode-darwin-x64.zip";
            sha256 = "a07cc41295ef924db375b0b5328ab0968af68a827e8d0cc774178e6f79e43677";
          };
          aarch64-darwin = {
            url = "https://github.com/sst/opencode/releases/download/${tag}/opencode-darwin-arm64.zip";
            sha256 = "06dcdef7676a69b288e6bddebce98779dbf8734b6026107d2b21334ff6ea5646";
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
