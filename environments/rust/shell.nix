{ packages ? import <nixpkgs> {} }:
let
  baseShell = import ../../shells/shell.nix { inherit packages; };
in
packages.mkShell {
  inherit (baseShell) pure;
  
  buildInputs = baseShell.buildInputs ++ (with packages; [
    rustc
    cargo
    rust-analyzer
    clippy
    rustfmt
  ]);
  
  shellHook = ''
    ${baseShell.shellHook}
    echo "Rust $(rustc --version) activated"
    echo "Cargo $(cargo --version) available"
  '';
}
