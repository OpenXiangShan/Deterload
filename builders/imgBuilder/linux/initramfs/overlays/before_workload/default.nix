{ stdenv
, riscv64-cc

, riscv64-libc
}:
stdenv.mkDerivation rec {
  name = "before_workload";
  src = builtins.fetchurl {
    url = "https://github.com/OpenXiangShan/riscv-rootfs/raw/da983ec95858dfd6f30e9feadd534b79db37e618/apps/before_workload/before_workload.c";
    sha256 = "09i7ad3cfvlkpwjfci9rhfhgx240v6ip5l1ns8yfhvxg7r6dcg6j";
  };
  dontUnpack = true;
  buildInputs = [
    riscv64-cc
    riscv64-libc
  ];
  # do not disable timer interrupts, so that we can run multithread workloads.
  postPatch = ''
    sed '/DISABLE_TIME_INTR/d' ${src} > ${name}.c
  '';
  buildPhase = ''
    riscv64-unknown-linux-gnu-gcc ${name}.c -o ${name} -static
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp ${name} $out/bin/
  '';
}
