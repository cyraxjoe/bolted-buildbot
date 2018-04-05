{ stdenv
, callPackage
, lib
, makeWrapper
# custom params
, utilFuncs
, buildbotFull
, externalMasterDir
, masterConfigFile
, masterSrc
}:
let 
  inherit(lib) getVersion versionAtLeast importJSON;
  inherit(builtins) typeOf hasAttr tryEval;
  inherit(utilFuncs) coerceToString missingAttr bigErrorMsg;

  minVersion = "1.0"; 
  currentVersion = getVersion buildbotFull.name;
  config = importJSON masterConfigFile;
in
  assert !(versionAtLeast currentVersion  minVersion) ->
    abort (bigErrorMsg ''
      The buildbot master in nixpkgs needs to be at least at version ${ minVersion }.

      Current version: ${ currentVersion }
    '');

  assert missingAttr "port" config -> 
    abort (bigErrorMsg "Missing required 'port' in the config file");

  assert missingAttr "webUIport" config -> 
    abort (bigErrorMsg "Missing required 'webUIport' in the config file");

let
  # main attributes of the master.
  #
  # note that we are not using callPackage on purpose, the function
  # assumes that the return value is a derivation and includes 
  # override and overrideDerivation, in this case we just want to
  # obtain the plain attribute set
  BBBMaster = import ./core-master-setup.nix { 
    inherit lib bigErrorMsg buildbotFull masterSrc externalMasterDir;
    masterPortStr = (coerceToString config.port);
    masterUIPortStr = (coerceToString config.webUIport);
  };

  # init package
  BBBInit = callPackage ./init-master.nix { };
in

stdenv.mkDerivation (BBBMaster // rec {
  name = "bbb-regular-master-${ version }";
  version = "0.0.1";
  src = ./.;
  buildInputs = [ buildbotFull makeWrapper ];
  passthru = {
    init-master = BBBInit;
  };
  shellHook = ''
    export PATH="${ passthru.init-master }:$PATH"
    echo "Run '${ passthru.init-master.name } <target-dir>' to initialize a master repo"
  '';
})
