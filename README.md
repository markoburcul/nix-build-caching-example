# Nix build caching example

This repository demonstrates an issue where `nix build` does not fetch a package from the binary cache after the package was built and cached. Instead, it always attempts to build the package again.

## Problem Description

When running `nix build` after the package has been built and stored in binary cache, I expect that subsequent builds on a different machine fetch the cached package, provided the package's commit SHA matches.
However, even with caching enabled and proper configuration, nix build does not fetch the package from the cache. Instead, it rebuilds the package.

## Steps to reproduce

#### With a Cloned Repository
1. Clone the repository.
2. Build the package with full logs and verbosity:
```bash
nix build '.#test' -L --verbose
```

#### Without Cloning the Repository
Run the following command directly:
```bash
nix build 'git+https://github.com/markoburcul/nix-build-caching-example?rev=d35f6f19f7ce5b58c6a1f55e3ea16568933e5bc7#test' -L --debug
```

## Expected Behavior

After building and caching the package:
* Running nix build on a host that does not have the package should fetch it from the binary cache.


## Verifying Cache entry exists

To confirm that the package exists in the cache, use the following flake configuration:
```nix
{
  description = "Testing packages in cache";

  nixConfig = {
    extra-substituters = [ "https://nix-cache.status.im/" ];
    extra-trusted-public-keys = [ "nix-cache.status.im-1:x/93lOfLU+duPplwMSBR+OlY4+mo+dCN7n0mr4oPwgY=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/df27247e6f3e636c119e2610bf12d38b5e98cc79";
    cached-pkg.url = "git+https://github.com/markoburcul/nix-build-caching-example?rev=d35f6f19f7ce5b58c6a1f55e3ea16568933e5bc7";
  };

  outputs = { self, nixpkgs, cached-pkg }: 
  let
    stableSystems = [
      "x86_64-linux" "aarch64-linux"
      "x86_64-darwin" "aarch64-darwin"
      "x86_64-windows"
    ];
    forAllSystems = f: nixpkgs.lib.genAttrs stableSystems (system: f system);
    pkgsFor = forAllSystems (
      system: import nixpkgs {
        inherit system;
      }
    );
  in {
    devShells = forAllSystems (system: {
      default = pkgsFor.${system}.mkShell {
        nativeBuildInputs = [
          cached-pkg.packages.${system}.test
        ];
      };
    });
  };
}
```

Enter the development shell with:
```bash
nix develop -L --verbose
```

#### Expected Output
If the package is fetched from the cache, you should see output like:
```bash
nix develop -L --verbose
copying path '/nix/store/vs3gf5frf8x4nclqcwac4rv60ifkpz12-cached-package' from 'https://nix-cache.status.im'...
building '/nix/store/giy26sbn1x4z9zpxp90wbijr426bj9cj-nix-shell-env.drv'...
```