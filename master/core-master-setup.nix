{ copyPathToStore
, writeShellScriptBin
, buildbotFull
, shellMode
, masterSrc
, masterSrcConfig
, externalMasterDir
, masterPortStr
, masterUIPortStr
}:
let
  buildbotPath = "${ buildbotFull }/bin/buildbot"; 
  inherit (builtins) typeOf hasAttr getAttr toPath pathExists;
in 
assert (shellMode == false && externalMasterDir == null)  -> 
  abort "Missing required externalMasterDir parameter";

assert (masterSrcConfig != null) &&  !(hasAttr "type" masterSrcConfig) ->
  abort "Missing required property 'type' in the masterSrc property";

assert (masterSrcConfig != null) && 
       (with masterSrcConfig; (type != "directory") && (type != "fetchurl")) ->
  abort "Invalid type of '${ masterSrcConfig.type }'";

let 
  masterSrcBuilders = {
     directory = args:  copyPathToStore args;
     fetchurl = args: args; # do something with fetchurl;
  };
  masterSrc' = with masterSrcConfig; ((getAttr type masterSrcBuilders) args);

in
({ masterSrc = if masterSrc  == null then masterSrc' else masterSrc; } // rec {
  inherit externalMasterDir;
  externalSetupName = "_bbb-master-setup";
  externalSetupScript = ./scripts/external-master-setup.sh;
  installPhase = with rec {
      baseBBBCmd = "$out/bin/bbb-master";
      BBBExternalSetupScript = "$out/bin/${externalSetupName}";
      configDir = "$out/etc/bbb-master";
      make3BWrapper = cmd: ''
        makeWrapper ${buildbotPath}  ${baseBBBCmd}-${cmd} \
          --add-flags ${cmd} \
          --add-flags $externalMasterDir \
          --set BBB_CONFIG_DIR "$CONFIG_DIR" \
          --set BBB_MASTER_PORT "${masterPortStr}" \
          --set BBB_MASTER_UI_PORT "${masterUIPortStr}"
      '';

    }; ''
     CONFIG_DIR=${configDir}
     mkdir -p $CONFIG_DIR
     cp -R  ${ masterSrc }/* $CONFIG_DIR
     pushd $CONFIG_DIR
     ${buildbotPath} checkconfig $masterConfigFile;
     popd
     # delete the residual pyc from the check 
     find $out -name '*.pyc' -delete
     ${make3BWrapper "start"}
     ${make3BWrapper "stop"}
     ${make3BWrapper "restart"}
     ${make3BWrapper "reconfig"}
     ${make3BWrapper "upgrade-master"}
     makeWrapper ${buildbotPath} ${baseBBBCmd} 
     makeWrapper ${externalSetupScript}  ${BBBExternalSetupScript} \
          --set CONFIG_DIR $CONFIG_DIR \
          --set UPGRADE_MASTER_CMD $out/bin/bbb-master-upgrade-master \
          --set externalMasterDir $externalMasterDir \
          --set ORIGIN $out

  '';
})
