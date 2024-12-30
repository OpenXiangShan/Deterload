{ stdenv
, fetchFromGitHub
, fetchFromGitLab
, python3
, ninja
, meson
, glib
, pkg-config
, zstd
, dtc
}:
stdenv.mkDerivation {
  name = "xs-checkpoint-qemu";
  src = fetchFromGitHub {
    owner = "OpenXiangShan";
    repo = "qemu";
    # latest checkpoint branch
    rev = "8758c375de12f09073614cad48f9956fe53b5aa7";
    hash = "sha256-xSJcR4bywPwpBGQfFKGOTrYZBhMoy0gOP8hYoA+hEOM=";
    postFetch = let
      keycodemapdb = fetchFromGitLab {
        owner = "qemu-project";
        repo = "keycodemapdb";
        rev = "f5772a62ec52591ff6870b7e8ef32482371f22c6";
        hash = "sha256-GbZ5mrUYLXMi0IX4IZzles0Oyc095ij2xAsiLNJwfKQ=";
      };
      berkeley-softfloat-3 = fetchFromGitLab {
        owner = "qemu-project";
        repo = "berkeley-softfloat-3";
        rev = "b64af41c3276f97f0e181920400ee056b9c88037";
        hash = "sha256-Yflpx+mjU8mD5biClNpdmon24EHg4aWBZszbOur5VEA=";
      };
      berkeley-testfloat-3 = fetchFromGitLab {
        owner = "qemu-project";
        repo = "berkeley-testfloat-3";
        rev = "e7af9751d9f9fd3b47911f51a5cfd08af256a9ab";
        hash = "sha256-inQAeYlmuiRtZm37xK9ypBltCJ+ycyvIeIYZK8a+RYU=";
      };
    in ''
      cp -r ${keycodemapdb} $out/subprojects/keycodemapdb
      find $out/subprojects/keycodemapdb -type d -exec chmod +w {} \;

      cp -r ${berkeley-softfloat-3} $out/subprojects/berkeley-softfloat-3
      find $out/subprojects/berkeley-softfloat-3 -type d -exec chmod +w {} \;
      cp -r $out/subprojects/packagefiles/berkeley-softfloat-3/* $out/subprojects/berkeley-softfloat-3/

      cp -r ${berkeley-testfloat-3} $out/subprojects/berkeley-testfloat-3
      find $out/subprojects/berkeley-testfloat-3 -type d -exec chmod +w {} \;
      cp -r $out/subprojects/packagefiles/berkeley-testfloat-3/* $out/subprojects/berkeley-testfloat-3/
    '';
  };
  patches = [
    ./allow_get_icount_anytime.patch
  ];
  # do not disable timer
  postPatch = ''
    sed -i 's/nemu_trap_count == 2/nemu_trap_count == 1/g' contrib/plugins/profiling.c
  '';

  buildInputs = [
    python3
    ninja
    meson
    glib
    pkg-config
    zstd
    dtc
  ];

  dontUseMesonConfigure = true;
  preConfigure = ''
  '';
  configureFlags = [
    "--target-list=riscv64-softmmu"
    # "--enable-debug"
    "--enable-zstd"
    "--enable-plugins"
    "--disable-werror"
    "--disable-download"
  ];
  preBuild = "cd build";

  # build plugins
  postBuild = ''
    make -C contrib/plugins
  '';
  # install plugins
  postInstall = ''
    mkdir -p $out/lib
    cp contrib/plugins/*.so $out/lib/
  '';
}
