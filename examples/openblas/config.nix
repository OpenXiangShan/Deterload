{...}@args: import ../. ({
  cc = "gcc13";
  cores = "2";

  TARGET = "RISCV64_ZVL256B";

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
