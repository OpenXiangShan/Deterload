from pydot import Dot, Edge, Node, Graph, Cluster
from typing import TypeVar
T = TypeVar("T")

def safe_set(args: dict, key: str, value):
  if key not in args: args[key] = value
class CCluster(Cluster): # Connectable Cluster
  def __init__(self, name, **args):
    safe_set(args, "label", name)
    safe_set(args, "penwidth", 2)
    Cluster.__init__(self, name, **args)
    self._connect_node_ = addNode(self, "_connect_node_", label="",
                                  shape="none", width=0, height=0, margin=0)
class CDot(Dot): # Compound Dot
  def __init__(self, *vargs, **args):
    args["compound"] = True
    safe_set(args, "bgcolor", "transparent")
    Dot.__init__(self, *vargs, **args)
    self.set_node_defaults(shape="box")
    self.set_edge_defaults(color="#00000044")

def addNode(g: Graph|CCluster, name, **args):
  if "label" not in args: args["label"] = name
  n = Node(g.get_name()+name, **args)
  g.add_node(n)
  return n
def addEdge(g: Graph, n1: Node|CCluster, n2: Node|CCluster, **args):
  # auto edge color
  if isinstance(n1, Node)  and n1.get("color"):    safe_set(args, "color", n1.get("color"))
  if isinstance(n1, Graph) and n1.get("pencolor"): safe_set(args, "color", n1.get("pencolor"))
  # auto edge width
  if n1.get("penwidth"): safe_set(args, "penwidth", n1.get("penwidth"))

  if isinstance(n1, CCluster): l = n1._connect_node_; args["ltail"] = n1.get_name()
  else: l = n1
  if isinstance(n2, CCluster): r = n2._connect_node_; args["lhead"] = n2.get_name()
  else: r = n2
  g.add_edge(Edge(l.get_name(), r.get_name(), **args))
def addCluster(g: Graph|CCluster, name, **args):
  s=CCluster(name, **args)
  g.add_subgraph(s)
  return s
def add(g: Graph, item: T) -> T:
  if   isinstance(item, Node):     g.add_node(item)
  elif isinstance(item, Edge):     g.add_edge(item)
  elif isinstance(item, CCluster): g.add_subgraph(item)
  else: raise Exception(f"add(g, item): unknown item type [{type(item)}]")
  return item

class _Colors_:
  def set(self, item: Node|Graph, background, boundary):
    if isinstance(item, Node):
      item.set("style", "filled") # TODO: safe add style
      item.set("fillcolor", background)
      item.set("color", boundary)
    elif isinstance(item, Graph):
      item.set("bgcolor", background)
      item.set("pencolor", boundary)
  def benchmark  (self, item: Node|Graph): self.set(item, "#D5E8D4", "#82B366")
  def builder    (self, item: Node|Graph): self.set(item, "#F5F5F5", "#666666")
  def imgBuilder (self, item: Node|Graph): self.set(item, "#CCE5FF", "#666666")
  def cptBuilder (self, item: Node|Graph): self.set(item, "#F8CECC", "#B85450")
  def gcpt       (self, item: Node|Graph): self.set(item, "#DAE8FC", "#6C8EBF")
  def checkpoints(self, item: Node|Graph): self.set(item, "#FFE6CC", "#D79B00")
set_colors = _Colors_()
