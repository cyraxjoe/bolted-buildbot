{ nixpkgs
, bbb
, masterConfig
, externalMasterDir
}:
let 
  masterConfigDrv = with (import nixpkgs {});
  stdenv.mkDerivation {
     name = "master-config";
     src = masterConfig;
     phases = [ "buildPhase" ];
     buildPhase = ''
       mkdir $out
       cp -r  $src/* $out/
       substituteInPlace $out/config.json --subst-var-by NIX_STORE_PATH $out
     '';
  };
  masterConfigFile = "${masterConfigDrv}/config.json";
  bolted-buildbot = import bbb { inherit nixpkgs  masterConfigFile externalMasterDir; };
in {
  inherit (bolted-buildbot) lw-master;
}
