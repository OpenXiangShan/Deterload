{ stdenv
, riscv64-cc

, riscv64-libc
}:
stdenv.mkDerivation rec {
  name = "qemu_trap";
  src = builtins.fetchurl {
    url = "https://github.com/OpenXiangShan/riscv-rootfs/raw/da983ec95858dfd6f30e9feadd534b79db37e618/apps/qemu_trap/qemu_trap.c";
    sha256 = "0ray1gq841m8n6kyhp2ncj6aa7nw3lwwy3mfjh3848hsy7583vky";
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
