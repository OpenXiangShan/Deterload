{ stdenv
, runCommand
, writeText
, bc
, flex
, bison

, riscv64-cc
, rmExt
, initramfs
, common-build
}@args: stdenv.mkDerivation (finalAttrs: {
  name = "${rmExt initramfs.name}.linux";
  src = builtins.fetchurl {
    url = "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.10.7.tar.xz";
    sha256 = "1adkbn6dqbpzlr3x87a18mhnygphmvx3ffscwa67090qy1zmc3ch";
  };
  buildInputs = [
    bc
    flex
    bison
    riscv64-cc
  ];

  patches = [
    # Shutdown QEMU when the kernel raises a panic.
    # This feature prevents the kernel from entering an endless loop,
    # allowing for quicker identification of failed SPEC CPU testCases.
    ./panic_shutdown.patch
  ];

  defconfig = runCommand "defconfig" {} ''
    path=$(tar tf ${finalAttrs.src} | grep arch/riscv/configs/defconfig)
    tar xf ${finalAttrs.src} $path -O > $out
  '';
  baseconfig = runCommand "baseconfig" {} ''
    sed '/=m/d' ${finalAttrs.defconfig} | sed '/NFS/d' | sed '/CONFIG_FTRACE/d' > $out
  '';
  # TODO: auto deduplicate and merge xiangshan_defconfig to baseconfig
  xiangshan_defconfig = writeText "xiangshan_defconfig" ''
    ${builtins.readFile finalAttrs.baseconfig}
    CONFIG_KVM=y
    CONFIG_LOG_BUF_SHIFT=15
    CONFIG_NONPORTABLE=y
    CONFIG_RISCV_SBI_V01=y
    CONFIG_SERIO_LIBPS2=y
    CONFIG_SERIAL_UARTLITE=y
    CONFIG_SERIAL_UARTLITE_CONSOLE=y
    CONFIG_HVC_RISCV_SBI=y
    CONFIG_STACKTRACE=y
    CONFIG_RCU_CPU_STALL_TIMEOUT=300
    CONFIG_CMDLINE="norandmaps"
    CONFIG_INITRAMFS_SOURCE="${initramfs}"
  '';

  buildPhase = ''
    export ARCH=riscv
    export CROSS_COMPILE=riscv64-unknown-linux-gnu-

    export KBUILD_BUILD_TIMESTAMP=@0
    ln -s ${finalAttrs.xiangshan_defconfig} arch/riscv/configs/xiangshan_defconfig
    make xiangshan_defconfig
    make -j $NIX_BUILD_CORES
  '';
  installPhase = ''
    cp arch/riscv/boot/Image $out
  '';
  passthru = args;
})
