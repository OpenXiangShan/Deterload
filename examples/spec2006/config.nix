{...}@args: import ./. ({
  cc = "gcc13";
  cores = "2";

  enableVector = true;

  size = "test";
  optimize = "-O3";
  march = "rv64gcbv";
  # "464_h264ref" and "465_tonto" will be excluded
  testcase-filter = testcase: !(builtins.elem testcase [
    "464_h264ref"
    "465_tonto"
  ]);

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
