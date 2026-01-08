{
  description = "Functional Design PPP - Development environments managed with Nix";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        packages = nixpkgs.legacyPackages.${system};
      in
      {
        devShells = {
          default = import ./shells/shell.nix { inherit packages; };
          node = import ./environments/node/shell.nix { inherit packages; };
          clojure = import ./environments/clojure/shell.nix { inherit packages; };
          scala = import ./environments/scala/shell.nix { inherit packages; };
          fsharp = import ./environments/fsharp/shell.nix { inherit packages; };
          haskell = import ./environments/haskell/shell.nix { inherit packages; };
          rust = import ./environments/rust/shell.nix { inherit packages; };
        };
      }
    );
}
