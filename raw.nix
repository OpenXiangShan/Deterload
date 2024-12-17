{ pkgs ? import (fetchTarball { # TODO: remove, as it move into examples.nix
    url = "https://github.com/NixOS/nixpkgs/archive/e8c38b73aeb218e27163376a2d617e61a2ad9b59.tar.gz";
    sha256 = "1n6gdjny8k5rwkxh6sp1iwg1y3ni1pm7lvh9sisifgjb18jdvzbm";
  }) {}
}:
pkgs.lib.makeScope pkgs.lib.callPackageWith (ds/*deterload-scope itself*/: {
  riscv64-scope = let callPackageDefaultThrowWith = autoArgs: fn: args:
    let inherit (pkgs.lib) isFunction functionArgs intersectAttrs mapAttrs filterAttrs attrNames makeOverridable;
      f = if isFunction fn then fn else import fn;
      fargs = functionArgs f;
      allArgs = intersectAttrs fargs autoArgs // args;
      missingArgs =
        # Throw error message for missing args
        (mapAttrs (name: value: throw ''Argument "${name}" has not been overrided'')
        # Filter out arguments that have a default value
        (filterAttrs (name: value: ! value)
        # Filter out arguments that would be passed
        (removeAttrs fargs (attrNames allArgs))));
    in makeOverridable f (allArgs // missingArgs);
  in pkgs.lib.makeScope callPackageDefaultThrowWith (self: pkgs // {
    riscv64-pkgs = pkgs.pkgsCross.riscv64;
    riscv64-stdenv = self.riscv64-pkgs.gcc14Stdenv;
    riscv64-cc = self.riscv64-stdenv.cc;
    riscv64-libc-static = self.riscv64-stdenv.cc.libc.static;
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
  });

  build = ds.riscv64-scope.callPackage ./builders {};

  spec2006 = let
    benchmarks = ds.riscv64-scope.callPackage ./benchmarks/spec2006 {};
  in builtins.mapAttrs (name: benchmark: (ds.build benchmark))
    (pkgs.lib.filterAttrs (n: v: (pkgs.lib.isDerivation v)) benchmarks);

  openblas = let
    benchmark = ds.riscv64-scope.callPackage ./benchmarks/openblas {};
  in ds.build benchmark;
})
