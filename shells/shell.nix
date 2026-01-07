{ packages ? import <nixpkgs> {} }:
packages.mkShell {
  buildInputs = with packages; [ 
    git
    docker
  ];
  
  pure = true;
  
  shellHook = ''
    echo "Welcome to functional-design-ppp development environment"
    echo "Git and Docker are available"
  '';
}
