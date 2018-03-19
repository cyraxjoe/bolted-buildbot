{ nixpkgs ? <nixpkgs>
, shellMode ? false
, masterConfigFile ? null
, externalMasterDir ? null
, externalWorkerDir ? null
, workerConfigFile ? null
}:
let 
  inherit(import nixpkgs {}) lib pkgs;
  inherit(lib) callPackageWith optionalAttrs removeSuffix;
  # ^ base libaries ^

  callPackage = callPackageWith pkgs;
  baseMaster = callPackage ./master ({ inherit shellMode;  } //
    (optionalAttrs (masterConfigFile != null) { inherit masterConfigFile;} ) //
    # remove trailing slash 
    (optionalAttrs (externalMasterDir != null) { externalMasterDir = removeSuffix "/" externalMasterDir;} ));
in {
  master = baseMaster.regular;
  # master with local workers
  lw-master = baseMaster.with-local-workers;
  # only pass the workerConfigFile when is not null, otherwise it will 
  # use the default argument in the worker default expression
  worker = callPackage ./worker ({
    inherit externalWorkerDir;
  } // (if workerConfigFile != null then { inherit workerConfigFile;} else  {}));
}
