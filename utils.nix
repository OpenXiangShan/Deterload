{ lib
, linkFarm
}: rec {
  getName = p: if (p?pname) then p.pname else p.name;
  escapeName = lib.converge (name:
    builtins.replaceStrings
      [" " "." "-" "__"]
      [""  "_"  "_" "_" ]
  name);
  /*set -> set: filter derivations in a set*/
  filterDrvs = set: lib.filterAttrs (n: v: (lib.isDerivation v)) set;
  /*set -> set:
    wrap-l2 {
      a={x=drv0; y=drv1; z=drv2; w=0;};
      b={x=drv3; y=drv4; z=drv5; w=1;};
      c={x=drv6; y=drv7; z=drv8; w=2;};
    }
    returns {
      x=linkFarm xNewName [drv0 drv3 drv6];
      y=linkFarm yNewName [drv1 drv4 drv7];
      z=linkFarm zNewName [drv2 drv5 drv8];
    }*/
  wrap-l2 = attrs: let
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
    value = linkFarm (
      # Assuming the name of drv is mmm.400_perlbmk.nnn, we want mmm.nnn
      # Take spec2006 for an example:
      # full = spec2006_ref_gcc_14_2_0_O3_flto_rv64gc_glibc_jemalloc.400_perlbench.1core_3_checkpoint
      # front= spec2006_ref_gcc_14_2_0_O3_flto_rv64gc_glibc_jemalloc
      # tail = 1core_3_checkpoint
      # res  = spec2006_ref_gcc_14_2_0_O3_flto_rv64gc_glibc_jemalloc.1core_3_checkpoint
      let full = (builtins.head (builtins.attrValues attrs))."${name}".name;
          split= lib.splitString "." full;
          front= lib.init (lib.init split);
          last = lib.last split;
      in builtins.concatStringsSep "." (front ++ [last])
    ) (
      lib.mapAttrsToList (testCase: attr: {
        name = testCase;
        path = attr."${name}";
      }) attrs);
  }) (attrDrvNames attrs);

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
