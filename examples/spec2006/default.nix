{ lib ? import <nixpkgs/lib>
/**
<arg>enableVector</arg>: Controls compiler's auto-vectorization during benchmark builds.
* **Type**: bool
* **Default value**: `false`
*/
, enableVector ? false

/**
<arg>src</arg>: Path to SPEC CPU 2006 source code.
* <span style="background-color:yellow;">**Note**</span>:
  As SPEC CPU 2006 is a proprietary benchmark, it cannot be incorporated in Deterload's source code.
  You need to obatin the its source code through legal means.
* **Type**: path
* **Supported path types**:
  * Path to a folder:

    The folder must be the root directory of the SPEC CPU 2006 source code.

    Example:
    ```nix
    src = /path/miao/spec2006;
    ```

    Required folder structure:
    ```
    /path/miao/spec2006
    ├── benchspec/
    ├── bin/
    ├── tools/
    ├── shrc
    ...
    ```

  * Path to a tar file:

    The tar file must contain a folder named exactly `spec2006`,
    with the same folder structure as above.

    Supported tar file extensions:
    * gzip (.tar.gz, .tgz or .tar.Z)
    * bzip2 (.tar.bz2, .tbz2 or .tbz)
    * xz (.tar.xz, .tar.lzma or .txz)

    Example:
    ```nix
    src = /path/of/spec2006.tar.gz;
    ```

  * For more information about supported path types,
    please see [Nixpkgs Manual: The unpack phase](https://nixos.org/manual/nixpkgs/stable/#ssec-unpack-phase).
*/
, src ? throw "Please specify <src> the path of spec2006, for example: /path/of/spec2006.tar.gz"

/**
<arg>size</arg>: Input size for SPEC CPU 2006.
* **Type**: string
* **Default value**: `"ref"`
* **Available values**: `"ref"`, `"train"`, `"test"`
*/
, size ? "ref"

/**
<arg>optimize</arg>: Compiler optimization flags for SPEC CPU 2006.
* **Type**: string
* **Default value**: `"-O3 -flto"`
*/
, optimize ? "-O3 -flto"

/**
<arg>march</arg>: Compiler's `-march` option for SPEC CPU 2006.
* **Type**: string
* **Default value**: "rv64gc${lib.optionalString enableVector "v"}"
* **Description**: The default value depends on `enableVector`:
  * If `enableVector` is `true`, the default value is `"rv64gc"`,
  * If `enableVector` is `false`, the default value is `"rv64gcv"`.
*/
, march ? "rv64gc${lib.optionalString enableVector "v"}"

/**
<arg>testcase-filter</arg>: Function to filter SPEC CPU 2006 testcases.
* **Type**: string -> bool
* **Default value**: `testcase: true`
* **Description**: `testcase-filter` takes a testcase name as input and returns:
  * `true`: include this testcase
  * `false`: exclude this testcase
* **Example 1**: Include all testcases:
  ```nix
  testcase-filter = testcase: true;
  ```
* **Example 2**: Only include `403_gcc`:
  ```nix
  testcase-filter = testcase: testcase == "403_gcc";
  ```
* **Example 3**: Exlcude `464_h264ref` and `465_tonto`:
  ```nix
  testcase-filter = testcase: !(builtins.elem testcase [
    "464_h264ref"
    "465_tonto"
  ]);
  ```
*/
, testcase-filter ? testcase: true
, ...
}@args:
assert lib.assertOneOf "size" size ["ref" "train" "test"];
let
  deterload = import ../.. args;
  spec2006-full = deterload.deterPkgs.callPackage ./packages.nix {
    riscv64-libc = deterload.deterPkgs.riscv64-stdenv.cc.libc.static;
    riscv64-jemalloc = deterload.deterPkgs.riscv64-pkgs.jemalloc.overrideAttrs (oldAttrs: {
      configureFlags = (oldAttrs.configureFlags or []) ++ [
        "--enable-static"
        "--disable-shared"
      ];
      preBuild = ''
        # Add weak attribute to C++ operators, same as jemalloc_cpp.patch
        sed -i 's/void \*operator new(size_t)/void *operator new(size_t) __attribute__((weak))/g' src/jemalloc_cpp.cpp
        sed -i 's/void operator delete(void \*)/void operator delete(void *) __attribute__((weak))/g' src/jemalloc_cpp.cpp
      '';
      # Ensure static libraries are installed
      postInstall = ''
        ${oldAttrs.postInstall or ""}
        cp -v lib/libjemalloc.a $out/lib/
      '';
    });
    inherit src size enableVector optimize march;
  };
  spec2006-filtered = lib.filterAttrs (testcase: value:
    (testcase-filter testcase) && (lib.isDerivation value))
    spec2006-full;
  spec2006-deterload = builtins.mapAttrs
    (name: benchmark: (deterload.build benchmark))
    (lib.filterAttrs (n: v: (lib.isDerivation v)) spec2006-filtered);
in spec2006-deterload // (
  deterload.deterPkgs.utils.wrap-l2
    (deterload.deterPkgs.rmExt
      (builtins.head 
        (builtins.attrValues spec2006-deterload)).benchmark.name)
    spec2006-deterload
)
