{ lib
, linkFarm
, symlinkJoin
}: rec {
  getName = p: if (p?pname) then p.pname else p.name;
  escapeName = lib.converge (name:
    builtins.replaceStrings
      [" " "." "-" "__"]
      [""  ""  "_" "_" ]
  name);
  /*set -> set: filter derivations in a set*/
  filterDrvs = set: lib.filterAttrs (n: v: (lib.isDerivation v)) set;
  /*string -> set -> set:
    wrap-l2 prefix {
      a={x=drv0; y=drv1; z=drv2; w=0;};
      b={x=drv3; y=drv4; z=drv5; w=1;};
      c={x=drv6; y=drv7; z=drv8; w=2;};
    }
    returns {
      x=linkFarm "${prefix}_x" [drv0 drv3 drv6];
      y=linkFarm "${prefix}_y" [drv1 drv4 drv7];
      z=linkFarm "${prefix}_z" [drv2 drv5 drv8];
    }*/
  wrap-l2 = prefix: attrBuildResults: let
    /*mapToAttrs (name: {inherit name; value=...}) ["a", "b", "c", ...]
      returns {x=value0; b=value1; c=value2; ...} */
    mapToAttrs = func: list: builtins.listToAttrs (builtins.map func list);
    /*attrDrvNames {
        a={x=drv0; y=drv1; z=drv2; w=0;};
        b={x=drv3; y=drv4; z=drv5; w=1;};
        c={x=drv6; y=drv7; z=drv8; w=2;};
      }
      returns ["x" "y" "z"] */
    attrDrvNames = set: builtins.attrNames (filterDrvs (builtins.head (builtins.attrValues set)));
  in mapToAttrs (name/*represents the name in builders/default.nix, like img, cpt, ...*/: {
    inherit name;
    value = linkFarm (escapeName "${prefix}_${name}") (
      lib.mapAttrsToList (testCase: buildResult: {
        name = testCase;
        path = buildResult."${name}";
      }) attrBuildResults);
  }) (attrDrvNames attrBuildResults);

  wrap-l1 = prefix: buildResult: builtins.mapAttrs (name: value:
    if lib.isDerivation value then symlinkJoin {
      name = escapeName "${prefix}_${name}";
      paths = [value];
      passthru = lib.optionalAttrs (value?passthru) value.passthru;
    } else value
  ) buildResult;

  metricPrefix = input: let
    num =  if builtins.isInt input then input
      else if builtins.isString input then lib.toInt input
      else throw "metricPrefix: unspported type of ${input}";
    K = 1000;
    M = 1000 * K;
    G = 1000 * M;
    T = 1000 * G;
    P = 1000 * T;
    E = 1000 * P;
  in     if num < K then "${toString  num     }"
    else if num < M then "${toString (num / K)}K"
    else if num < G then "${toString (num / M)}M"
    else if num < T then "${toString (num / G)}G"
    else if num < P then "${toString (num / T)}T"
    else if num < E then "${toString (num / P)}P"
    else                 "${toString (num / E)}E"
  ;
}
