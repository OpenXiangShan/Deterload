{ pkgs ? import (fetchTarball {
    # Currently latest nixpkgs 24.11
    url = "https://github.com/NixOS/nixpkgs/archive/9c6b49aeac36e2ed73a8c472f1546f6d9cf1addc.tar.gz";
    sha256 = "0zwnaiw6cryrvwxxa96f72p4w75wq2miyi066f2sk8n7ivj0kxcb";
  }) {}
, lib ? pkgs.lib

/** ## Benchmarks Configuration */

/** ### Benchmarks Common Configuration */

/**
<arg>spec2006-extra-tag</arg>: Extra tag for SPEC CPU 2006 output names.
* **Type**: string
* **Default value**: `""`
* **Example**:
  Setting `spec2006-extra-tag = "miao"`,
  the checkpoint name changes from `spec2006_ref_..._1core_cpt` to `spec2006_ref_..._1core_miao_cpt`.
*/
, spec2006-extra-tag ? ""

/** ### OpenBLAS Configuration */

/**
<arg>openblas-extra-tag</arg>: Extra tag for OpenBLAS output names.
* **Type**: string
* **Default value**: `""`
* **Description**:
  Setting `openblas-extra-tag = "miao"`,
  the checkpoint name changes from `openblas_ref_..._1core_cpt` to `openblas_ref_..._1core_miao_cpt`.
*/
, openblas-extra-tag ? ""
}:
let
  raw' = import ./raw.nix { inherit pkgs; };
  utils = pkgs.callPackage ./utils.nix {};
in raw'.overrideScope (deterload: raw: {
  benchmarks = raw.benchmarks.overrideScope (self: super: {
    spec2006 = builtins.mapAttrs (testcase: value: value.override {
      inherit enableVector;
      src = spec2006-src;
      size = spec2006-size;
      optimize = spec2006-optimize;
      march = spec2006-march;
    }) (lib.filterAttrs (testcase: value:
      (spec2006-testcase-filter testcase) && (lib.isDerivation value))
    super.spec2006);

    openblas = super.openblas.override {
      TARGET = openblas-target;
    };
  });

  spec2006 = let tag = builtins.concatStringsSep "_" [
    "spec2006"
    spec2006-size
    (lib.removePrefix "${deterload.deterPkgs.riscv64-stdenv.targetPlatform.config}-" deterload.deterPkgs.riscv64-stdenv.cc.cc.name)
    spec2006-optimize
    spec2006-march
    deterload.benchmarks.riscv64-libc.pname
    deterload.benchmarks.riscv64-jemalloc.pname
    spec2006-extra-tag
  ]; in raw.spec2006 // (utils.wrap-l2 tag raw.spec2006);

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
