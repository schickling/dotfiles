{
  description = "OpenAI Codex CLI packaged with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Version information from the latest release
        version = "0.36.0";
        tag = "rust-v${version}";

        # Platform-specific download URLs, hashes, and binary names
        sources = {
          x86_64-linux = {
            url = "https://github.com/openai/codex/releases/download/${tag}/codex-x86_64-unknown-linux-gnu.tar.gz";
            sha256 = "6416eb1b33da9f16f31f933b6c68f98a3891309a7eccdf2fbc5aa2799925b61d";
            binaryName = "codex-x86_64-unknown-linux-gnu";
          };
          aarch64-linux = {
            url = "https://github.com/openai/codex/releases/download/${tag}/codex-aarch64-unknown-linux-gnu.tar.gz";
            sha256 = "0623c5b3025e54ffcf0931ad67b75dd02337b848de23b56cfbd5bdae7813346e";
            binaryName = "codex-aarch64-unknown-linux-gnu";
          };
          x86_64-darwin = {
            url = "https://github.com/openai/codex/releases/download/${tag}/codex-x86_64-apple-darwin.tar.gz";
            sha256 = "3c731501544d6c92b3b205c0a7e5e0a3fb64683278a68fe664dbd86cc50548b3";
            binaryName = "codex-x86_64-apple-darwin";
          };
          aarch64-darwin = {
            url = "https://github.com/openai/codex/releases/download/${tag}/codex-aarch64-apple-darwin.tar.gz";
            sha256 = "d0d3758370f2ca448fe468e9dd07b03487a8e6ec8fa40a1c4b1ea537d1673478";
            binaryName = "codex-aarch64-apple-darwin";
          };
        };

        platformInfo = sources.${system} or (throw "Unsupported system: ${system}");

        codex = pkgs.stdenv.mkDerivation {
          pname = "codex";
          inherit version;

          src = pkgs.fetchurl {
            inherit (platformInfo) url sha256;
          };

          # installShellFiles provides installShellCompletion. We'll tolerate
          # completion generation failures during install on Linux and rely on
          # postFixup to make the binary runnable.
          nativeBuildInputs = with pkgs; [ installShellFiles ];

          unpackPhase = ''
            runHook preUnpack
            tar -xzf $src
            runHook postUnpack
          '';

          installPhase = ''
            runHook preInstall
            
            # Create bin directory
            mkdir -p $out/bin
            
            # Install the binary with correct name
            cp ${platformInfo.binaryName} $out/bin/codex
            chmod +x $out/bin/codex

            # Try to generate shell completions (best-effort). On Linux this may
            # fail before patchelf fixes the binary; ignore failures and continue.
            installShellCompletion --cmd codex \
              --fish <($out/bin/codex completion fish) || true
            installShellCompletion --cmd codex \
              --zsh <($out/bin/codex completion zsh) || true
            
            runHook postInstall
          '';

          # Add dynamic library dependencies for Linux
          postFixup = pkgs.lib.optionalString pkgs.stdenv.isLinux ''
            ${pkgs.patchelf}/bin/patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
              --set-rpath "${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib pkgs.openssl ]}" \
              $out/bin/codex

            # After patching, try generating shell completions (best-effort)
            mkdir -p $out/share/fish/vendor_completions.d $out/share/zsh/site-functions
            $out/bin/codex completion fish > $out/share/fish/vendor_completions.d/codex.fish || true
            $out/bin/codex completion zsh > $out/share/zsh/site-functions/_codex || true
          '';

          meta = with pkgs.lib; {
            description = "AI-powered coding agent that runs locally";
            homepage = "https://github.com/openai/codex";
            license = licenses.asl20;
            maintainers = [ ];
            platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
            mainProgram = "codex";
          };
        };
      in {
        packages.codex = codex;
        packages.default = codex;

        devShells.default = pkgs.mkShell {
          packages = [ codex ];
        };
      });
}
