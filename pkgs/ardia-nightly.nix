{ callPackage }:
let
  # Filled in by update.sh (CI runs it every few hours)
  version = "0.2.49-nightly.1";
  hash = "1nvvm1dzsvp692glgs18mfz2qdn4gsrq0lmdiq4sbmvymi7xb5sq";
in
callPackage ./build-ardia.nix { } {
  pname = "ardia-nightly";
  inherit version hash;
  url = "https://github.com/ardia-browser/ardia/releases/download/v${version}/Ardia-${version}-linux-x64.deb";
}
