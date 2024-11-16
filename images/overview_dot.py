from common import CDot, CCluster, add, addNode, addEdge, set_colors

graph = CDot(label="Deterload\nWorkflow Overview")

benchmark = addNode(graph, "benchmark")
set_colors.benchmark(benchmark)

class Builder(CCluster):
  def __init__(self):
    CCluster.__init__(self, "builder"); set_colors.builder(self)
    self.imgBuilder = addNode(self, "imgBuilder"); set_colors.gcpt(self.imgBuilder)
    self.cptBuilder = addNode(self, "cptBuilder"); set_colors.cptBuilder(self.cptBuilder)
    addEdge(self, self.imgBuilder, self.cptBuilder)
builder = add(graph, Builder())
addEdge(graph, benchmark, builder.imgBuilder)

checkpoints = addNode(graph, "checkpoints"); set_colors.checkpoints(checkpoints)
addEdge(graph, builder.cptBuilder, checkpoints)

graph.write(__file__.replace("_dot.py", "_py.dot"))
