# 🧾配置系统（Configuration System）

TODO:

Deterload支持多种配置方式：

* 命令行
* 配置文件
* 命令行+配置文件

## 命令行

通过`--arg key value`的方式传递配置。例如：

```bash
nix-build --arg enableVector true --arg simulator '"qemu"' -A openblas.cpt
```

可以用`--argstr key value`来简化`--arg key '"value"'`：

```bash
nix-build --arg enableVector true --argstr simulator qemu -A openblas.cpt
```

## 配置文件

## 命令行+配置文件

## [🧾可配参数（Configurable Arguments）](./reference/config.md)
