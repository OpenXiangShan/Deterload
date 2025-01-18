{ pkgs ? import (fetchTarball {
    # Currently latest nixpkgs 24.11
    url = "https://github.com/NixOS/nixpkgs/archive/9c6b49aeac36e2ed73a8c472f1546f6d9cf1addc.tar.gz";
    sha256 = "0zwnaiw6cryrvwxxa96f72p4w75wq2miyi066f2sk8n7ivj0kxcb";
  }) {}
, lib ? pkgs.lib

/**
<style>
arg {
  font-family: mono;
  font-size: 1.2em;
  font-weight: bold;
}
arg::before {
  content: "• "
}
</style>
*/
/** ## Common Configuration */

/**
<arg>cc</arg>: Compiler Collection used for compiling RISC-V binaries.
* **Type**: string
* **Default value**: `"gcc14"`
* **Available values**: Prefix of any nixpkgs-supported <u>xxx</u>Stdenv.
  To list available <u>xxx</u>Stdenv:
  ```bash
  nix-instantiate --eval -E 'let pkgs=import <nixpkgs> {}; in builtins.filter (x: pkgs.lib.hasSuffix "Stdenv" x)(builtins.attrNames pkgs)'
  ```
* **TODO**: Currently only supports GCC's stdenv.
  LLVM's fortran compiler (flang) is needed to support Clang's stdenv.
  Preliminary experiments with riscv64-jemalloc show that Clang provides better auto-vectorization than GCC.
*/
, cc ? "gcc14"
, ...
}@args:
assert pkgs.pkgsCross.riscv64 ? "${cc}Stdenv";
rec {
  deterPkgs = pkgs.lib.makeScope pkgs.lib.callPackageWith (self: pkgs // {
    riscv64-pkgs = pkgs.pkgsCross.riscv64;
    riscv64-stdenv = self.riscv64-pkgs."${cc}Stdenv";
    riscv64-cc = self.riscv64-stdenv.cc;
    riscv64-fortran = self.riscv64-pkgs.wrapCCWith {
      cc = self.riscv64-stdenv.cc.cc.override {
        name = "gfortran";
        langFortran = true;
        langCC = false;
        langC = false;
        profiledCompiler = false;
      };
      # fixup wrapped prefix, which only appear if hostPlatform!=targetPlatform
      #   for more details see <nixpkgs>/pkgs/build-support/cc-wrapper/default.nix
      stdenvNoCC = self.riscv64-pkgs.stdenvNoCC.override {
        hostPlatform = pkgs.stdenv.hostPlatform;
      };
      # Beginning from 24.05, wrapCCWith receive `runtimeShell`.
      # If leave it empty, the default uses riscv64-pkgs.runtimeShell,
      # thus executing the sheBang will throw error:
      #   `cannot execute: required file not found`.
      runtimeShell = pkgs.runtimeShell;
    };
    rmExt = name: builtins.concatStringsSep "."
      (pkgs.lib.init
        (pkgs.lib.splitString "." name));
    writeShScript = name: passthru: text: pkgs.writeTextFile {
      inherit name;
      text = ''
        #!/usr/bin/env sh
        ${text}
      '';
      executable = true;
      derivationArgs = { inherit passthru; };
    };
    utils = pkgs.callPackage ./utils.nix {};
  });

  build = deterPkgs.callPackage ./builders {} args;
}
