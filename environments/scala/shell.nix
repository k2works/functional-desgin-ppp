{ packages ? import <nixpkgs> {} }:
let
  baseShell = import ../../shells/shell.nix { inherit packages; };
in
packages.mkShell {
  inherit (baseShell) pure;
  
  buildInputs = baseShell.buildInputs ++ (with packages; [
    scala_3
    sbt
    metals
    coursier
  ]);
  
  shellHook = ''
    ${baseShell.shellHook}
    echo "Scala $(scala -version 2>&1 | head -1) activated"
    echo "sbt $(sbt --version 2>&1 | grep sbt | head -1) available"
  '';
}
