
# XiangShan Checkpoint Profiling

This repository contains tools and scripts for generating deterministic checkpoints of SPEC CPU2006 benchmarks using QEMU and Simpoint. These checkpoints are designed for use with XiangShan and gem5 simulators, enabling rapid architectural exploration. The project aims to support NEMU checkpoints in the future.

## Overview

The project uses Nix to manage dependencies and build the necessary components:

- QEMU: Modified version of QEMU with checkpoint and profiling capabilities
- Simpoint: Simpoint is a tool for profiling and checkpointing in XiangShan
- OpenSBI: RISC-V OpenSBI firmware
- Linux: Custom Linux kernel image
- Profiling tools: Scripts and plugins for analyzing checkpoint data

## Preparing SPEC CPU2006 Source Code

Before using this project, you need to prepare the SPEC CPU2006 program source code yourself. Please follow these steps:

1. Obtain the SPEC CPU2006 source code (we cannot provide the source code due to licensing restrictions).
2. It is recommended to store the SPEC CPU2006 source code directory separately, not in the same location as this repository.
3. Rename the obtained source code folder to "spec2006", like ~/workspace/spec2006.
4. Please do not modify the SPEC CPU2006 source code, as this may cause the build to fail.
5. Note that the spec2006/default.nix directory in this repository is different from the SPEC CPU2006 source code directory. The former can be considered as a Nix build script.

## Nix Installation and Usage

### Installing Nix

To install Nix, run the following command:

if you are using nix on linux and have sudo permission, you can install nix by running
```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```
other OS, please refer to [Nix Installation Guide](https://nixos.org/download/)

### Building and Running

first, enter nix shell
```bash
nix-shell
```

then get help
```bash
h
```

it will show you some usage tips
```
   DETERMINISTIC_CHECKPOINTS USAGE TIPS

  • Set SPEC CPU 2006 source code: edit  config.nix :  spec2006_path = [...]
  • Set input size: edit  config.nix :  size = xxx  (default input is ref)
  • Change other configs in  config.nix
  • Generate the checkpoints of all testCases into  result/ :  nom-build -A checkpoints
  • Generate the checkpoints of a specific testCase into  result/ :  nom-build -A checkpoints.<testCase>
    • E.g.:  nom-build -A checkpoints.403_gcc
  • Running nom-build without parameters will generate results-* directory containing all intermediate build results, symlinked to the corresponding /nix/store/....nix. You can then use dump_result.py to read the log files within and obtain the dynamic instruction count of the program.
    • E.g.:  nom-build
```


build the project
```bash
nom-build -A checkpoints -j 10
```


Please note that the build process may take a considerable amount of time:

1. First, the script will fetch and compile the RISC-V GCC toolchain, Linux kernel, QEMU, and other necessary components. This step takes approximately 1 hour.

2. Then, it will use QEMU for profiling, SimPoint sampling, and QEMU checkpoint generation. Generating spec2006 ref input checkpoint typically requires about 10 hours.

If you want to quickly test the system, you can start by setting the input size to "test":

1. Edit the `conf.nix` file
2. Change `size = xxx` to `size = "test"`

With the test input size, the entire process should complete in about 30 minutes.

Finally, it will generate a result folder, you will get all the checkpoints in the result folder

If you want to back up some checkpoints:
run
```bash
nom-build -j 30
python3 backup_checkpoints.py
```
It will copy checkpoints from nix path to local pwd path, named backup_XXX (timestamp).
Notice: backup_XXX is about 100GB!


## Running on Gem5

The checkpoints generated by this repository can be run on Gem5, Nemu, and XiangShan RTL in the XiangShan repository. Here we explain the considerations for running on Gem5.

Since the checkpoints in this repository are currently single-core and without V extension (will be updated once vector extension support is stable), please configure according to the README in https://github.com/OpenXiangShan/GEM5.

Note: This repository's checkpoints by default place the checkpoint restorer code at the beginning of the checkpoint address space (refer to opensbi/default.nix). Therefore, there's no need to specify the $GCB_RESTORER environment variable; you can set it to empty.


If you encounter difftest errors during Gem5 execution, you can follow these steps:

1. Visit the Gem5 releases page
2. Download a stable version of NEMU
3. Set the corresponding `$GCBV_REF_SO` environment variable

This approach can help resolve difftest errors and ensure proper execution of checkpoints on Gem5.

If you encounter other Gem5 runtime errors, try debugging by adding `gdb --args` before the gem5 command. You can also open an issue in this repository or the Gem5 repository.

Please note that some checkpoints may fail to run in Gem5. This issue is currently being addressed. However, over 90% of the checkpoints should run correctly, and the resulting scores should be generally accurate. After running all checkpoints in Gem5, you can use the following script to calculate the SPEC CPU 2006 slice scores:

https://github.com/shinezyy/gem5_data_proc

You may need to make some minor modifications to this repository, as gem5_data_proc is designed for internal checkpoints, and there are slight differences in file naming between it and the Nix checkpoints. For example, "hmmer" vs "456.hmmer".

This script can help you process the data generated by Gem5 and calculate the final scores for the SPEC CPU 2006 benchmark. Even if a few checkpoints fail to run, this script should still provide you with a fairly accurate performance assessment.


## Reference

This repository referenced the following documents to facilitate one-click generation of deterministic slices:

- [Linux Kernel for XiangShan in EMU(opensbi)](https://docs.xiangshan.cc/zh-cn/latest/tools/opensbi-kernel-for-xs/)
- [Linux Kernel for XiangShan in EMU(pk)](https://docs.xiangshan.cc/zh-cn/latest/tools/linux-kernel-for-xs/)
- [Simpoint for XiangShan](https://docs.xiangshan.cc/zh-cn/latest/tools/simpoint/)
- [Checkpoint scripts](https://github.com/xyyy1420/checkpoint_scripts)

This repository can be considered as a Nix-managed version of checkpoint_scripts.

These resources provided valuable insights and tools for implementing the deterministic checkpoint generation process in this project.





