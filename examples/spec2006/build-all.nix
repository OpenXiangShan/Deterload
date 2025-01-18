{ stdenv
, lib
, fetchFromGitHub
, libxcrypt-legacy
, riscv64-cc
, riscv64-fortran

, utils
, riscv64-libc
, riscv64-jemalloc
, src
, size
, enableVector # TODO: enable vector in libc and jemalloc
, optimize
, march
}:
let
  CPU2006LiteWrapper = fetchFromGitHub {
    owner = "OpenXiangShan";
    repo = "CPU2006LiteWrapper";
    rev = "010ca8fe8bf229c68443a2dd1766e1be62fa7998";
    hash = "sha256-qNxmM9Dmobr6fvTZapacu8jngcBPRbybwayTi7CZGd0=";
  };
in stdenv.mkDerivation {
  name = utils.escapeName (builtins.concatStringsSep "_" [
    "spec2006"
    size
    (lib.removePrefix "${stdenv.targetPlatform.config}-" stdenv.cc.cc.name)
    optimize
    march
    riscv64-libc.pname
    riscv64-jemalloc.pname
  ]);
  system = "x86_64-linux";

  srcs = [
    src
    CPU2006LiteWrapper
  ];
  sourceRoot = ".";

  buildInputs = [
    riscv64-cc
    riscv64-fortran
    riscv64-libc
    riscv64-jemalloc
  ];

  patches = [ ./483.xalancbmk.patch ];

  configurePhase = let
    rpath = lib.makeLibraryPath [
      libxcrypt-legacy
    ];
  in ''
    echo patchelf: ./spec2006/bin/
    for file in $(find ./spec2006/bin -type f \( -perm /0111 -o -name \*.so\* \) ); do
      patchelf --set-interpreter "$(cat ${stdenv.cc}/nix-support/dynamic-linker)" "$file" &> /dev/null || true
      patchelf --set-rpath ${rpath} $file &> /dev/null || true
    done
  '';

  buildPhase = ''
    export LiteWrapper=$(realpath ${CPU2006LiteWrapper.name})
    export SPEC=$(realpath ./spec2006)
    cd $LiteWrapper

    export SPEC_LITE=$PWD
    export ARCH=riscv64
    export CROSS_COMPILE=riscv64-unknown-linux-gnu-
    export OPTIMIZE="${optimize} -march=${march}"
    export SUBPROCESS_NUM=5

    export CFLAGS="$CFLAGS -static -Wno-format-security -I${riscv64-jemalloc}/include "
    export CXXFLAGS="$CXXFLAGS -static -Wno-format-security -I${riscv64-jemalloc}/include"
    export LDFLAGS="$LDFLAGS -static -ljemalloc -L${riscv64-jemalloc}/lib"

    pushd $SPEC && source shrc && popd
    make copy-all-src
    make build-all -j $NIX_BUILD_CORES
    make copy-all-data
  '';

  dontFixup = true;

  # based on https://github.com/OpenXiangShan/CPU2006LiteWrapper/blob/main/scripts/run-template.sh
  installPhase = ''
    for WORK_DIR in [0-9][0-9][0-9].*; do
      echo "Prepare data: $WORK_DIR"
      pushd $WORK_DIR
      mkdir -p run
      if [ -d data/all/input ];        then cp -r data/all/input/*     run/; fi
      if [ -d data/${size}/input ];    then cp -r data/${size}/input/* run/; fi
      if [ -f extra-data/${size}.sh ]; then sh extra-data/${size}.sh       ; fi

      mkdir -p $out/$WORK_DIR/run/
      cp -r run/* $out/$WORK_DIR/run/
      cp build/$WORK_DIR $out/$WORK_DIR/run/
      # Replace $APP with executable in run-<size>.sh
      # E.g.: 481.wrf/run-ref.sh
      #   before replace: [run-ref.h]: $APP > rsl.out.0000
      #   after replace:     [run.sh]: ./481.wrf > rsl.out.0000
      sed 's,\$APP,./'$WORK_DIR',' run-${size}.sh > $out/$WORK_DIR/run/run-spec.sh
      popd
    done

    find $out -type d -exec chmod 555 {} +
  '';
}
