{ packages ? import <nixpkgs> {} }:
let
  baseShell = import ../../shells/shell.nix { inherit packages; };
in
packages.mkShell {
  inherit (baseShell) pure;
  
  buildInputs = baseShell.buildInputs ++ (with packages; [
    elixir
    erlang
    elixir-ls
  ] ++ packages.lib.optionals packages.stdenv.isLinux [
    inotify-tools
  ]);
  
  shellHook = ''
    ${baseShell.shellHook}
    echo "Elixir $(elixir --version | head -1) activated"
    echo "Erlang/OTP available"
  '';
}
