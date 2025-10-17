{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgsUnstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgsUnstable, rust-overlay, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        pkgsUnstable = import nixpkgsUnstable {
          inherit system overlays;
        };
        
        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          targets = [ "wasm32-wasip1" ];
        };
      in
      {
        packages.default = pkgs.rustPlatform.buildRustPackage rec {
          pname = "zellij-auto-tabname";
          version = "0.1.0";
          
          src = ./.;
          
          cargoLock.lockFile = ./Cargo.lock;
          
          nativeBuildInputs = [ rustToolchain ];
          
          buildPhase = ''
            cargo build --release --target wasm32-wasip1
          '';
          
          installPhase = ''
            mkdir -p $out
            cp target/wasm32-wasip1/release/*.wasm $out/zellij-auto-tabname.wasm
          '';
          
          # Skip check phase for WASM
          doCheck = false;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            rustToolchain
            cargo-watch
          ];
        };
      });
}