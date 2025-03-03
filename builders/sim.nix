{ writeShellScriptBin
, rmExt

, qemu
, img
, smp
}: writeShellScriptBin "${rmExt img.name}.sim" (toString [
  "${qemu}/bin/qemu-system-riscv64"
  "-bios ${img}"
  "-M nemu"
  "-nographic"
  "-m 8G"
  "-smp ${smp}"
  "-cpu rv64,v=true,vlen=128,h=true,sv39=true,sv48=false,sv57=false,sv64=false"
  # "-plugin ${qemu}/lib/libprofiling.so,workload=${workload_name},intervals=${intervals},target=$out"
  "-icount shift=0,align=off,sleep=on"
])
