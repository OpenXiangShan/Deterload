{ stdenv
, riscv64-cc

, riscv64-libc
}:
stdenv.mkDerivation rec {
  name = "nemu_trap";
  src = builtins.fetchurl {
    url = "https://github.com/OpenXiangShan/riscv-rootfs/raw/da983ec95858dfd6f30e9feadd534b79db37e618/apps/trap/trap.c";
    sha256 = "05rlbicdbz9zdv6a82bjm7xp13rzb84sj9pkb5cqmizmlsmf3rzj";
  };
  dontUnpack = true;
  buildInputs = [
    riscv64-cc
    riscv64-libc
  ];
  buildPhase = ''
    riscv64-unknown-linux-gnu-gcc ${src} -o after_workload -static
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp after_workload $out/bin/
  '';
}
