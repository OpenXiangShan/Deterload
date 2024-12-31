{ pkgs ? import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/e8c38b73aeb218e27163376a2d617e61a2ad9b59.tar.gz";
    sha256 = "1n6gdjny8k5rwkxh6sp1iwg1y3ni1pm7lvh9sisifgjb18jdvzbm";
  }) {}
, lib ? pkgs.lib

/**
<style>
arg {
  font-family: mono;
  font-size: 1.2em;
  font-weight: bold;
}
arg::before {
  content: "• "
}
</style>
*/
/** ## Common Configuration */

/**
<arg>cc</arg>: Compiler Collection used for compiling RISC-V binaries.
* **Type**: string
* **Default value**: `"gcc14"`
* **Available values**: Prefix of any nixpkgs-supported <u>xxx</u>Stdenv.
  To list available <u>xxx</u>Stdenv:
  ```bash
  nix-instantiate --eval -E 'let pkgs=import <nixpkgs> {}; in builtins.filter (x: pkgs.lib.hasSuffix "Stdenv" x)(builtins.attrNames pkgs)'
  ```
* **TODO**: Currently only supports GCC's stdenv.
  LLVM's fortran compiler (flang) is needed to support Clang's stdenv.
  Preliminary experiments with riscv64-jemalloc show that Clang provides better auto-vectorization than GCC.
*/
, cc ? "gcc14"

/**
<arg>cores</args>: Number of cores.
* **Type**: number-in-string
* **Default value**: `"1"`
* **Available values**: `"1"`, `"2"`.
  ([LibCheckpoint](https://github.com/OpenXiangShan/LibCheckpoint) is still in development,
  its stable configuration current only supports dual core)
* **Note**: `cpt-simulator`: qemu supports multiple cores, however, nemu only supports single core.
*/
, cores ? "1"

/** ## Benchmarks Configuration */

/** ### Benchmarks Common Configuration */

/**
<arg>enableVector</arg>: Controls compiler's auto-vectorization during benchmark builds.
* **Type**: bool
* **Default value**: `false`
*/
, enableVector ? false

/** ### SPEC CPU 2006 Configuration */

/**
<arg>spec2006-extra-tag</arg>: Extra tag for SPEC CPU 2006 output names.
* **Type**: string
* **Default value**: `""`
* **Example**:
  Setting `spec2006-extra-tag = "miao"`,
  the checkpoint name changes from `spec2006_ref_..._1core_cpt` to `spec2006_ref_..._1core_miao_cpt`.
*/
, spec2006-extra-tag ? ""

/**
<arg>spec2006-src</arg>: Path to SPEC CPU 2006 source code.
* <span style="background-color:yellow;">**Note**</span>:
  As SPEC CPU 2006 is a proprietary benchmark, it cannot be incorporated in Deterload's source code.
  You need to obatin the its source code through legal means.
* **Type**: path
* **Supported path types**:
  * Path to a folder:

    The folder must be the root directory of the SPEC CPU 2006 source code.

    Example:
    ```nix
    spec2006-src = /path/miao/spec2006;
    ```

    Required folder structure:
    ```
    /path/miao/spec2006
    ├── benchspec/
    ├── bin/
    ├── tools/
    ├── shrc
    ...
    ```

  * Path to a tar file:

    The tar file must contain a folder named exactly `spec2006`,
    with the same folder structure as above.

    Supported tar file extensions:
    * gzip (.tar.gz, .tgz or .tar.Z)
    * bzip2 (.tar.bz2, .tbz2 or .tbz)
    * xz (.tar.xz, .tar.lzma or .txz)

    Example:
    ```nix
    spec2006-src = /path/of/spec2006.tar.gz;
    ```

  * For more information about supported path types,
    please see [Nixpkgs Manual: The unpack phase](https://nixos.org/manual/nixpkgs/stable/#ssec-unpack-phase).
*/
, spec2006-src ? throw "Please specify <spec2006-src> the path of spec2006, for example: /path/of/spec2006.tar.gz"

/**
<arg>spec2006-size</arg>: Input size for SPEC CPU 2006.
* **Type**: string
* **Default value**: `"ref"`
* **Available values**: `"ref"`, `"train"`, `"test"`
*/
, spec2006-size ? "ref"

/**
<arg>spec2006-optimize</arg>: Compiler optimization flags for SPEC CPU 2006.
* **Type**: string
* **Default value**: `"-O3 -flto"`
*/
, spec2006-optimize ? "-O3 -flto"

/**
<arg>spec2006-march</arg>: Compiler's `-march` option for SPEC CPU 2006.
* **Type**: string
* **Default value**: "rv64gc${lib.optionalString enableVector "v"}"
* **Description**: The default value depends on `enableVector`:
  * If `enableVector` is `true`, the default value is `"rv64gc"`,
  * If `enableVector` is `false`, the default value is `"rv64gcv"`.
*/
, spec2006-march ? "rv64gc${lib.optionalString enableVector "v"}"

/**
<arg>spec2006-testcase-filter</arg>: Function to filter SPEC CPU 2006 testcases.
* **Type**: string -> bool
* **Default value**: `testcase: true`
* **Description**: `spec2006-testcase-filter` takes a testcase name as input and returns:
  * `true`: include this testcase
  * `false`: exclude this testcase
* **Example 1**: Include all testcases:
  ```nix
  spec2006-testcase-filter = testcase: true;
  ```
* **Example 2**: Only include `403_gcc`:
  ```nix
  spec2006-testcase-filter = testcase: testcase == "403_gcc";
  ```
* **Example 3**: Exlcude `464_h264ref` and `465_tonto`:
  ```nix
  spec2006-testcase-filter = testcase: !(builtins.elem testcase [
    "464_h264ref"
    "465_tonto"
  ]);
  ```
*/
, spec2006-testcase-filter ? testcase: true

/** ### OpenBLAS Configuration */

/**
<arg>openblas-extra-tag</arg>: Extra tag for OpenBLAS output names.
* **Type**: string
* **Default value**: `""`
* **Description**:
  Setting `openblas-extra-tag = "miao"`,
  the checkpoint name changes from `openblas_ref_..._1core_cpt` to `openblas_ref_..._1core_miao_cpt`.
*/
, openblas-extra-tag ? ""

/**
<arg>openblas-target</arg>: CPU TARGET for OpenBLAS.
* **Type**: string
* **Default value**: `if enableVector then "RISCV64_ZVL128B" else "RISCV64_GENERIC"`
* **Available values**: `"RISCV64_GENERIC"`, `"RISCV64_ZVL128B"`, `"RISCV64_ZVL256B"`
* **Description**: The default value depends on `enableVector`:
  * If `enableVector` is `true`, the default value is `"RISCV64_ZVL128B"`,
  * If `enableVector` is `false`, the default value is `"RISCV64_GENERIC"`.
*/
, openblas-target ? if enableVector then "RISCV64_ZVL128B" else "RISCV64_GENERIC"

/** ## Builders Configuration */

/**
<arg>cpt-maxK</arg>: maxK value for all benchmarks in checkpoint generation.
* **Type**: number-in-string
* **Default value**: `"30"`
* **Description**:
  maxK is a parameter in SimPoint algorithm used during the checkpoint's clustering stage.
  `cpt-maxK` will set maxK for all benchmarks' clustering stage in checkpoints generation.
  To override the maxK for specific benchmarks, refer to the `cpt-maxK-bmk` argument.
*/
, cpt-maxK ? "30"

/**
<arg>cpt-maxK-bmk</arg>: maxK values for specifed benchmarks in checkpoint generation.
* **Type**: attr (`{ benchmark-name = number-in-string; ... }`)
* **Default value**: `{ "483.xalancbmk" = "100"; }`
* **Description**:
  `cpt-maxK-bmk` sets the the maxK for specifed benchmarks.
  Unspecified benchmarks will use the value from `cpt-maxK`.
  This attribute consists of key-value pairs where:
  * Key: benchmark name.
  * Value: number in a string (same format as `cpt-maxK`).
* **FAQ 1**: Why set maxK of 483.xalancbmk to 100?
  * Setting maxK to 30 for 483.xalancbmk resulted in unstable scores.
* **FAQ 2**: How to retreive the benchmark name?
  * Use the following commands:
    ```bash
    # Try `pname` first, if not available, use `name`.
    nix-instantiate --eval -A <benchmark>.benchmark.pname
    nix-instantiate --eval -A <benchmark>.benchmark.name
    ```

    Examples:

    ```bash
    # To retreive the name of openblas benchmark, first try
    nix-instantiate --eval -A openblas.benchmark.pname
    # Output: "openblas"
    ```
    ```bash
    # To retreive the name of 483_xalancbmk benchmark, first try
    nix-instantiate --eval -A spec2006.483_xalancbmk.benchmark.pname
    # Error: attribute 'pname' in selection path 'spec2006.483_xalancbmk.benchmark.pname' not found Did you mean name?
    # Second try
    nix-instantiate --eval -A spec2006.483_xalancbmk.benchmark.name
    # Output: "483.xalancbmk"
    ```
*/
, cpt-maxK-bmk ? {
    # TODO: rename xxx.yyyyyyy to xxx_yyyyyy ?
    "483.xalancbmk" = "100";
  }

/**
<arg>cpt-intervals</arg>: Number of BBV interval instructions in checkpoint generation.
* **Type**: number-in-string
* **Default value**: `"20000000"`
*/
, cpt-intervals ? "20000000"

/**
<arg>cpt-simulator</arg>: Simulator used in checkpoint generation.
* **Type**: string
* **Default value**: `"qemu"`
* **Available values**: `"qemu"`, `"nemu"`
* **Note**:
  Though nemu is faster than qemu,

  * nemu does not support multiple cores,
  * the current version of nemu is not deterministic.

  Therefore, qemu is chosen as the default simulator.
  For more information, refer to [OpenXiangShan/Deterload Issue #8: nemu is not deterministic](https://github.com/OpenXiangShan/Deterload/issues/8).
*/
, cpt-simulator ? "qemu"

/**
<arg>cpt-format</arg>: Compress format of output checkpoints.
* **Type**: string
* **Default value**: `"zstd"`
* **Available value**: `"zstd"`, `"gz"`
* **Note**: nemu supports both formats; however, qemu only supports zstd format.
*/
, cpt-format ? "zstd"
}:
assert pkgs.pkgsCross.riscv64 ? "${cc}Stdenv";
assert lib.assertOneOf "cores" cores ["1" "2"];
assert lib.assertMsg (cpt-simulator=="nemu" -> cores=="1") "nemu only supports single core";
assert lib.assertOneOf "spec2006-size" spec2006-size ["ref" "train" "test"];
assert lib.assertOneOf "openblas-target" openblas-target ["RISCV64_GENERIC" "RISCV64_ZVL128B" "RISCV64_ZVL256B"];
assert lib.assertOneOf "cpt-simulator" cpt-simulator ["qemu" "nemu"];
assert lib.assertOneOf "cpt-format" cpt-format ["gz" "zstd"];
assert lib.assertMsg (cpt-simulator=="qemu" -> cpt-format=="zstd") "qemu only supports cpt-format: zstd";
let
  raw = import ./raw.nix { inherit pkgs; };
  getName = p: if (p?pname) then p.pname else p.name;
  escapeName = lib.converge (name:
    builtins.replaceStrings
      [" " "." "-" "__"]
      [""  ""  "_" "_" ]
  name);
  /*set -> set: filter derivations in a set*/
  filterDrvs = set: lib.filterAttrs (n: v: (lib.isDerivation v)) set;
  /*string -> set -> set:
    wrap-l2 prefix {
      a={x=drv0; y=drv1; z=drv2; w=0;};
      b={x=drv3; y=drv4; z=drv5; w=1;};
      c={x=drv6; y=drv7; z=drv8; w=2;};
    }
    returns {
      x=linkFarm "${prefix}_x" [drv0 drv3 drv6];
      y=linkFarm "${prefix}_y" [drv1 drv4 drv7];
      z=linkFarm "${prefix}_z" [drv2 drv5 drv8];
    }*/
  wrap-l2 = prefix: attrBuildResults: let
    /*mapToAttrs (name: {inherit name; value=...}) ["a", "b", "c", ...]
      returns {x=value0; b=value1; c=value2; ...} */
    mapToAttrs = func: list: builtins.listToAttrs (builtins.map func list);
    /*attrDrvNames {
        a={x=drv0; y=drv1; z=drv2; w=0;};
        b={x=drv3; y=drv4; z=drv5; w=1;};
        c={x=drv6; y=drv7; z=drv8; w=2;};
      }
      returns ["x" "y" "z"] */
    attrDrvNames = set: builtins.attrNames (filterDrvs (builtins.head (builtins.attrValues set)));
  in mapToAttrs (name/*represents the name in builders/default.nix, like img, cpt, ...*/: {
    inherit name;
    value = pkgs.linkFarm (escapeName "${prefix}_${name}") (
      lib.mapAttrsToList (testCase: buildResult: {
        name = testCase;
        path = buildResult."${name}";
      }) attrBuildResults);
  }) (attrDrvNames attrBuildResults);

  wrap-l1 = prefix: buildResult: builtins.mapAttrs (name: value:
    if lib.isDerivation value then pkgs.symlinkJoin {
      name = escapeName "${prefix}_${name}";
      paths = [value];
      passthru = lib.optionalAttrs (value?passthru) value.passthru;
    } else value
  ) buildResult;

  metricPrefix = input: let
    num =  if builtins.isInt input then input
      else if builtins.isString input then lib.toInt input
      else throw "metricPrefix: unspported type of ${input}";
    K = 1000;
    M = 1000 * K;
    G = 1000 * M;
    T = 1000 * G;
    P = 1000 * T;
    E = 1000 * P;
  in     if num < K then "${toString  num     }"
    else if num < M then "${toString (num / K)}K"
    else if num < G then "${toString (num / M)}M"
    else if num < T then "${toString (num / G)}G"
    else if num < P then "${toString (num / T)}T"
    else if num < E then "${toString (num / P)}P"
    else                 "${toString (num / E)}E"
  ;
in raw.overrideScope (r-self: r-super: {
  riscv64-scope = r-super.riscv64-scope.overrideScope (self: super: {
    riscv64-stdenv = super.riscv64-pkgs."${cc}Stdenv";
  });

  benchmarks = r-super.benchmarks.overrideScope (bmks-self: bmks-super: {
    spec2006 = builtins.mapAttrs (testcase: value: value.override {
      inherit enableVector;
      src = spec2006-src;
      size = spec2006-size;
      optimize = spec2006-optimize;
      march = spec2006-march;
    }) (lib.filterAttrs (testcase: value:
      (spec2006-testcase-filter testcase) && (lib.isDerivation value))
    bmks-super.spec2006);

    openblas = bmks-super.openblas.override {
      TARGET = openblas-target;
    };
  });

  build = benchmark: (r-super.build benchmark).overrideScope (b-self: b-super: {
    initramfs_overlays = b-super.initramfs_overlays.override {
      trapCommand = "${cpt-simulator}_trap";
    };
    gcpt = if cores=="1" then b-super.gcpt_single_core
      else if cores=="2" then b-super.gcpt_dual_core
      else b-super.gcpt;

    stage1-profiling = b-super.stage1-profiling.override {
      workload_name = "miao";
      intervals = cpt-intervals;
      simulator = cpt-simulator;
      profiling_log = "profiling.log";
    };
    stage2-cluster = b-super.stage2-cluster.override {
      maxK = if (cpt-maxK-bmk ? "${getName benchmark}")
        then cpt-maxK-bmk."${getName benchmark}"
        else cpt-maxK;
    };
    stage3-checkpoint = b-super.stage3-checkpoint.override {
      workload_name = "miao";
      intervals = cpt-intervals;
      simulator = cpt-simulator;
      checkpoint_format = cpt-format;
      checkpoint_log = "checkpoint.log";
    };
  });

  spec2006 = let tag = builtins.concatStringsSep "_" [
    "spec2006"
    spec2006-size
    (lib.removePrefix "${r-self.riscv64-scope.riscv64-stdenv.targetPlatform.config}-" r-self.riscv64-scope.riscv64-stdenv.cc.cc.name)
    spec2006-optimize
    spec2006-march
    r-self.benchmarks.riscv64-libc.pname
    r-self.benchmarks.riscv64-jemalloc.pname
    cpt-simulator
    (metricPrefix cpt-intervals)
    (let suffix = lib.optionalString (builtins.any
      (x: x.stage2-cluster.maxK!=cpt-maxK)
      (builtins.attrValues r-super.spec2006)
    ) "x"; in"maxK${cpt-maxK}${suffix}")
    "${cores}core"
    spec2006-extra-tag
  ]; in r-super.spec2006 // (wrap-l2 tag r-super.spec2006);

  openblas = let tag = builtins.concatStringsSep "_" [
    "openblas"
    (lib.removePrefix "${r-self.riscv64-scope.riscv64-stdenv.targetPlatform.config}-" r-self.riscv64-scope.riscv64-stdenv.cc.cc.name)
    openblas-target
    r-self.benchmarks.riscv64-libc.pname
    cpt-simulator
    (metricPrefix cpt-intervals)
    "maxK${r-super.openblas.stage2-cluster.maxK}"
    "${cores}core"
    openblas-extra-tag
  ]; in wrap-l1 tag r-super.openblas;
})
