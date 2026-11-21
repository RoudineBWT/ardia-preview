{
  description = "Ardia Browser (Linux) Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      overlay = final: prev: {
        ardia = final.callPackage ./pkgs/ardia.nix {};
        ardia-nightly = final.callPackage ./pkgs/ardia-nightly.nix {};
      };
    in
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
      in
      {
        packages = {
          ardia = pkgs.ardia;
          ardia-nightly = pkgs.ardia-nightly;
          default = pkgs.ardia;
        };
      }
    ) // {
      overlays.default = overlay;

      nixosModules.default = { config, lib, pkgs, ... }: {
        nixpkgs.overlays = [ overlay ];
        imports = [ ./modules/ardia-browser.nix ];
      };
    };
}
