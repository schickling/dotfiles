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

        version = "0.15.30";
        tag = "v${version}";

        sources = {
          x86_64-linux = {
            url = "https://github.com/sst/opencode/releases/download/${tag}/opencode-linux-x64.zip";
            sha256 = "7bd2bef09864520eb023d6ff94c1328f13834996428ffe78b0d20363725d9118";
          };
          aarch64-linux = {
            url = "https://github.com/sst/opencode/releases/download/${tag}/opencode-linux-arm64.zip";
            sha256 = "a1d8767ead3996e1394bb8118ac1f5ff87ba6c0f1e7cae3532c6727a76bccc9a";
          };
          x86_64-darwin = {
            url = "https://github.com/sst/opencode/releases/download/${tag}/opencode-darwin-x64.zip";
            sha256 = "558ed57178cdab71218d76e5f4b67068b52c229db45ef52ff04601a80c80eb82";
          };
          aarch64-darwin = {
            url = "https://github.com/sst/opencode/releases/download/${tag}/opencode-darwin-arm64.zip";
            sha256 = "4b93f768d743492bf064f71754a8c85846f57baa781460841222f06485f2da38";
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
