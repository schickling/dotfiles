{
  description = "Amp CLI packaged with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfreePredicate =
            pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "amp" ];
        };

        version = "0.0.1766750480-gd79e9b";

        sources = {
          x86_64-linux = {
            url = "https://storage.googleapis.com/amp-public-assets-prod-0/cli/${version}/amp-linux-x64";
            sha256 = "0gidqbpgza3xqywdk5w7aw6yx49qb72xkixccalcmn1h30sxcksh";
          };
          aarch64-linux = {
            url = "https://storage.googleapis.com/amp-public-assets-prod-0/cli/${version}/amp-linux-arm64";
            sha256 = "0ybaf4yx5k5m9vis3mh94lzx2w3pajjx53z9ln1fdlb1sibbcxda";
          };
          x86_64-darwin = {
            url = "https://storage.googleapis.com/amp-public-assets-prod-0/cli/${version}/amp-darwin-x64";
            sha256 = "0ls182h7zsji1wrjy8fanbqczph0bgsb8akd7sn9m4spqw23yvcl";
          };
          aarch64-darwin = {
            url = "https://storage.googleapis.com/amp-public-assets-prod-0/cli/${version}/amp-darwin-arm64";
            sha256 = "1ck1f275sxjv3y77y0pp8s1jnm35x1m61vlf77ibfwbgb2a60z8f";
          };
        };

        platformInfo = sources.${system} or (throw "Unsupported system: ${system}");

        amp = pkgs.stdenv.mkDerivation {
          pname = "amp";
          inherit version;

          dontBuild = true;
          dontUnpack = true;

          src = pkgs.fetchurl {
            inherit (platformInfo) url sha256;
          };

          nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.patchelf ];

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            cp $src $out/bin/amp
            chmod +x $out/bin/amp

            ${pkgs.lib.optionalString pkgs.stdenv.isLinux ''
              if ${pkgs.patchelf}/bin/patchelf --print-interpreter $out/bin/amp >/dev/null 2>&1; then
                ${pkgs.patchelf}/bin/patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
                  $out/bin/amp
              fi
            ''}

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Amp CLI coding agent";
            homepage = "https://ampcode.com";
            license = licenses.unfreeRedistributable;
            maintainers = [ ];
            platforms = builtins.attrNames sources;
            mainProgram = "amp";
          };
        };
      in {
        packages.amp = amp;
        packages.default = amp;

        devShells.default = pkgs.mkShell {
          packages = [ amp ];
        };
      });
}
