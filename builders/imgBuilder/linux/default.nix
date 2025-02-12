{ lib

, riscv64-stdenv
, rmExt

, initramfs
, riscv64-linux
, linuxStructuredExtraConfig
, linuxKernelPatches
# The `override` is overriding the arguments of pkgs/os-specific/linux/kernel/mainline.nix
# The `argsOverride` attr is overriding the makeOverridable attrs of pkgs/os-specific/linux/kernel/generic.nix
# The `overrideAttrs` is overriding derivation built by pkgs/os-specific/linux/kernel/manual-config.nix
}@args: (riscv64-linux.override { argsOverride = {
  stdenv = riscv64-stdenv;
  kernelPatches = linuxKernelPatches;
  ignoreConfigErrors = false;
  enableCommonConfig = false;
  structuredExtraConfig = with lib.kernel; {
    INITRAMFS_SOURCE = freeform (builtins.toString initramfs);
  } // linuxStructuredExtraConfig;
};}).overrideAttrs (old: {
  name = "${rmExt initramfs.name}.linux";
  # `postInstall` in pkgs/os-specific/linux/kernel/manual-config.nix is depends on `isModular`, which is a good design.
  # However, pkgs/os-specific/linux/kernel/generic.nix hardcode the config = {CONFIG_MODULES = "y";} which is not generic and is a bad design.
  # Here, we correct the `postInstall` by checking linuxStructuredExtraConfig.
  postInstall = if linuxStructuredExtraConfig?MODULES
                && linuxStructuredExtraConfig.MODULES==lib.kernel.yes
  then old.postInstall else ''
    mkdir -p $dev
    cp vmlinux $dev/
  '';
  passthru = args // old.passthru;
})
