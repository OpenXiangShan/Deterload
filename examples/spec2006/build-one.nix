{ runCommand
, callPackage
, writeShScript

, utils
, riscv64-libc
, riscv64-jemalloc
, src
, size
, enableVector
, optimize
, march
, testCase
}@args: let
  build-all = callPackage ./build-all.nix {
    inherit riscv64-libc riscv64-jemalloc;
    inherit src size enableVector optimize march;
  };
  build-one = runCommand "${build-all.name}.${utils.escapeName testCase}" {} ''
    mkdir -p $out
    cp -r ${build-all}/${testCase}/* $out/
  '';
in writeShScript "${build-one.name}" args ''
  cd ${build-one}/run
  sh ./run-spec.sh
''
