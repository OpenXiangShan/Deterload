{ pkgs ? import (fetchTarball {
    # Currently latest nixpkgs 24.11
    url = "https://github.com/NixOS/nixpkgs/archive/9c6b49aeac36e2ed73a8c472f1546f6d9cf1addc.tar.gz";
    sha256 = "0zwnaiw6cryrvwxxa96f72p4w75wq2miyi066f2sk8n7ivj0kxcb";
  }) {}
, lib ? pkgs.lib
}:
let
  raw' = import ./raw.nix { inherit pkgs; };
  utils = pkgs.callPackage ./utils.nix {};
in raw'.overrideScope (deterload: raw: {
  openblas = let tag = builtins.concatStringsSep "_" [
    "openblas"
    (lib.removePrefix "${deterload.deterPkgs.riscv64-stdenv.targetPlatform.config}-" deterload.deterPkgs.riscv64-stdenv.cc.cc.name)
    openblas-target
    deterload.benchmarks.riscv64-libc.pname
    openblas-extra-tag
  ]; in utils.wrap-l1 tag raw.openblas;

  nyancat = deterload.build (deterload.deterPkgs.writeShScript "nyancat-run" {} ''
    timeout 20 ${deterload.deterPkgs.riscv64-pkgs.nyancat}/bin/nyancat -t
  '');
})
