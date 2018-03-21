{ callPackage
, buildbot-full
, buildbot-worker
, shellMode ? false
, externalMasterDir ? null
, masterSrc ? null
, masterConfigFile ? ./config.json
}:

rec {
  regular = callPackage ./regular.nix { 
    inherit shellMode masterSrc masterConfigFile externalMasterDir;
  };

  with-local-workers = 
    let
    masterWithWorker = callPackage ./regular.nix { 
      buildbot-full = buildbot-full.overrideAttrs (old: {
        propagatedBuildInputs = old.propagatedBuildInputs ++ [ buildbot-worker ];
      });
      inherit shellMode masterSrc masterConfigFile externalMasterDir;
    };
    in 
     # specify the type of master to be used in the init script
     masterWithWorker.overrideAttrs (old: {
       passthru = {
        init-master = callPackage ./init-master.nix { typeOfMaster = "local-workers"; };
       };
    });
}
