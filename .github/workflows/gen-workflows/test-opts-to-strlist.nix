{ lib ? import <nixpkgs/lib> }:
/*
# input must contains an `args` attrubite
input (test-opts): {
  args = {
    cc = ["gcc14" "gcc"];
    miao = ["1" "2"];
    wang = [true false];
  };
  A = ["benchmark" "cpt"];
  max-jobs = [20];
}
output: [
  "--argstr cc gcc14 --argstr miao 1 --arg wang true -A benchmark --max-jobs 20"
  "--argstr cc gcc14 --argstr miao 1 --arg wang true -A cpt --max-jobs 20"
  "--argstr cc gcc14 --argstr miao 1 --arg wang false -A benchmark --max-jobs 20"
  "--argstr cc gcc14 --argstr miao 1 --arg wang false -A cpt --max-jobs 20"
  "--argstr cc gcc14 --argstr miao 2 --arg wang true -A benchmark --max-jobs 20"
  "--argstr cc gcc14 --argstr miao 2 --arg wang true -A cpt --max-jobs 20"
  "--argstr cc gcc14 --argstr miao 2 --arg wang false -A benchmark --max-jobs 20"
  "--argstr cc gcc14 --argstr miao 2 --arg wang false -A cpt --max-jobs 20"
  "--argstr cc gcc --argstr miao 1 --arg wang true -A benchmark --max-jobs 20"
  "--argstr cc gcc --argstr miao 1 --arg wang true -A cpt --max-jobs 20"
  "--argstr cc gcc --argstr miao 1 --arg wang false -A benchmark --max-jobs 20"
  "--argstr cc gcc --argstr miao 1 --arg wang false -A cpt --max-jobs 20"
  "--argstr cc gcc --argstr miao 2 --arg wang true -A benchmark --max-jobs 20"
  "--argstr cc gcc --argstr miao 2 --arg wang true -A cpt --max-jobs 20"
  "--argstr cc gcc --argstr miao 2 --arg wang false -A benchmark --max-jobs 20"
  "--argstr cc gcc --argstr miao 2 --arg wang false -A cpt --max-jobs 20"
]
*/
test-opts: let
  /*
  optsArgs = {
    cc = ["gcc14" "gcc"];
    miao = ["1" "2"];
    wang = [true false];
  }
  */
  optsArgs = test-opts.args;
  # optsArgsStrList = ["--argstr cc gcc14 --argstr miao 1 --arg wang true" ...]
  optsArgsStrList = lib.mapCartesianProduct (
    /*
    argAttr = {
      cc = "gcc14";
      miao = "1";
      wang = true;
    }
    */
    argAttr: toString (lib.mapAttrsToList (n: v:
      if builtins.typeOf v == "string"
      then "--argstr ${n} ${v}"
      else "--arg ${n} ${lib.generators.toPretty {multiline = false;} v}"
    ) argAttr)
  ) optsArgs;
  # If optsArgsStrList is empty make it [""]
  optsArgsStrList' = if builtins.length optsArgsStrList == 0 then [""] else optsArgsStrList;

  /*
  optsRest = {
    A = ["benchmark" "cpt"];
    max-jobs = [20];
  }
  !!!Noted: optsRest could be empty
  */
  optsRest = builtins.removeAttrs test-opts ["args"];
  # optsRestStrList = [ "-A benchmark --max-jobs 20" ... ]
  optsRestStrList = lib.mapCartesianProduct (
    /*
    optsAttr = {
      A = "benchmark";
      max-jobs = 20;
    }
    */
    optsAttr: toString (lib.mapAttrsToList (n: v:
      if lib.stringLength n == 1
      then  "-${n} ${toString v}"
      else "--${n} ${toString v}"
    ) optsAttr)
  ) optsRest;
  # If optsRestStrList is empty make it [""]
  optsRestStrList' = if builtins.length optsRestStrList == 0 then [""] else optsRestStrList;

  optsStrList =  lib.mapCartesianProduct (
    /*
    opts = {
      optsArgsStrList' = "--argstr cc gcc14 --argstr miao 1 --arg wang true";
      optsRestStrList' = "-A benchmark --max-jobs 20";
    }
    */
    opts: toString (builtins.attrValues opts)
  ) {inherit optsRestStrList' optsArgsStrList';};
in optsStrList
