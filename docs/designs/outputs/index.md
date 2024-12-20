# 📊输出（Outputs）

下面的表格展示了Deterload的构建结果，具体说明如下：

* `Date`行表示构建开始的时间，格式为年月日时分秒(yymmddhhmmss)。
  各列按照`Date`降序排列（最新排最前面）。
* `Commit`行显示每次构建对应的Git commit的哈希值。
* `Note`行包含简单的说明（主要是说明为什么哈希值发生变化）。
* `result/`行及其下方的行表示构建结果的Nix store哈希值。
  每个单元格都用颜色标记，不同的颜色表示不同的哈希值。
  通过这种颜色标记，可以轻松看出多次构建之间是否保持了**确定性**。

The tables below demonstrate the build results of Deterload, with the following details:

* The `Date` row indicates the build start time in yymmddhhmmss format.
  Columns are sorted by `Date` in descending order (most recent first).
* The `Commit` row displays the Git commit hash associated with each build.
* The `Note` row shows a simple explanation (mainly explains why hash changed).
* The `result/` row and the subsequent rows indicates the Nix store hashes of build results.
  Each cell is color-coded, with different colors indicating distinct hash values.
  This color coding makes it straightforward to verify **deterministic** build across multiple builds.

## SPEC2006

<div style="width: var(--content-max-width); overflow: auto;">
<div id="spec2006Table"></div>
</div>


## OpenBLAS

<div style="width: var(--content-max-width); overflow: auto;">
<div id="openblasTable"></div>
</div>

<script src="https://cdn.plot.ly/plotly-2.35.2.min.js" charset="utf-8"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/PapaParse/5.4.1/papaparse.min.js"></script>
<script src="./gen_table.js"></script>
<script>
gen_table("spec2006Table", "https://raw.githubusercontent.com/OpenXiangShan/Deterload/refs/heads/data/spec2006.txt")
gen_table("openblasTable", "https://raw.githubusercontent.com/OpenXiangShan/Deterload/refs/heads/data/openblas.txt")
</script>
