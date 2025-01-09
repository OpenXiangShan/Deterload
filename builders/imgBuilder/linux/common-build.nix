{ stdenv
, writeText
, runCommand
, bc
, flex
, bison

, riscv64-cc
}:
let
  name = "linux-common-build";
  # currently lastest stable linux version
  version = "6.10.7";
  sha256 = "1adkbn6dqbpzlr3x87a18mhnygphmvx3ffscwa67090qy1zmc3ch";
in stdenv.mkDerivation (finalAttrs: {
  inherit name;
  src = builtins.fetchurl {
    url = "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${version}.tar.xz";
    inherit sha256;
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
    tar xf ${finalAttrs.src} linux-${version}/arch/riscv/configs/defconfig -O > $out
  '';
  baseconfig = runCommand "baseconfig" {} ''
    sed '/=m/d' ${finalAttrs.defconfig} | sed '/NFS/d' | sed '/CONFIG_FTRACE/d' > $out
  '';
  # TODO: auto deduplicate and merge xiangshan_defconfig to baseconfig
  xiangshan_defconfig = writeText "xiangshan_defconfig" ''
    ${builtins.readFile finalAttrs.baseconfig}
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
  '';

  # TODO: add same gcc optimization cflags as benchmarks?
  buildPhase = ''
    export ARCH=riscv
    export CROSS_COMPILE=riscv64-unknown-linux-gnu-

    export KBUILD_BUILD_TIMESTAMP=@0
    ln -s ${finalAttrs.xiangshan_defconfig} arch/riscv/configs/xiangshan_defconfig
    make xiangshan_defconfig
    make -j $NIX_BUILD_CORES

    # Perform a minor cleanup to trigger the next make -j command for generating a new image.
    rm arch/riscv/boot/Image*
    rm .config
  '';
  installPhase = ''
    mkdir -p $out
    cp -r ./* $out/
  '';
  dontFixup = true;
})
