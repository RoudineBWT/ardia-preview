{ callPackage }:
let
  # Filled in by update.sh (CI runs it every few hours)
  version = "0.2.49";
  hash = "0d1q7z7981k9xwnpd4vs21xdaskglqizyfaypvnzv538hmmhq6hz";
in
callPackage ./build-ardia.nix { } {
  pname = "ardia";
  inherit version hash;
  url = "https://github.com/ardia-browser/ardia/releases/download/v${version}/Ardia-${version}-linux-x64.deb";
}
