{...}@args: import ../. ({
  cc = "gcc13";
  cores = "2";

  enableVector = true;

  spec2006-extra-tag = "exclude_464_465";
  spec2006-size = "test";
  spec2006-optimize = "-O3";
  spec2006-march = "rv64gcbv";
  # "464_h264ref" and "465_tonto" will be excluded
  spec2006-testcase-filter = testcase: !(builtins.elem testcase [
    "464_h264ref"
    "465_tonto"
  ]);

  openblas-extra-tag = "miao";
  openblas-target = "RISCV64_ZVL256B";

  cpt-maxK = "10";
  cpt-maxK-bmk = {
    "403.gcc" = "20";
    "483.xalancbmk" = "30";
    "openblas" = "50";
  };
  cpt-intervals = "1000000";
  cpt-simulator = "qemu";
  cpt-format = "zstd";
} // args)
