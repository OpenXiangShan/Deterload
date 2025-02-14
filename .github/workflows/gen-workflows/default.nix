{ pkgs ? import <nixpkgs> {}, lib ? pkgs.lib }: let
  workflow = {
    name = "build-deterload";
    on.push = {
      branches = ["actions"];
      paths = ["**" "!docs/**"];
    };
    # TODO: quick-test
    jobs = (
      let
        zipWithIndex = f: list: let
          indices = builtins.genList lib.id (builtins.length list);
        in lib.zipListsWith f list indices;

        # cmds = [ "cmd0" "cmd1" ... ]
        cmds = import ./gen-nix-build-cmds.nix {};

        # jobsList = [ {name="jobi"; value="cmdi"} ... ]
        jobsList = zipWithIndex (cmd: index: {
          name = "job${toString index}";
          value = {
            # one week (spec2006 with enableVector needs about 4 days)
            timeout-minutes = 10080;
            runs-on = ["self-hosted" "Linux" "X64" "nix" "spec2006"];
            steps = [
              {uses = "actions/checkout@v4";}
              {run = cmd;}
            ];
          };
        }) cmds;
      in builtins.listToAttrs jobsList
    ) // {
      quick-test = {
        runs-on = ["self-hosted" "Linux" "X64" "nix" "spec2006"];
        steps = [
          { uses = "actions/checkout@v4"; }
          { run = ''
              for example in examples/*/default.nix; do
                nix-instantiate $example --arg src $(ls -d /spec2006* | head -n1) -A cpt
              done
          ''; }
        ];
      };
    };
  };
in (pkgs.formats.yaml {}).generate "build-deterload.yaml" workflow
