{ lib ? import <nixpkgs/lib> }: let
  /*
  examplesDirs = [
    "<abspath>/examples/nyancat"
    "<abspath>/examples/openblas"
    "<abspath>/examples/spec2006"
    ...
  ]
  */
  examplesDirs = let
    # items = { "README.md" = "regular"; nyancat = "directory"; result = "symlink"; ... }
    items = builtins.readDir ../../../examples;
    # dirs = { nyancat = "directory"; ... }
    dirs = lib.filterAttrs (n: v: v=="directory") items;
    # paths = [ "<abspath>/nyancat" ... ]
    paths = lib.mapAttrsToList (n: v: ../../../examples + "/${n}") dirs;
    paths_contain_defaultnix = builtins.filter
      (p: builtins.pathExists (p + "/default.nix")) paths;
  in paths_contain_defaultnix;

  /*
  cmdStrListL2 = [
    ["nix-build <abspath>/examples/nyancat --argstr cores 1 --argstr linuxVersion default -A cpt ..." ... ]
    ...
  ]
  */
  cmdStrListL2 = map (
    # examplesDir = "<abspath>/examples/nyancat"
    examplesDir: let
      # test-opts = {args={...}; ...}
      test-opts = lib.foldl lib.recursiveUpdate {args={};} [
        (import ../../../test-opts.nix)
        (import ../../../builders/test-opts.nix)
        (lib.optionalAttrs
          (builtins.pathExists "${examplesDir}/test-opts.nix")
          (import "${examplesDir}/test-opts.nix")
        )
      ];
      # optsStrList = [ "--argstr cores 1 --argstr linuxVersion default -A cpt ..." ... ]
      optsStrList = import ./test-opts-to-strlist.nix {} test-opts;
      # cmdStrList = [ "nix-build <abspath>/examples/nyancat --argstr cores 1 --argstr linuxVersion default -A cpt ..." ... ]
      cmdStrList = map (optsStr: "nix-build ${toString examplesDir} ${optsStr}") optsStrList;
    in cmdStrList
  ) examplesDirs;
in lib.flatten cmdStrListL2
