{ callPackage

, utils
, riscv64-libc
, riscv64-jemalloc
, src
, size
, enableVector
, optimize
, march
}: let
  testCases = [
    "400.perlbench"
    "401.bzip2"
    "403.gcc"
    "410.bwaves"
    "416.gamess"
    "429.mcf"
    "433.milc"
    "434.zeusmp"
    "435.gromacs"
    "436.cactusADM"
    "437.leslie3d"
    "444.namd"
    "445.gobmk"
    "447.dealII"
    "450.soplex"
    "453.povray"
    "454.calculix"
    "456.hmmer"
    "458.sjeng"
    "459.GemsFDTD"
    "462.libquantum"
    "464.h264ref"
    "465.tonto"
    "470.lbm"
    "471.omnetpp"
    "473.astar"
    "481.wrf"
    "482.sphinx3"
    "483.xalancbmk"
  ];
in builtins.listToAttrs (
  builtins.map (testCase: {
    # change `.` to `_`, e.g. "403.gcc" to "403_gcc"
    name = utils.escapeName testCase;
    value = callPackage ./build-one.nix {
      inherit riscv64-libc riscv64-jemalloc;
      inherit src size enableVector optimize march;
      inherit testCase;
    };
  }) testCases
)
