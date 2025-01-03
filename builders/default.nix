{ lib
, callPackage
, riscv64-pkgs
, riscv64-stdenv
}:
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
    inherit (self) riscv64-busybox before_workload qemu_trap nemu_trap benchmark;
  };

  initramfs = callPackage ./imgBuilder/linux/initramfs {
    inherit (self) benchmark;
    base = self.initramfs_base;
    overlays = self.initramfs_overlays;
  };

  linux-common-build = callPackage ./imgBuilder/linux/common-build.nix {};
  linux = callPackage ./imgBuilder/linux {
    inherit (self) initramfs;
    common-build = self.linux-common-build;
  };

  dts = callPackage ./imgBuilder/opensbi/dts {};
  opensbi-common-build = callPackage ./imgBuilder/opensbi/common-build.nix {
    inherit (self) dts;
  };
  opensbi = callPackage ./imgBuilder/opensbi {
    inherit (self) dts linux;
    common-build = self.opensbi-common-build;
  };
  gcpt_single_core = callPackage ./imgBuilder/gcpt/single_core.nix {
    inherit (self) opensbi;
  };
  gcpt_dual_core = callPackage ./imgBuilder/gcpt/dual_core.nix {
    inherit (self) opensbi;
  };
  gcpt = self.gcpt_single_core;
  img = callPackage ./imgBuilder {
    inherit (self) gcpt;
  };

  nemu = callPackage ./cptBuilder/nemu {};
  qemu = callPackage ./cptBuilder/qemu {};
  simpoint = callPackage ./cptBuilder/simpoint {};
  stage1-profiling = callPackage ./cptBuilder/1.profiling.nix {
    inherit (self) qemu nemu img;
  };
  stage2-cluster = callPackage ./cptBuilder/2.cluster.nix {
    inherit (self) simpoint stage1-profiling;
  };
  stage3-checkpoint = callPackage ./cptBuilder/3.checkpoint.nix {
    inherit (self) qemu nemu img stage2-cluster;
  };
  cpt = callPackage ./cptBuilder {
    inherit (self) stage3-checkpoint;
  };
})
