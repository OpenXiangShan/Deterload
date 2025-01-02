{ runCommand
, cpio
, writeClosure

, benchmark
, base
, overlays
}@args: let
  cpioPatched = cpio.overrideAttrs (old: { patches = [./cpio_reset_timestamp.patch]; });
  benchmark-closure = writeClosure [ benchmark ];
in runCommand "${benchmark.name}.cpio" {
  passthru = args // { inherit cpioPatched; };
} ''
  cp ${base}/init.cpio $out
  chmod +w $out

  # !!!NOTED!!!:
  # Prepare folder nix/store before copying contents in nix/store
  # https://www.kernel.org/doc/Documentation/filesystems/ramfs-rootfs-initramfs.txt
  # > The Linux kernel cpio extractor won't create files in a directory that
  # > doesn't exist, so the directory entries must go before the files that go in
  # > those directories.
  cd /
  echo ./nix | ${cpioPatched}/bin/cpio --reproducible -H newc -oAF $out
  echo ./nix/store | ${cpioPatched}/bin/cpio --reproducible -H newc -oAF $out

  for dep in $(cat ${benchmark-closure}); do
    find .$dep | sort -n | ${cpioPatched}/bin/cpio --reproducible -H newc -oAF $out
  done

  cd ${overlays}
  find . | sort -n | ${cpioPatched}/bin/cpio --reproducible -H newc -oAF $out
''
