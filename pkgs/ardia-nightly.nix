{ callPackage }:
let
  # Filled in by update.sh (CI runs it every few hours)
  version = "0.0.0";
  hash = "0000000000000000000000000000000000000000000000000000";
in
callPackage ./build-ardia.nix { } {
  pname = "ardia-nightly";
  inherit version hash;
  url = "https://github.com/ardia-browser/ardia/releases/download/v${version}/Ardia-${version}-linux-x64.deb";
}
