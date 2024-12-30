# GEM5

生成的工作负载（例如切片）可以在多个香山平台上运行，包括GEM5、Nemu和香山RTL。

The generated workloads (e.g. checkpoints) are compatible with multiple XiangShan platforms including GEM5, Nemu, and XiangShan RTL.

## 用法（Usage）

请按照[OpenXiangShan/GEM5](https://github.com/OpenXiangShan/GEM5)仓库中的配置指南进行设置。

Please follow the configuration guidelines in the [OpenXiangShan/GEM5](https://github.com/OpenXiangShan/GEM5) repository.

注意：生成的切片中已包含恢复代码（见`opensbi/default.nix`），
因此不用设置$GCB_RESTORER环境变量。

Note: The generated checkpoints has included the restorer code (see `opensbi/default.nix`),
eliminating the need to set the $GCB_RESTORER environment variable.

## 故障排除（Troubleshooting）

请考虑在[Deterload issues](https://github.com/OpenXiangShan/Deterload/issues)中报告你遇到的问题。

Please consider reporting your issues in [Deterload issues](https://github.com/OpenXiangShan/Deterload/issues).

### Difftest错误（Difftest Errors）

* 访问香山GEM5的release页面
* 下载稳定版本的NEMU
* 设置相应的$GCBV_REF_SO环境变量


* Visit the XiangShan GEM5 releases page
* Download a stable version of NEMU
* Set the corresponding `$GCBV_REF_SO` environment variable

### 常见运行时问题（General Runtime Issues）

* 在gem5命令前添加`gdb --args`进行调试
* 在本仓库或香山GEM5仓库中报告问题


* Debug by prefixing your gem5 command with `gdb --args`
* Report issues in either this repository or the XiangShan GEM5 repository

### 部分切片运行失败（Failures in Some Checkpoints）

虽然目前部分切片可能在GEM5中运行失败（这个问题正在解决中），
但约90%的切片应该能够正确执行，提供可靠的性能指标。

While some checkpoints may currently fail in GEM5 (this is being addressed),
approximately 90% should execute correctly, providing reliable performance metrics.

## 分数计算（Score Calculation）

要在使用GEM5运行切片后计算SPEC CPU 2006分数，
请使用[gem5_data_proc](https://github.com/shinezyy/gem5_data_proc)工具。
由于该工具最初是为内部切片设计的，可能需要进行一些小的调整。
例如，基准测试名称可能需要调整（如"hmmer"改为"456.hmmer"）。
即使偶尔有切片运行失败，
这个工具仍然能够为SPEC CPU 2006提供准确的整体性能指标。

To calculate SPEC CPU 2006 scores after running the checkpoints using GEM5,
use the [gem5_data_proc](https://github.com/shinezyy/gem5_data_proc) tool.
Minor adjustments to the tool may be necessary as it was designed for internal checkpoints.
For example, benchmark names may need adaptation (e.g., "hmmer" to "456.hmmer").
Even with occasional checkpoint failures,
this tool should provide accurate overall performance metrics for SPEC CPU 2006.
