from common import CDot, CCluster, addNode, addEdge, add, set_colors

graph = CDot(label="Deterload Dependency Graph", splines="line")
graph.set_node_defaults(margin=0)

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
              self.busybox = addNode(self, "busybox")
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
        addEdge(self, self.dts, self.common_build, constraint=False)
        self.linux = add(self, self.Linux())
    def __init__(self, **args):
      CCluster.__init__(self, "gcpt", **args, penwidth=3)
      set_colors.gcpt(self)
      self.opensbi = add(self, self.OpenSBI())
  def __init__(self, **args):
    CCluster.__init__(self, "imgBuilder", **args)
    set_colors.imgBuilder(self)
    self.gcpt = add(self, self.GCPT())

class CptBuilder(CCluster):
  def __init__(self, **args):
    CCluster.__init__(self, "cptBuilder", **args)
    set_colors.cptBuilder(self)
    self.qemu = addNode(self, "qemu")
    self.nemu = addNode(self, "nemu")
    self.stage1_profiling = addNode(self, "stage1-profiling")
    self.simpoint = addNode(self, "simpoint")
    self.stage2_cluster = addNode(self, "stage2-cluster")
    self.stage3_checkpoint = addNode(self, "stage3-checkpoint")
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

benchmark = addNode(inputs, "benchmark"); set_colors.benchmark(benchmark)
addEdge(graph, benchmark, builder.imgBuilder.gcpt.opensbi.linux.initramfs.overlays.run_sh)
addEdge(graph, benchmark, builder.imgBuilder.gcpt.opensbi.linux.initramfs)

class Output(CCluster):
  def __init__(self, name, **args):
    CCluster.__init__(self, name, **args)
    set_colors.output(self)
    self._level0_ = add(self, CCluster("_level0_", label="", bgcolor="transparent", pencolor="transparent"))
    self.benchmark = addNode(self._level0_, "benchmark"); set_colors.benchmark(self.benchmark)

    self._level1_ = add(self, CCluster("_level1_", label="", bgcolor="transparent", pencolor="transparent"))
    addEdge(self, self._level0_, self._level1_, color="transparent")
    self.gen_init_cpio = addNode(self._level1_, "gen_init_cpio"); set_colors.gcpt(self.gen_init_cpio)
    self.initramfs_base = addNode(self._level1_, "initramfs_base"); set_colors.gcpt(self.initramfs_base)
    self.busybox = addNode(self._level1_, "busybox"); set_colors.gcpt(self.busybox)
    self.before_workload = addNode(self._level1_, "before_workload"); set_colors.gcpt(self.before_workload)
    self.nemu_trap = addNode(self._level1_, "nemu_trap"); set_colors.gcpt(self.nemu_trap)
    self.qemu_trap = addNode(self._level1_, "qemu_trap"); set_colors.gcpt(self.qemu_trap)
    self.initramfs_overlays = addNode(self._level1_, "initramfs_overlays"); set_colors.gcpt(self.initramfs_overlays)
    self.initramfs = addNode(self._level1_, "initramfs"); set_colors.gcpt(self.initramfs)

    self._level2_ = add(self, CCluster("_level2_", label="", bgcolor="transparent", pencolor="transparent"))
    addEdge(self, self._level1_, self._level2_, color="transparent")
    self.linux_common_build = addNode(self._level2_, "linux-common-build"); set_colors.gcpt(self.linux_common_build)
    self.linux = addNode(self._level2_, "linux"); set_colors.gcpt(self.linux)
    self.dts = addNode(self._level2_, "dts"); set_colors.gcpt(self.dts)
    self.opensbi_common_build = addNode(self._level2_, "opensbi-common-build"); set_colors.gcpt(self.opensbi_common_build)
    self.opensbi = addNode(self._level2_, "opensbi"); set_colors.gcpt(self.opensbi)
    self.gcpt = addNode(self._level2_, "gcpt"); set_colors.gcpt(self.gcpt)
    self.img = addNode(self._level2_, "img"); set_colors.imgBuilder(self.img)

    self._level3_ = add(self, CCluster("_level3_", label="", bgcolor="transparent", pencolor="transparent"))
    addEdge(self, self._level2_, self._level3_, color="transparent")
    self.nemu = addNode(self._level3_, "nemu"); set_colors.cptBuilder(self.nemu)
    self.qemu = addNode(self._level3_, "qemu"); set_colors.cptBuilder(self.qemu)
    self.simpoint = addNode(self._level3_, "simpoint"); set_colors.cptBuilder(self.simpoint)
    self.stage1_profiling = addNode(self._level3_, "stage1-profiling"); set_colors.cptBuilder(self.stage1_profiling)
    self.stage2_cluster = addNode(self._level3_, "stage2-cluster"); set_colors.cptBuilder(self.stage2_cluster)
    self.stage3_checkpoint = addNode(self._level3_, "stage3-checkpoint"); set_colors.cptBuilder(self.stage3_checkpoint)
    self.cpt = addNode(self._level3_, "cpt"); set_colors.cptBuilder(self.cpt)
    cpt_e = addEdge(self._level3_, self.stage3_checkpoint, self.cpt, constraint=False, dir="none")
    cpt_e.set("color", f"{cpt_e.get('color')}:transparent:{cpt_e.get('color')}")


output = add(outputs, Output("output"))
addEdge(graph, builder.cptBuilder.stage3_checkpoint, output)

from pydot import Graph, Node
def addFlatEdge(g: Graph, n1: Node|CCluster, n2: Node|CCluster, **args):
  # args["constraint"] = False
  args["dir"] = "none"
  e = addEdge(g, n1, n2, **args)
  if e.get("color"): e.set("color", e.get("color")+"11") # transparent #xxxxxx11
  else: e.set("color", "#00000011")
addFlatEdge(graph, benchmark, output.benchmark)
addFlatEdge(graph, builder.imgBuilder.gcpt.opensbi.linux.initramfs.base.gen_init_cpio, output.gen_init_cpio)
addFlatEdge(graph, builder.imgBuilder.gcpt.opensbi.linux.initramfs.base, output.initramfs_base)
addFlatEdge(graph, builder.imgBuilder.gcpt.opensbi.linux.initramfs.overlays.busybox, output.busybox)
addFlatEdge(graph, builder.imgBuilder.gcpt.opensbi.linux.initramfs.overlays.before_workload, output.before_workload)
addFlatEdge(graph, builder.imgBuilder.gcpt.opensbi.linux.initramfs.overlays.nemu_trap, output.nemu_trap)
addFlatEdge(graph, builder.imgBuilder.gcpt.opensbi.linux.initramfs.overlays.qemu_trap, output.qemu_trap)
addFlatEdge(graph, builder.imgBuilder.gcpt.opensbi.linux.initramfs.overlays, output.initramfs_overlays)
addFlatEdge(graph, builder.imgBuilder.gcpt.opensbi.linux.initramfs, output.initramfs)
addFlatEdge(graph, builder.imgBuilder.gcpt.opensbi.linux.common_build, output.linux_common_build)
addFlatEdge(graph, builder.imgBuilder.gcpt.opensbi.linux, output.linux)
addFlatEdge(graph, builder.imgBuilder.gcpt.opensbi.dts, output.dts)
addFlatEdge(graph, builder.imgBuilder.gcpt.opensbi.common_build, output.opensbi_common_build)
addFlatEdge(graph, builder.imgBuilder.gcpt.opensbi, output.opensbi)
addFlatEdge(graph, builder.imgBuilder.gcpt, output.gcpt)
addFlatEdge(graph, builder.imgBuilder, output.img)
addFlatEdge(graph, builder.cptBuilder.nemu, output.nemu)
addFlatEdge(graph, builder.cptBuilder.qemu, output.qemu)
addFlatEdge(graph, builder.cptBuilder.simpoint, output.simpoint)
addFlatEdge(graph, builder.cptBuilder.stage1_profiling, output.stage1_profiling)
addFlatEdge(graph, builder.cptBuilder.stage2_cluster, output.stage2_cluster)
addFlatEdge(graph, builder.cptBuilder.stage3_checkpoint, output.stage3_checkpoint)
addFlatEdge(graph, builder.cptBuilder.stage3_checkpoint, output.cpt)

overrideScope = addNode(outputs, "overrideScope", shape="oval", color="black", penwidth=2, fontsize=20)
addEdge(outputs, overrideScope, output, constraint=False)
addEdge(outputs, output.dts, overrideScope, color="transparent")
override = addNode(outputs, "override", shape="oval", color="black")
for attr in dir(output):
  obj = getattr(output, attr)
  if isinstance(obj, Node) and not attr.startswith("_"):
    addEdge(outputs, override, obj, constraint=False, color="#00000022")

# Tweaks
addEdge(graph, builder.imgBuilder, builder.cptBuilder.qemu, color="transparent")
for i in range(5):
  addEdge(graph, builder.cptBuilder.stage3_checkpoint, output.benchmark, color="transparent")

graph.write(__file__.replace("_dot.py", "_py.dot"))
