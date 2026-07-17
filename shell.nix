{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildImputs = [ pkgs.python3 ];
}
