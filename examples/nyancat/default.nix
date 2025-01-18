{ ... }@args: let
  deterload = import ../.. args;
in deterload.build (deterload.deterPkgs.writeShScript "nyancat-run" {} ''
  timeout 20 ${deterload.deterPkgs.riscv64-pkgs.nyancat}/bin/nyancat -t
'')
