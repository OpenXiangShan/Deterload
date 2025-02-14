<!-- ANCHOR: main -->
# 确定性负载（Deterload）

**确定性负载**（Deterload）是一个为香山生态（包括
[香山处理器](https://docs.xiangshan.cc)、
[香山NEMU](https://github.com/OpenXiangShan/NEMU)
和[香山GEM5](https://github.com/OpenXiangShan/GEM5)
）生成**确定性工作负载**的框架。

**Deterload** is a framework for generating **Deterministic Workloads** for the XiangShan ecosystem (including
[XiangShan Processor](https://github.com/OpenXiangShan/XiangShan),
[XiangShan NEMU](https://github.com/OpenXiangShan/NEMU),
and [XiangShan GEM5](https://github.com/OpenXiangShan/GEM5)
).

## 背景（Background）

[香山](https://github.com/OpenXiangShan/XiangShan/)是一款开源的高性能RISC-V处理器，其核心理念是敏捷开发。
[香山的工作负载](https://docs.xiangshan.cc/zh-cn/latest/workloads/overview/)指运行在香山处理器上的各类程序，是开发、调试、评估、研究时不可或缺的组件。

[XiangShan](https://github.com/OpenXiangShan/XiangShan/) is an open-source high-performance RISC-V processor, built around the core concept of agile development.
[XiangShan's workloads](https://docs.xiangshan.cc/zh-cn/latest/workloads/overview/) refer to various programs running on XiangShan processor,
which are essential components for development, debugging, evaluation, and research.

为了能更加敏捷地生成各类工作负载，我们开发了Deterload项目。
Deterload在[checkpoint_scripts](https://github.com/xyyy1420/checkpoint_scripts)框架上，引入了**确定性**。
此外，Deterload不仅支持生成切片镜像，还计划支持香山的各类工作负载，包括非切片镜像和裸机镜像。

To enable more agile generation of various workloads, we developed the Deterload project.
Deterload is based on the [checkpoint_scripts](https://github.com/xyyy1420/checkpoint_scripts) framework and adds the **deterministic** feature.
Moreover, Deterload not only supports generating checkpoint images but also plans to support various workloads for XiangShan, including non-checkpoint images and bare-metal images.

## 关于“确定性”（About "Deterministic"）

🤔**什么**是“确定性”？
😺无论何时何地，两次构建同一个工作负载，都应该得到完全相同的结果！

🤔**为什么**需要“确定性”？
😺它能让开发更敏捷。无论何时何地，你都能轻松重现bug和性能异常！

🤔**如何**实现“确定性”？
😺使用确定性包管理器[Nix](https://nixos.org/)并且控制所有随机性！

🤔**What** is "Deterministic"?
😺It means that whenever and wherever building the workload twice should yield the same result!

🤔**Why** do we need "Deterministic"?
😺It enables more agile development.
You can reproduce bugs and performance anomalies anytime, anywhere, without hassle!

🤔**How** to achieve "Deterministic"?
😺Using the deterministic package manager [Nix](https://nixos.org/) and controlling all possible sources of randomness!

## 使用方法（Usage）

Deterload由Nix驱动。
如果你尚未安装Nix，请参考[Nix官方安装指南](https://nixos.org/download/)。

Deterload is powered by Nix.
If you haven't installed Nix, please refer to the [Nix official installation](https://nixos.org/download/).

```bash
# 进入nix shell（推荐使用direnv自动进入nix shell）：
# Enter the nix shell (direnv is recommended for auto entering the nix shell):
nix-shell

# 用10个线程为<benchmark>生成切片，切片存于result/：
# Generate checkpoints for <benchmark> using 10 threads, saved in result/:
nom-build examples/<benchmark> -A cpts-simpoint -j10

# 显示帮助信息：
# Display help information:
h
```

<!-- ANCHOR_END: main -->

## 更多文档（More Documentation）

请参考[本仓库的GitHub Pages](https://openxiangshan.github.io/Deterload/)。

Please refer to [the GitHub Pages of this repo](https://openxiangshan.github.io/Deterload/) of this documentation.
