{ ... }@args: let
  deterload = import ../.. args;
  pkgs = deterload.deterPkgs;
  hello-nolibc = pkgs.riscv64-pkgs.callPackage ./hello-nolibc.nix {};
  # TODO: refactor deterload to reduce duplicate here and below
  deterload-hello = deterload.build (pkgs.writeShScript "hello-run" {} ''
    ${hello-nolibc}/bin/hello
  '');
  overrided = deterload-hello.overrideScope (final: prev: {
    initramfs_overlays = prev.initramfs_overlays.override {
      # TODO: refactor deterload to reduce duplicate here and above
      run_sh = pkgs.writeText "run.sh" "${hello-nolibc}/bin/hello";
    };
  });
in overrided
