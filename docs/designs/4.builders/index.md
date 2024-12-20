# 🔨构建框架（Builders）

![](./images/overview_py.svg)

![](./images/deps_py.svg)

TODO:

The project uses Nix to manage dependencies and build the necessary components:

- QEMU: Modified version of QEMU with checkpoint and profiling capabilities
- Simpoint: Simpoint is a tool for profiling and checkpointing in XiangShan
- OpenSBI: RISC-V OpenSBI firmware
- Linux: Custom Linux kernel image
- Profiling tools: Scripts and plugins for analyzing checkpoint data
