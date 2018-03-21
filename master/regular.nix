{ stdenv
, copyPathToStore
, lib
, runCommand
, writeShellScriptBin
, makeWrapper
, buildbot-full
# custom params
, externalMasterDir
, shellMode
, masterConfigFile
, masterSrc
}:

let 
  inherit(lib) getVersion versionAtLeast importJSON;
  minVersion = "1.0"; 
  currentVersion = getVersion buildbot-full.name;
in
  assert !(versionAtLeast currentVersion  minVersion) -> 
    abort ''
    #########################################################
    The buildbot master in nixpkgs needs to be at least at version ${minVersion}.

    Current version: ${currentVersion}
    ##########################################################
  '';
with {
  config = importJSON masterConfigFile;
  missingAttr = a: config: !(builtins.hasAttr a config);
};
  assert missingAttr "port" config -> 
    abort "Missing required 'port' in the config file.";
  assert missingAttr "webUIport" config -> 
    abort "Missing required 'webUIport' in the config file.";
  assert (missingAttr "masterSrc" config && masterSrc == null) -> 
    abort "Missing required 'masterSrc' in the config file.";
let
  BBBMaster = with rec {
    coerceToString = prop: with builtins; if (typeOf prop) == "int" then toString prop else prop;
    masterPortStr = coerceToString config.port;
    masterUIPortStr = coerceToString config.webUIport;
    masterSrcConfig = if masterSrc == null  then config.masterSrc else null;
    params = { inherit 
      copyPathToStore
      writeShellScriptBin buildbot-full shellMode
      masterSrc
      masterSrcConfig externalMasterDir masterPortStr masterUIPortStr;
    };
  }; import ./core-master-setup.nix params;
  BBBInit = import ./init-master.nix { 
      inherit(lib) getAttr;
      inherit stdenv makeWrapper writeShellScriptBin;
  };
in 
stdenv.mkDerivation (BBBMaster // rec {
  name = "bbb-master-${version}";
  version = "0.0.1";
  src = ./.;
  buildInputs = [ buildbot-full makeWrapper ];
  passthru = {
    init-master = BBBInit;
  };
  shellHook = ''
    export PATH="${ passthru.init-master }:$PATH"
    echo "Run '${ passthru.init-master.name } <target-dir>' to initialize a master repo"
  '';
})
