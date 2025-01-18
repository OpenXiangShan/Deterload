{ lib
, callPackage
, riscv64-pkgs
, riscv64-stdenv
}: lib.makeScope lib.callPackageWith (self: {
  spec2006 = callPackage ./spec2006 {
    inherit (self) riscv64-libc riscv64-jemalloc;
  };

  openblas = callPackage ./openblas {
    inherit (self) riscv64-libc riscv64-libfortran;
  };
})
