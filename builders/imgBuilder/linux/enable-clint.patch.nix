rec {
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
}
