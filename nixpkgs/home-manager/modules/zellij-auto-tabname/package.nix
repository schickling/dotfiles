{ lib
, stdenv
, rustPlatform
, cargo
, rustc
}:

stdenv.mkDerivation rec {
  pname = "zellij-auto-tabname";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [ 
    cargo 
    rustc
    rustPlatform.cargoSetupHook
  ];

  buildPhase = ''
    runHook preBuild
    
    # Set up cargo home
    export CARGO_HOME=$(mktemp -d cargo-home.XXXXXX)
    
    # Copy the lockfile
    cp ${./Cargo.lock} Cargo.lock
    
    # Build for wasm32-wasip1 target
    echo "Building WASM plugin..."
    
    # Check if the rust toolchain supports wasm32-wasip1
    if rustc --print target-list | grep -q wasm32-wasip1; then
      echo "wasm32-wasip1 target is available"
      cargo build --release --target wasm32-wasip1
    else
      echo "Error: wasm32-wasip1 target not available in rustc"
      echo "Available targets:"
      rustc --print target-list | grep wasm
      exit 1
    fi
    
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out
    cp target/wasm32-wasip1/release/zellij_auto_tabname.wasm $out/
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "Zellij plugin for automatic tab naming";
    license = licenses.mit;
  };
}