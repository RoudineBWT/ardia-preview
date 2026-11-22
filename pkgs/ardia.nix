{ callPackage }:
let
  # Filled in by update.sh (CI runs it every few hours)
  version = "0.2.48";
  hash = "0fp2jblzhccb0wa7q6xmwp17zz435ppi79d510nd9npfh5vk3qqn";
in
callPackage ./build-ardia.nix { } {
  pname = "ardia";
  inherit version hash;
  url = "https://github.com/ardia-browser/ardia/releases/download/v${version}/Ardia-${version}-linux-x64.deb";
}
