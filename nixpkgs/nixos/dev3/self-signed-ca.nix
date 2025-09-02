{ pkgs ? import <nixpkgs> { } }:

pkgs.runCommand "self-signed-ca"
{
  buildInputs = [ pkgs.mkcert ];
} ''
  mkdir $out
  export CAROOT=$out

  # Create a self-signed root CA certificate + key
  # Future `mkcert` invocations will use this CA to sign certificates (as long as the `$CAROOT` environment variable is set)
  mkcert -install
''
