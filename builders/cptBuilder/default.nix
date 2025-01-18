{ stage3-checkpoint
, utils
, rmExt
}: let
  stage2-cluster = stage3-checkpoint.stage2-cluster;
  stage1-profiling = stage2-cluster.stage1-profiling;
in stage3-checkpoint.overrideAttrs (old: {
  name = "${rmExt stage1-profiling.img.name}." + (builtins.concatStringsSep "_" [
    stage3-checkpoint.simulator
    (utils.metricPrefix stage3-checkpoint.intervals)
    "maxK${stage2-cluster.maxK}"
    "${stage3-checkpoint.smp}core"
    "cpt"
  ]);
  passthru = {
    inherit stage1-profiling stage2-cluster stage3-checkpoint;
    qemu = stage1-profiling.qemu;
    nemu = stage1-profiling.nemu;
    simpoint = stage2-cluster.simpoint;
  };
})
