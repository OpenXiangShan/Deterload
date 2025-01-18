{ writeText
, runCommand

, riscv64-busybox
, enableTrap
, before_workload
, qemu_trap
, nemu_trap
, trapCommand
, benchmark
, interactive
}@args:
let
  name = "initramfs-overlays";
  inittab = writeText "inittab" ''
    ::sysinit:/bin/busybox --install -s
    /dev/console::sysinit:-/bin/sh ${if interactive then "" else "/bin/run.sh"}
  '';
  run_sh = writeText "run.sh" ''
    ${if enableTrap then "before_workload" else ""}
    echo start
    ${benchmark}
    echo exit
    ${if enableTrap then trapCommand else ""}
  '';
in runCommand name {
  passthru = args // { inherit inittab run_sh; };
} (''
  mkdir -p $out/bin
  cp ${riscv64-busybox}/bin/busybox $out/bin/
  ln -s /bin/busybox $out/init

  mkdir -p $out/etc
  cp ${inittab} $out/etc/inittab

  mkdir -p $out/bin
  cp ${run_sh} $out/bin/run.sh
'' + (if enableTrap then ''
  cp ${before_workload}/bin/before_workload $out/bin/
  cp ${qemu_trap}/bin/qemu_trap $out/bin/
  cp ${nemu_trap}/bin/nemu_trap $out/bin/
'' else ""))
