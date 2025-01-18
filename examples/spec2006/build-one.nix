{ runCommand
, callPackage
, writeShScript

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
  build-one = runCommand "${testCase}" {} ''
    mkdir -p $out
    cp -r ${build-all}/${testCase}/* $out/
  '';
in writeShScript "${testCase}-run" args ''
  cd ${build-one}/run
  sh ./run-spec.sh
''
