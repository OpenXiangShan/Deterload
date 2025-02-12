{ lib
, callPackage
, riscv64-pkgs
, riscv64-stdenv
}: {

/**
<arg>cores</arg>: Number of cores.
* **Type**: number-in-string
* **Default value**: `"1"`
* **Available values**: `"1"`, `"2"`.
  ([LibCheckpoint](https://github.com/OpenXiangShan/LibCheckpoint) is still in development,
  its stable configuration current only supports dual core)
* **Note**: `cpt-simulator`: qemu supports multiple cores, however, nemu only supports single core.
*/
cores ? "1"

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

/**
<arg>interactive</arg>: The image is interactive.
* **Type**: bool
* **Default value**: `false`
* **Note**: This argument only use together with `-A sim` to debug.
*/
, interactive ? false

/**
<arg>enableTrap</arg>: Whether to incorporate QEMU/NEMU trap in image.
* **Type**: bool
* **Default value**: `true`
*/
, enableTrap ? true

, ...
}:
assert lib.assertOneOf "cores" cores ["1" "2"];
assert lib.assertMsg (cpt-simulator=="nemu" -> cores=="1") "nemu only supports single core";
assert lib.assertOneOf "cpt-simulator" cpt-simulator ["qemu" "nemu"];
assert lib.assertOneOf "cpt-format" cpt-format ["gz" "zstd"];
assert lib.assertMsg (cpt-simulator=="qemu" -> cpt-format=="zstd") "qemu only supports cpt-format: zstd";
benchmark: lib.makeScope lib.callPackageWith (self: {
  inherit benchmark;
  gen_init_cpio = callPackage ./imgBuilder/linux/initramfs/base/gen_init_cpio {};
  initramfs_base = callPackage ./imgBuilder/linux/initramfs/base {
    inherit (self) gen_init_cpio;
  };

  riscv64-libc = riscv64-stdenv.cc.libc.static;
  riscv64-busybox = riscv64-pkgs.busybox.override {
    enableStatic = true;
    useMusl = true;
  };
  before_workload = callPackage ./imgBuilder/linux/initramfs/overlays/before_workload {
    inherit (self) riscv64-libc;
  };
  nemu_trap = callPackage ./imgBuilder/linux/initramfs/overlays/nemu_trap {
    inherit (self) riscv64-libc;
  };
  qemu_trap = callPackage ./imgBuilder/linux/initramfs/overlays/qemu_trap {
    inherit (self) riscv64-libc;
  };
  initramfs_overlays = callPackage ./imgBuilder/linux/initramfs/overlays {
    inherit (self) riscv64-busybox before_workload benchmark;
    after_workload = self."${cpt-simulator}_trap";
    inherit interactive enableTrap;
  };

  initramfs = callPackage ./imgBuilder/linux/initramfs {
    inherit (self) benchmark;
    base = self.initramfs_base;
    overlays = self.initramfs_overlays;
  };

  linux = callPackage ./imgBuilder/linux {
    inherit (self) initramfs;
    riscv64-linux = riscv64-pkgs.linux;
  };

  dts = callPackage ./imgBuilder/opensbi/dts { inherit cores; };
  opensbi = callPackage ./imgBuilder/opensbi { inherit (self) dts linux; };
  gcpt_single_core = callPackage ./imgBuilder/gcpt/single_core.nix {
    inherit (self) opensbi;
  };
  gcpt_dual_core = callPackage ./imgBuilder/gcpt/dual_core.nix {
    inherit (self) opensbi;
  };
  gcpt = if cores=="1" then self.gcpt_single_core
    else if cores=="2" then self.gcpt_dual_core
    else throw "gcpt only support 1 or 2 cores";
  img = callPackage ./imgBuilder {
    inherit (self) gcpt;
  };

  nemu = callPackage ./cptBuilder/nemu {};
  qemu = callPackage ./cptBuilder/qemu {};
  simpoint = callPackage ./cptBuilder/simpoint {};
  stage1-profiling = callPackage ./cptBuilder/1.profiling.nix {
    inherit (self) qemu nemu img;
    workload_name = "miao";
    intervals = cpt-intervals;
    simulator = cpt-simulator;
    profiling_log = "profiling.log";
    smp = cores;
  };
  stage2-cluster = callPackage ./cptBuilder/2.cluster.nix {
    inherit (self) simpoint stage1-profiling;
    maxK = cpt-maxK;
  };
  stage3-checkpoint = callPackage ./cptBuilder/3.checkpoint.nix {
    inherit (self) qemu nemu img stage2-cluster;
    workload_name = "miao";
    intervals = cpt-intervals;
    simulator = cpt-simulator;
    checkpoint_format = cpt-format;
    checkpoint_log = "checkpoint.log";
    smp = cores;
  };
  # TODO: name
  #   workload_name = "miao";
  #   intervals = cpt-intervals;
  #   simulator = cpt-simulator;
  #   checkpoint_format = cpt-format;
  #   checkpoint_log = "checkpoint.log";
  #   smp = cores;
  #   maxK
  cpt = callPackage ./cptBuilder {
    inherit (self) stage3-checkpoint;
  };

  sim = callPackage ./sim.nix {
    inherit (self) qemu img;
    smp = cores;
  };
})
