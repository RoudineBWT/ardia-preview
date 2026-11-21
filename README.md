# Ardia Browser Flake

A **Nix Flake** packaging the Linux (`x86_64-linux`) builds of [Ardia](https://github.com/ardia-browser/ardia), the Chromium browser with Arc's sidebar and Dia's polish, from the official `.deb` published on its GitHub releases.

Packages:

- **`ardia`**: latest stable release that ships a Linux `.deb`.
- **`ardia-nightly`**: latest nightly that ships a Linux `.deb`.

Some Ardia releases only contain macOS assets, so `update.sh` always picks the newest release of the channel that actually has `Ardia-<version>-linux-x64.deb`.

## Usage

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    ardia.url = "github:roudinebwt/ardia-preview";
    ardia.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, ardia, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        ardia.nixosModules.default
        { programs.ardia.enable = true; }
        # or: programs.ardia-nightly.enable = true;
      ];
    };
  };
}
```

Ad-hoc: `nix run github:roudinebwt/ardia-preview#ardia`

## How it works

1. `update.sh` queries the GitHub releases API, selects the newest stable/nightly release with a Linux `.deb`, prefetches it with `nix-prefetch-url` and rewrites `version`/`hash` in `pkgs/ardia*.nix`.
2. `check-release.yml` (hourly) tracks the latest tags in `.last-ardia-*` and triggers `update.yml`, which also runs every 6 hours, verifies the build and commits.
3. `build-and-cache.yml` builds both packages on `pkgs/` changes.

> The first run of **Update Ardia** (Actions › Run workflow) fills in the real version and hash: the files in `pkgs/` ship with a placeholder.

## License

Packaging code: MIT. Ardia is GPL-3.0 (Apache-2.0 for its own sources), see its repository.
