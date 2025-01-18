{ runCommand
, rmExt

, qemu
, nemu
, img
, stage2-cluster
, intervals
, workload_name
, checkpoint_format
, simulator
, checkpoint_log
, smp
}@args:
let
  qemuCommand = [
    "${qemu}/bin/qemu-system-riscv64"
    "-bios ${img}"
    "-M nemu,simpoint-path=${stage2-cluster},workload=.,cpt-interval=${intervals},output-base-dir=$out,config-name=${workload_name},checkpoint-mode=SimpointCheckpoint"
    "-nographic"
    "-m 8G"
    "-smp ${smp}"
    "-cpu rv64,v=true,vlen=128,h=true,sv39=true,sv48=false,sv57=false,sv64=false"
    "-icount shift=0,align=off,sleep=off"
  ];

  nemuCommand = [
    "${nemu}/bin/riscv64-nemu-interpreter"
    "${img}"
    "-b"
    "-D $out"
    "-C checkpoint"
    "-w ."
    "-S ${stage2-cluster}"
    "--cpt-interval ${intervals}"
    "--checkpoint-format ${checkpoint_format}"
  ];

in runCommand "${rmExt stage2-cluster.name}.${smp}core_3_checkpoint" {
  passthru = args;
} ''
  mkdir -p $out

 ${if simulator == "qemu" then ''
    echo "Executing QEMU command: ${builtins.toString qemuCommand}"
    ${builtins.toString qemuCommand} | tee $out/${checkpoint_log}
  '' else ''
    echo "Executing NEMU command: ${builtins.toString nemuCommand}"
    ${builtins.toString nemuCommand} | tee $out/${checkpoint_log}
  ''}
''
