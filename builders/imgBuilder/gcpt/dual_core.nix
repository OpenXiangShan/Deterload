{ stdenv
, fetchFromGitHub
, python3
, riscv64-cc
, rmExt

, opensbi
}@args: stdenv.mkDerivation {
  name = "${rmExt opensbi.name}.gcpt_2core";
  src = fetchFromGitHub {
    owner = "OpenXiangShan";
    repo = "LibCheckpoint";
    rev = "f8c33689cdf11aa2f8f25dbf99075dca148ecd44";
    hash = "sha256-UpHhy9dsYs7PAXllAEhvFcYOuEX8US365q1QUwNxqbA=";
    fetchSubmodules = true;
  };
  buildInputs = [
    (python3.withPackages (pypkgs: [
      pypkgs.protobuf
      pypkgs.grpcio-tools
    ]))
    riscv64-cc
  ];
  makeFlags = [
    "CROSS_COMPILE=riscv64-unknown-linux-gnu-"
    "USING_QEMU_DUAL_CORE_SYSTEM=1"
    "GCPT_PAYLOAD_PATH=${opensbi}"
  ];
  installPhase = ''
    cp build/gcpt.bin $out
  '';
  passthru = args;
}
