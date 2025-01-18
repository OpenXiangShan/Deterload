{ stdenv
, fetchFromGitHub
, riscv64-cc
, riscv64-fortran
, writeShScript

, riscv64-libc
, riscv64-libfortran
, TARGET
}: let drv = stdenv.mkDerivation {
  pname = "openblas";
  version = "0.3.28";
  src = fetchFromGitHub {
    owner = "OpenMathLib";
    repo = "OpenBLAS";
    rev = "v0.3.28";
    hash = "sha256-430zG47FoBNojcPFsVC7FA43FhVPxrulxAW3Fs6CHo8=";
  };

  depsBuildBuild = [
    riscv64-cc
    riscv64-fortran
    riscv64-libc
  ];

  buildPhase = let
    makeFlags_common = let
      prefix = "${riscv64-cc}/bin/riscv64-unknown-linux-gnu-";
    in [
      "CC=${prefix}gcc"
      "AR=${prefix}ar"
      "AS=${prefix}as"
      "LD=${prefix}ld"
      "RANLIB=${prefix}ranlib"
      "NM=${prefix}nm"
      "FC=${riscv64-fortran}/bin/riscv64-unknown-linux-gnu-gfortran"

      "BINARY=64"
      "TARGET=${TARGET}"
      "DYNAMIC_ARCH=false"
      "CROSS=true"
      "HOSTCC=cc"
      # "ARCH=riscv64"
      # TODO: "USE_OPENMP=true"
      "NUM_THREADS=64"
    ];
    makeFlags1 = makeFlags_common ++ [
      "NO_STATIC=0"
      "NO_SHARED=1"
      # not run tests, only compilation
      "shared"
    ];
    makeFlags2 = makeFlags_common ++ [
      # benchmark/Makefile uses `cc` to compile and link, does not use `ld` directly.
      # Therefore, benchmark/Makefile does not receive LDFLAGS, only receives CFLAGS
      "CFLAGS=\"-L${riscv64-libfortran}/lib -L${riscv64-libc}/lib -static\""
      "FFLAGS=\"-L${riscv64-libfortran}/lib -L${riscv64-libc}/lib -static\""
      "-C benchmark"
    ];
  in ''
    # 1. compile libopenblas
    make ${builtins.toString makeFlags1}
    # 2. compile benchmark
    make ${builtins.toString makeFlags2}
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp benchmark/*.goto $out/bin/
  '';
  doCheck = false;
}; in writeShScript "openblas-run" {} ''
  for goto in ${drv}/bin/*.goto; do
    echo running $goto
    $goto
  done
''

