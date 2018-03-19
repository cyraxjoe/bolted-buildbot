{ callPackage
, buildbot-full
, buildbot-worker
, shellMode ? false
, externalMasterDir ? null
, masterConfigFile ? ./config.json
}:

rec {
  regular = callPackage ./regular.nix { 
    inherit shellMode masterConfigFile externalMasterDir;
  };

  with-local-workers = 
    let
    masterWithWorker = callPackage ./regular.nix { 
      buildbot-full = buildbot-full.overrideAttrs (old: {
        propagatedBuildInputs = old.propagatedBuildInputs ++ [ buildbot-worker ];
      });
      inherit shellMode masterConfigFile externalMasterDir;
    };
    in 
     # specify the type of master to be used in the init script
     masterWithWorker.overrideAttrs (old: {
       passthru = {
        init-master = callPackage ./init-master.nix { typeOfMaster = "local-workers"; };
       };
    });
}