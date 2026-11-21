{ callPackage }:
let
  # Filled in by update.sh (CI runs it every few hours)
  version = "0.2.47-nightly.9";
  hash = "1avfhgi5ks6cn7qsl0370f3z26ml1b9krammxk8pkq29dxp8dfmj";
in
callPackage ./build-ardia.nix { } {
  pname = "ardia-nightly";
  inherit version hash;
  url = "https://github.com/ardia-browser/ardia/releases/download/v${version}/Ardia-${version}-linux-x64.deb";
}
