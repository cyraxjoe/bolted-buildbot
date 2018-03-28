{ callPackage
, buildbot
, buildbot-worker
, buildbot-plugins
, shellMode ? false
, externalMasterDir ? null
, masterSrc ? null
, masterConfigFile ? ./config.json
}:

let
  extraPlugins = callPackage ./plugins.nix {};

  buildbotFull = buildbot.withPlugins (
    with buildbot-plugins; 
    [ www console-view waterfall-view grid-view wsgi-dashboards extraPlugins.badges ]);

  buildbotFullWithWorker = buildbotFull.overrideAttrs (old: {
     propagatedBuildInputs = old.propagatedBuildInputs ++ [ buildbot-worker ];
  });
in  {
  regular = callPackage ./regular.nix { 
    inherit buildbotFull shellMode masterSrc masterConfigFile externalMasterDir; };

  with-local-workers = let
    masterWithWorker = callPackage ./regular.nix { 
      buildbotFull = buildbotFullWithWorker;
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
