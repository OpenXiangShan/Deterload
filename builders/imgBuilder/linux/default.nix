{ stdenv
, bc
, flex
, bison
# * With OverlayFS disabled, the default `unpackPhase` will copy the entire `common-build`,
#   which involves approximately 1.7GB of disk writes.
#   When building N linux images simultaneously, the disk write throughput becomes N*1.7GB.
# * With OverlayFS enabled, the build processes are overlaied onto 1.7GB `common-build`,
#   resulting in minimal disk writes.
#   However, because of the nix sandbox, overlayfs cannot be used directly in nix build processes,
#   we utilize `runInLinuxVM` to work around this limitation.
#   (For more details, see https://discourse.nixos.org/t/using-fuse-inside-nix-derivation/8534.)
#   * If your nixbld* users have access to /dev/kvm,
#     there will be no noticable performance degradation.
#   * If your nixbld* users lack access to /dev/kvm,
#     QEMU will fall back to translation mode (TCG),
#     which is approximately 100 times slower.
, enableOverlayFS ? true
, fuse-overlayfs
, vmTools

, riscv64-cc
, rmExt
, initramfs
, common-build
}@args: let overlayfsDisabled = stdenv.mkDerivation {
  name = "${rmExt initramfs.name}.linux";
  src = common-build;
  buildInputs = [
    bc
    flex
    bison
    riscv64-cc
  ];

  buildPhase = ''
    export ARCH=riscv
    export CROSS_COMPILE=riscv64-unknown-linux-gnu-

    # Prepare benchmark config
    TESTCASE_DEFCONFIG=arch/riscv/configs/xiangshan_benchmark_defconfig
    cat arch/riscv/configs/xiangshan_defconfig > $TESTCASE_DEFCONFIG
    echo CONFIG_INITRAMFS_SOURCE=\"${initramfs}\" >> $TESTCASE_DEFCONFIG

    export KBUILD_BUILD_TIMESTAMP=@0
    make xiangshan_benchmark_defconfig
    make -j $NIX_BUILD_CORES
  '';
  installPhase = ''
    # runInLinuxVM will auto create dir $out
    rm -rf $out
    cp arch/riscv/boot/Image $out
  '';
  passthru = args;
};
overlayfsEnabled = vmTools.runInLinuxVM (overlayfsDisabled.overrideAttrs (old: {
  unpackPhase = ''
    mkdir workdir
    mkdir upperdir
    mkdir overlaydir
    /run/modprobe fuse
    ${fuse-overlayfs}/bin/fuse-overlayfs -o lowerdir=${old.src},workdir=workdir,upperdir=upperdir overlaydir
    cd overlaydir
  '';
  memSize = 2048;
}));
in if enableOverlayFS then overlayfsEnabled else overlayfsDisabled
