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
        version = "0.45.0";
        tag = "rust-v${version}";

        # Platform-specific download URLs, hashes, and binary names
        sources = {
          x86_64-linux = {
            url = "https://github.com/openai/codex/releases/download/${tag}/codex-x86_64-unknown-linux-gnu.tar.gz";
            sha256 = "01fe3f88a33268a0b2102ede84ee656980b1396447df456455a23ef045cbe118";
            binaryName = "codex-x86_64-unknown-linux-gnu";
          };
          aarch64-linux = {
            url = "https://github.com/openai/codex/releases/download/${tag}/codex-aarch64-unknown-linux-gnu.tar.gz";
            sha256 = "39ba5ee905fc4b1cd1d6c2ac8ba0d9b5924080ee6f4ab62b61cdbc3fce3c85ff";
            binaryName = "codex-aarch64-unknown-linux-gnu";
          };
          x86_64-darwin = {
            url = "https://github.com/openai/codex/releases/download/${tag}/codex-x86_64-apple-darwin.tar.gz";
            sha256 = "46cff76099b1fab3639b07dcd87ba9daa4ddab1021e04c9f1458490c2816e7a3";
            binaryName = "codex-x86_64-apple-darwin";
          };
          aarch64-darwin = {
            url = "https://github.com/openai/codex/releases/download/${tag}/codex-aarch64-apple-darwin.tar.gz";
            sha256 = "cdd66dd9e8f7d0435b534bdfba84f9822dc06ed450f69e6d21ff653d4e9f4e36";
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
