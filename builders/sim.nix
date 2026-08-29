{ writeShellScriptBin
, rmExt

, qemu
, img
, smp
, qemu_cpu
}: writeShellScriptBin "${rmExt img.name}.sim" (toString [
  "${qemu}/bin/qemu-system-riscv64"
  "-bios ${img}"
  "-M nemu"
  "-nographic"
  "-m 8G"
  "-smp ${smp}"
  "-cpu ${qemu_cpu}"
  # "-plugin ${qemu}/lib/libprofiling.so,workload=${workload_name},intervals=${intervals},target=$out"
  "-icount shift=0,align=off,sleep=on"
])
