{
  description = "Flake to reproduce caching issues when building a package.";

  nixConfig = {
    extra-substituters = [ "https://nix-cache.status.im/" ];
    extra-trusted-public-keys = [ "nix-cache.status.im-1:x/93lOfLU+duPplwMSBR+OlY4+mo+dCN7n0mr4oPwgY=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/df27247e6f3e636c119e2610bf12d38b5e98cc79";
  };

  outputs = { self, nixpkgs }: 
  let
    stableSystems = [
      "x86_64-linux" "aarch64-linux"
      "x86_64-darwin" "aarch64-darwin"
      "x86_64-windows"
    ];

    forAllSystems = f: nixpkgs.lib.genAttrs stableSystems (system: f system);

    pkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
  in {
    packages = forAllSystems (system: let
      pkgs = pkgsFor.${system};
    in {
      test = pkgs.stdenv.mkDerivation {
        name = "cached-package";
        src = builtins.path { path = ./.; name = "nix-build-caching-example"; };
        phases = [ "buildPhase" "installPhase" ];
        buildPhase = ''
          dd if=/dev/zero of=largefile.dat  bs=24M  count=1 > largefile.dat
        '';
        installPhase = ''
          mkdir -p $out
          mv largefile.dat $out/
        '';
      };
    });
  };
}
