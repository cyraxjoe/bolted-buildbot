{ callPackage
, buildbot
, buildbot-worker
, buildbot-plugins
, utilFuncs
, plugins ? [ "www" "console-view" "waterfall-view" "grid-view" "wsgi-dashboards" "badges" ]
, externalMasterDir ? null
, masterSrc ? null
, masterConfigFile ? ./config.json
}:

let
  inherit(builtins) map getAttr hasAttr;
  inherit(utilFuncs) bigErrorMsg;

  extraPlugins = callPackage ./plugins.nix {};

  getPlugin = plugin: 
    if (hasAttr plugin extraPlugins) 
     then getAttr plugin extraPlugins
    else # try in the plugins in nixpkgs
      (if (hasAttr plugin buildbot-plugins) 
         then getAttr plugin buildbot-plugins
       else 
         (abort (bigErrorMsg "The plugin '${plugins}' is not supported.")));

  pluginSelection = map getPlugin plugins;

  buildbotFull = buildbot.withPlugins pluginSelection;

  buildbotFullWithWorker = buildbotFull.overrideAttrs (old: {
     propagatedBuildInputs = old.propagatedBuildInputs ++ [ buildbot-worker ];
  });

  regularMasterParams = { 
    inherit utilFuncs callPackage buildbotFull masterSrc masterConfigFile externalMasterDir;
  };

  withLocalWorkersParams = (regularMasterParams // {
    buildbotFull = buildbotFullWithWorker;
  });

  masterWithWorker = callPackage ./regular.nix withLocalWorkersParams;
in 
{
  regular = callPackage ./regular.nix regularMasterParams;
  with-local-workers = masterWithWorker.overrideAttrs (old: {
    # specify the type of master to be used in the init script
    name = "bbb-lw-master-${ old.version }";
    passthru = {
      init-master = callPackage ./init-master.nix { typeOfMaster = "local-workers"; };
    };
  });
}
