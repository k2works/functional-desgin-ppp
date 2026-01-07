{ packages ? import <nixpkgs> {} }:
let
  baseShell = import ../../shells/shell.nix { inherit packages; };
in
packages.mkShell {
  inherit (baseShell) pure;
  
  buildInputs = baseShell.buildInputs ++ (with packages; [
    dotnet-sdk_8
    fantomas
  ]);
  
  shellHook = ''
    ${baseShell.shellHook}
    echo "F# (.NET $(dotnet --version)) activated"
    echo "dotnet fsi available for REPL"
  '';
}
