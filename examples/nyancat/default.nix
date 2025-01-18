{ deterload ? import ../../defaultNew.nix {}
}: deterload.build (deterload.deterPkgs.writeShScript "nyancat-run" {} ''
  timeout 20 ${deterload.deterPkgs.riscv64-pkgs.nyancat}/bin/nyancat -t
'')
