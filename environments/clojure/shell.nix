{ packages ? import <nixpkgs> {} }:
let
  baseShell = import ../../shells/shell.nix { inherit packages; };
in
packages.mkShell {
  inherit (baseShell) pure;
  
  buildInputs = baseShell.buildInputs ++ (with packages; [
    clojure
    leiningen
    clojure-lsp
  ]);
  
  shellHook = ''
    ${baseShell.shellHook}
    echo "Clojure $(clojure --version | head -1) activated"
    echo "Leiningen $(lein version | head -1) available"
  '';
}
