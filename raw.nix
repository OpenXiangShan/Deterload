{ pkgs ? import (fetchTarball { # TODO: remove, as it move into examples.nix
    url = "https://github.com/NixOS/nixpkgs/archive/e8c38b73aeb218e27163376a2d617e61a2ad9b59.tar.gz";
    sha256 = "1n6gdjny8k5rwkxh6sp1iwg1y3ni1pm7lvh9sisifgjb18jdvzbm";
  }) {}
}:
pkgs.lib.makeScope pkgs.lib.callPackageWith (raw/*deterload-scope itself*/: {
  benchmarks = raw.deterPkgs.callPackage ./benchmarks {};

  spec2006 = builtins.mapAttrs (name: benchmark: (raw.build benchmark))
    (pkgs.lib.filterAttrs (n: v: (pkgs.lib.isDerivation v)) raw.benchmarks.spec2006);

  openblas = raw.build raw.benchmarks.openblas;
})
