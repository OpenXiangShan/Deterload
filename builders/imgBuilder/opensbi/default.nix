{ stdenv
, python3
, enableOverlayFS ? true
, fuse-overlayfs
, vmTools

, riscv64-cc
, rmExt
, linux
, dts
, common-build
}@args: let overlayfsDisabled = stdenv.mkDerivation {
  name = "${rmExt linux.name}.opensbi";

  src = common-build;

  buildInputs = [
    python3
    riscv64-cc
  ];

  makeFlags = [
    "CROSS_COMPILE=riscv64-unknown-linux-gnu-"
    "PLATFORM=generic"
    "FW_FDT_PATH=${dts}/xiangshan.dtb"
    "FW_PAYLOAD_PATH=${linux}"
  ];
  buildPhase = ''
    patchShebangs .

    # Default FW_PAYLOAD memory layout:
    # Refers to https://github.com/riscv-software-src/opensbi/blob/master/platform/generic/objects.mk
    # and https://docs.xiangshan.cc/zh-cn/latest/tools/opensbi-kernel-for-xs/
    # FW_PAYLOAD_OFFSET=0x100000
    # -------------------------------------------------------------------
    # | gcpt  |  opensbi firmware      | payload e.g. linux Image | FDT |
    # -------------------------------------------------------------------
    # |       |                        |                          |
    # |OFFSET | FW_PAYLOAD_OFFSET      |                          |
    # |(1MB)  | (default:0x100000=1MB) |                          |
    # |                                                           |
    # |---------- FW_PAYLOAD_FDT_OFFSET --------------------------|
    #             (default:0x2200000=2MB+32MB)
    # Noted: In 64bit system, the FW_PAYLOAD_OFFSET and FW_PAYLOAD_FDT_OFFSET must be aligned to 2MB.

    # Calculate the FW_PAYLOAD_FDT_OFFSET
    ALIGN=0x200000
    FW_PAYLOAD_OFFSET=0x100000
    IMAGE_SIZE=$(ls -l ${linux} | awk '{print $5}')
    IMAGE_END=$((FW_PAYLOAD_OFFSET + IMAGE_SIZE))
    IMAGE_END_ALIGNED=$(( (IMAGE_END + ALIGN-1) & ~(ALIGN-1) ))
    IMAGE_END_ALIGNED_HEX=$(printf "0x%x" $IMAGE_END_ALIGNED)
    echo FW_PAYLOAD_FDT_OFFSET=$IMAGE_END_ALIGNED_HEX

    make -j $NIX_BUILD_CORES $makeFlags \
      FW_PAYLOAD_OFFSET=$FW_PAYLOAD_OFFSET \
      FW_PAYLOAD_FDT_OFFSET=$IMAGE_END_ALIGNED_HEX
  '';

  installPhase = ''
    # runInLinuxVM will auto create dir $out
    rm -rf $out
    cp build/platform/generic/firmware/fw_payload.bin $out
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
  memSize = 1024;
}));
in if enableOverlayFS then overlayfsEnabled else overlayfsDisabled
