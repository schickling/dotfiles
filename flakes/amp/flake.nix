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

        version = "0.0.1767386224-g46ed64";

        sources = {
          x86_64-linux = {
            url = "https://storage.googleapis.com/amp-public-assets-prod-0/cli/${version}/amp-linux-x64";
            sha256 = "1pik6h17av97k4rrmdcgc9n622nq8cpk9qciwy43s0kyawsb3106";
          };
          aarch64-linux = {
            url = "https://storage.googleapis.com/amp-public-assets-prod-0/cli/${version}/amp-linux-arm64";
            sha256 = "0s2r013gwp5p7svqik4byqmh8j2qz1rv9vhy0hffck4dh3hyrxvf";
          };
          x86_64-darwin = {
            url = "https://storage.googleapis.com/amp-public-assets-prod-0/cli/${version}/amp-darwin-x64";
            sha256 = "0xdqd8fd95y5i0bgwwxznrw9xrwaryrrr4yzl2kb111sfd999s4n";
          };
          aarch64-darwin = {
            url = "https://storage.googleapis.com/amp-public-assets-prod-0/cli/${version}/amp-darwin-arm64";
            sha256 = "0xjiwjx97zqj1zsziy5l0k8kry13y5bak5hw750375a0i8z1z26w";
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
            install -m 0755 $src $out/bin/amp

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
