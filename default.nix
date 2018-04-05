{ nixpkgs ? <nixpkgs>
, masterSrc ? null
, masterConfigFile ? null
, masterPlugins ? null
, externalMasterDir ? null
, externalWorkerDir ? null
, workerConfigFile ? null
}:
let 
  inherit(import nixpkgs {}) lib pkgs;
  inherit(lib) callPackageWith optionalAttrs removeSuffix;
  utilFuncs = import ./utils.nix {};

  callPackage = callPackageWith pkgs;

  baseMaster = callPackage ./master ({ inherit utilFuncs callPackage masterSrc; } //
    (optionalAttrs (masterConfigFile != null) { inherit masterConfigFile; } ) //
    # remove trailing slash 
    (optionalAttrs (externalMasterDir != null) { 
      externalMasterDir = removeSuffix "/" externalMasterDir;
     }) //
    (optionalAttrs (masterPlugins != null) { plugins = masterPlugins; })
  );

in {
  # master without support for the local workers
  master-regular = baseMaster.regular;
  # master with local workers

  master-lw = baseMaster.with-local-workers;
  # only pass the workerConfigFile when is not null, otherwise it will 
  # use the default argument in the worker default expression

  worker = callPackage ./worker ({
    inherit utilFuncs externalWorkerDir;
  } // (if workerConfigFile != null then { inherit workerConfigFile;} else  {}));
}
