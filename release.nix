{ nixpkgs ? <nixpkgs>
, masterSrc ? null
, masterConfigFile ? null
, masterPlugins ? null
, externalMasterDir ? "/tmp/bbb-master"
, externalWorkerDir ? "/tmp/bbb-worker"
, workerConfigFile ? null
, bbb ? ./.
}:
let
  pkgs = import nixpkgs {}; 
  inherit(pkgs) copyPathToStore;
  inherit(pkgs.lib) isStorePath optionalAttrs;

  masterSrc' = (if isStorePath masterSrc
                 then masterSrc
               else
                 copyPathToStore masterSrc);
  params =  { inherit 
    nixpkgs masterConfigFile masterPlugins 
    externalMasterDir externalWorkerDir workerConfigFile;
  };
  B3 = import bbb (
    params  // (optionalAttrs (masterSrc != null) { masterSrc = masterSrc'; })
  ); 

in {
  inherit (B3) master-regular master-lw worker;
}
