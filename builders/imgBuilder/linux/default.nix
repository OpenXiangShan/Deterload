{ lib

, riscv64-stdenv
, rmExt

, initramfs
, riscv64-linux
, enableModules ? false
# The `override` is overriding the arguments of pkgs/os-specific/linux/kernel/mainline.nix
# The `argsOverride` attr is overriding the makeOverridable attrs of pkgs/os-specific/linux/kernel/generic.nix
# The `overrideAttrs` is overriding derivation built by pkgs/os-specific/linux/kernel/manual-config.nix
}@args: (riscv64-linux.override { argsOverride = {
  stdenv = riscv64-stdenv;
  kernelPatches = [rec {
    name = "enable-clint";
    patch = builtins.toFile name ''
      --- a/drivers/clocksource/Kconfig
      +++ b/drivers/clocksource/Kconfig
      @@ -643,7 +643,7 @@
       	  required for all RISC-V systems.

       config CLINT_TIMER
      -	bool "CLINT Timer for the RISC-V platform" if COMPILE_TEST
      +	bool "CLINT Timer for the RISC-V platform"
       	depends on GENERIC_SCHED_CLOCK && RISCV
       	select TIMER_PROBE
       	select TIMER_OF
    '';
    extraConfig = ''
      CLINT_TIMER y
    '';
  }];
  ignoreConfigErrors = false;
  enableCommonConfig = false;
  structuredExtraConfig = with lib.kernel; {
    MODULES = if enableModules then yes else no;
    NFS_FS = no;
    KVM = yes;
    NONPORTABLE = yes;
    RISCV_SBI_V01 = yes;
    SERIO_LIBPS2 = yes;
    SERIAL_UARTLITE = yes;
    SERIAL_UARTLITE_CONSOLE = yes;
    HVC_RISCV_SBI = yes;
    STACKTRACE = yes;
    RCU_CPU_STALL_TIMEOUT = freeform "300";
    CMDLINE = freeform "norandmaps";
    INITRAMFS_SOURCE = freeform (builtins.toString initramfs);
  };};
}).overrideAttrs (old: {
  name = "${rmExt initramfs.name}.linux";
  # `postInstall` in pkgs/os-specific/linux/kernel/manual-config.nix is depends on `isModular`, which is a good design.
  # However, pkgs/os-specific/linux/kernel/generic.nix hardcode the config = {CONFIG_MODULES = "y";} which is not generic and is a bad design.
  # Here, we correct the `postInstall` by checking enableModules.
  postInstall = if enableModules then old.postInstall else ''
    mkdir -p $dev
    cp vmlinux $dev/
  '';
  passthru = args // old.passthru;
})
