{ runCommand
, lib

, qemu
, nemu
, img
, workload_name
, intervals
, simulator
, profiling_log
}@args:
let
  name = "${lib.removeSuffix ".gcpt" img.name}.1_profiling";

  qemuCommand = [
    "${qemu}/bin/qemu-system-riscv64"
    "-bios ${img}"
    "-M nemu"
    "-nographic"
    "-m 8G"
    "-smp 1"
    "-cpu rv64,v=true,vlen=128,h=false,sv39=true,sv48=false,sv57=false,sv64=false"
    "-plugin ${qemu}/lib/libprofiling.so,workload=${workload_name},intervals=${intervals},target=$out"
    "-icount shift=0,align=off,sleep=off"
  ];

  nemuCommand = [
    "${nemu}/bin/riscv64-nemu-interpreter"
    "${img}"
    "-b"
    "-D $out"
    "-C ${name}"
    "-w ${workload_name}"
    "--simpoint-profile"
    "--cpt-interval ${intervals}"
  ];

in runCommand name {
  passthru = args;
} ''
  mkdir -p $out

  ${if simulator == "qemu" then ''
    echo ${builtins.toString qemuCommand}
    ${builtins.toString qemuCommand} | tee $out/${profiling_log}
  '' else ''
    echo ${builtins.toString nemuCommand}
    ${builtins.toString nemuCommand} | tee $out/${profiling_log}
    cp $out/${name}/${workload_name}/simpoint_bbv.gz $out/
  ''}
''