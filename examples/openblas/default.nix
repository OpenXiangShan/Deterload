{ lib ? import <nixpkgs/lib>
/**
<arg>TARGET</arg>: CPU TARGET for OpenBLAS.
* **Type**: string
* **Default value**: "RISCV64_GENERIC"`
* **Available values**: `"RISCV64_GENERIC"`, `"RISCV64_ZVL128B"`, `"RISCV64_ZVL256B"`
*/
, TARGET ? "RISCV64_GENERIC"
, ...
}@args:
assert lib.assertOneOf "TARGET" TARGET ["RISCV64_GENERIC" "RISCV64_ZVL128B" "RISCV64_ZVL256B"];
let
  deterload = import ../.. args;
  openblas = deterload.deterPkgs.callPackage ./package.nix {
    inherit TARGET;
    riscv64-libfortran = deterload.deterPkgs.riscv64-pkgs.gfortran.cc;
    riscv64-libc = deterload.deterPkgs.riscv64-stdenv.cc.libc.static;
  };
in deterload.build openblas
