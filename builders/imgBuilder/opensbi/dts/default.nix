{ stdenv
, fetchFromGitHub
, dtc

, cores
}:
let
  name = "xiangshan.dtb";
in stdenv.mkDerivation {
  inherit name;
  src = fetchFromGitHub {
    owner = "OpenXiangShan";
    repo = "nemu_board";
    rev = "37dc20e77a9bbff54dc2e525dc6c0baa3d50f948";
    hash = "sha256-MvmYZqxA1jxHR4Xrw+18EO+b3iqvmn2m9LkcpxqlUg8=";
  };

  buildInputs = [
    dtc
  ];
  buildPhase = let
    dtsFile = if cores=="1" then "system.dts"
         else if cores=="2" then "fpga-dualcore-system.dts"
         else if cores=="4" then "fpga-fourcore-system.dts"
         else throw "dts only supports 1/2/4 cores";
  in ''
    cd dts
    dtc -O dtb -o ${name} ${dtsFile}
  '';
  installPhase = ''
    mkdir -p $out
    cp ${name} $out/
  '';
}
