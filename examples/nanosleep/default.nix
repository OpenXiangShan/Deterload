{ ... }@args: let

  deterload = import ../.. args;
  pkgs = deterload.deterPkgs;
  riscv64-pkgs = pkgs.riscv64-pkgs;
  nolibc = riscv64-pkgs.runCommand "nolibc" {} ''
    path=$(tar tf ${riscv64-pkgs.linux.src} | grep tools/include/nolibc | sort | head -n1)
    tar xf ${riscv64-pkgs.linux.src}
    mv $path $out
  '';
  nanosleep = riscv64-pkgs.runCommandCC "nanosleep" {
    passthru = {inherit nolibc;};
  } ''
    mkdir -p $out/bin
    $CC -nostdlib -I ${nolibc} ${./nanosleep.c} -o $out/bin/nanosleep
  '';
  # TODO: refactor deterload to reduce duplicate here and below
  deterload-nanosleep = deterload.build (pkgs.writeShScript "nanosleep-run" {
    passthru = {inherit nanosleep nolibc;};
  } ''
    ${nanosleep}/bin/nanosleep
  '');
  overrided = deterload-nanosleep.overrideScope (final: prev: {
    initramfs_overlays = prev.initramfs_overlays.override {
      # TODO: refactor deterload to reduce duplicate here and above
      run_sh = pkgs.writeText "run.sh" "${nanosleep}/bin/nanosleep";
    };
  });
in overrided
