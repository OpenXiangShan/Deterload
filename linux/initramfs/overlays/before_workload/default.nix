let
  name = "before_workload";
  pkgs = import <nixpkgs> {};
in pkgs.stdenv.mkDerivation rec {
  inherit name;
  src = builtins.fetchurl {
    url = "https://github.com/OpenXiangShan/riscv-rootfs/raw/da983ec95858dfd6f30e9feadd534b79db37e618/apps/before_workload/before_workload.c";
    sha256 = "09i7ad3cfvlkpwjfci9rhfhgx240v6ip5l1ns8yfhvxg7r6dcg6j";
  };
  dontUnpack = true;
  buildInputs = [
    pkgs.pkgsCross.riscv64.stdenv.cc
    pkgs.pkgsCross.riscv64.stdenv.cc.libc.static
  ];
  buildPhase = ''
    riscv64-unknown-linux-gnu-gcc ${src} -o ${name} -static
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp ${name} $out/bin/
  '';
}