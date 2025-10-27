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
        version = "0.50.0";
        tag = "rust-v${version}";

        # Platform-specific download URLs, hashes, and binary names
        sources = {
          x86_64-linux = {
            url = "https://github.com/openai/codex/releases/download/${tag}/codex-x86_64-unknown-linux-gnu.tar.gz";
            sha256 = "42402329dbdceb044316a82170f68531bafcff43ecec3d8850418b2ca6693287";
            binaryName = "codex-x86_64-unknown-linux-gnu";
          };
          aarch64-linux = {
            url = "https://github.com/openai/codex/releases/download/${tag}/codex-aarch64-unknown-linux-gnu.tar.gz";
            sha256 = "14461973a398b3697dcb3568f85744fe56de014b40a23a3f07916cfff6224106";
            binaryName = "codex-aarch64-unknown-linux-gnu";
          };
          x86_64-darwin = {
            url = "https://github.com/openai/codex/releases/download/${tag}/codex-x86_64-apple-darwin.tar.gz";
            sha256 = "8ab3e18a16b07ee32b955570e546e990d77bdfbf3732ac53db6a6eb447f0ffa7";
            binaryName = "codex-x86_64-apple-darwin";
          };
          aarch64-darwin = {
            url = "https://github.com/openai/codex/releases/download/${tag}/codex-aarch64-apple-darwin.tar.gz";
            sha256 = "9b8c723e456476b3394af3df7b3dc9826be76af137399958dc686cd5c9b68ffe";
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
