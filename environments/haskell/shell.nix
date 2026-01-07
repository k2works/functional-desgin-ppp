{ packages ? import <nixpkgs> {} }:
let
  baseShell = import ../../shells/shell.nix { inherit packages; };
in
packages.mkShell {
  inherit (baseShell) pure;
  
  buildInputs = baseShell.buildInputs ++ (with packages; [
    ghc
    cabal-install
    haskell-language-server
    zlib
    pkg-config
  ]);
  
  shellHook = ''
    ${baseShell.shellHook}
    echo "Haskell (GHC $(ghc --version | cut -d' ' -f8)) activated"
    echo "ghci available for REPL"
    echo "Run 'cabal update' first if package index is missing"
  '';
}
