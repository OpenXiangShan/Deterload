from common import CDot, CCluster, addNode, addEdge, add, set_colors

graph = CDot(label="Deterministic Checkpoint Dependency Graph", splines="line")

class ImgBuilder(CCluster):
  class GCPT(CCluster):
    class OpenSBI(CCluster):
      class Linux(CCluster):
        class InitRamFs(CCluster):
          class Base(CCluster):
            def __init__(self, **args):
              CCluster.__init__(self, "base", **args)
              self.gen_init_cpio = addNode(self, "gen_init_cpio")
              self.cpio_list = addNode(self, "cpio_list")
          class Overlays(CCluster):
            def __init__(self, **args):
              CCluster.__init__(self, "overlays", **args)
              self.before_workload = addNode(self, "before_workload")
              self.qemu_trap = addNode(self, "qemu_trap")
              self.nemu_trap = addNode(self, "nemu_trap")
              self.inittab = addNode(self, "inittab")
              self.run_sh = addNode(self, "run_sh", label="run.sh")
          def __init__(self, **args):
            CCluster.__init__(self, "initramfs", **args)
            self.base = add(self, self.Base())
            self.overlays = add(self, self.Overlays())
        def __init__(self, **args):
          CCluster.__init__(self, "linux", **args)
          self.initramfs = add(self, self.InitRamFs())
          self.common_build = addNode(self, "common-build")
      def __init__(self, **args):
        CCluster.__init__(self, "opensbi", **args)
        self.dts = addNode(self, "dts")
        self.common_build = addNode(self, "common-build")
        addEdge(self, self.dts, self.common_build)
        self.linux = add(self, self.Linux())
    def __init__(self, **args):
      CCluster.__init__(self, "gcpt", **args, penwidth=3)
      set_colors.gcpt(self)
      self.opensbi = add(self, self.OpenSBI())
  def __init__(self, **args):
    CCluster.__init__(self, "imgBuilder", **args)
    set_colors.imgBuilder(self)
    self.riscv64_cc = addNode(self, "riscv64-cc")
    self.riscv64_libc_static = addNode(self, "riscv64-libc-static")
    self.riscv64_busybox = addNode(self, "riscv64-busybox")
    self.gcpt = add(self, self.GCPT())
    addEdge(self, self.riscv64_cc, self.gcpt.opensbi.common_build)
    addEdge(self, self.riscv64_cc, self.gcpt.opensbi.linux.common_build)
    for i in (self.riscv64_cc, self.riscv64_libc_static):
      overlays = self.gcpt.opensbi.linux.initramfs.overlays
      for j in (overlays.before_workload, overlays.qemu_trap, overlays.nemu_trap):
        addEdge(self, i, j)
    addEdge(self, self.riscv64_busybox, self.gcpt.opensbi.linux.initramfs.overlays)

class CptBuilder(CCluster):
  def __init__(self, **args):
    CCluster.__init__(self, "cptBuilder", **args)
    set_colors.cptBuilder(self)
    self.riscv64_cc = addNode(self, "riscv64-cc")
    self.qemu = addNode(self, "qemu")
    self.nemu = addNode(self, "nemu")
    self.stage1_profiling = addNode(self, "stage1_profiling")
    self.simpoint = addNode(self, "simpoint")
    self.stage2_cluster = addNode(self, "stage2_cluster")
    self.stage3_checkpoint = addNode(self, "stage3_checkpoint")
    addEdge(self, self.riscv64_cc, self.nemu)
    addEdge(self, self.qemu, self.stage1_profiling)
    addEdge(self, self.nemu, self.stage1_profiling)
    addEdge(self, self.simpoint, self.stage2_cluster)
    addEdge(self, self.stage1_profiling, self.stage2_cluster)
    addEdge(self, self.qemu, self.stage3_checkpoint)
    addEdge(self, self.nemu, self.stage3_checkpoint)
    addEdge(self, self.stage2_cluster,self.stage3_checkpoint)

class Builder(CCluster):
  def __init__(self, **args):
    CCluster.__init__(self, "builder", **args)
    set_colors.builder(self)
    self.imgBuilder = add(self, ImgBuilder())
    self.cptBuilder = add(self, CptBuilder())
    addEdge(self, self.imgBuilder.gcpt, self.cptBuilder.stage1_profiling)
    addEdge(self, self.imgBuilder.gcpt, self.cptBuilder.stage3_checkpoint)
builder = add(graph, Builder())

inputs = add(graph, CCluster("inputs", label="", pencolor="transparent"))
outputs = add(graph, CCluster("outputs", label="", pencolor="transparent"))

pkgs = addNode(inputs, "pkgs")
addEdge(graph, pkgs, builder.imgBuilder.riscv64_cc)
addEdge(graph, pkgs, builder.imgBuilder.riscv64_libc_static)
addEdge(graph, pkgs, builder.imgBuilder.riscv64_busybox)
addEdge(graph, pkgs, builder.cptBuilder.riscv64_cc)

class Benchmark(CCluster):
  def __init__(self, name, **args):
    CCluster.__init__(self, name, **args)
    set_colors.benchmark(self)
    self.run = addNode(self, "run")
benchmark = add(inputs, Benchmark("benchmark"))
addEdge(graph, benchmark.run, builder.imgBuilder.gcpt.opensbi.linux.initramfs.overlays.run_sh)
addEdge(graph, benchmark, builder.imgBuilder.gcpt.opensbi.linux.initramfs)

checkpoints = addNode(graph, "checkpoints", penwidth=2)
set_colors.checkpoints(checkpoints)
addEdge(outputs, builder.cptBuilder.stage3_checkpoint, checkpoints)

# Tweaks
addEdge(graph, builder.imgBuilder.gcpt.opensbi.common_build, builder.cptBuilder.riscv64_cc, color="transparent")

graph.write(__file__.replace("_dot.py", "_py.dot"))