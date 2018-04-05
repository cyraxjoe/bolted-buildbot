{ lib
# custom params
, bigErrorMsg 
, buildbotFull
, masterSrc
, externalMasterDir
, masterPortStr
, masterUIPortStr
}:
let
  inherit (lib) inNixShell;

  inherit (builtins) typeOf;

  buildbotPath = "${ buildbotFull }/bin/buildbot"; 
in 
assert (inNixShell == false && externalMasterDir == null) ->
  abort (bigErrorMsg "Missing required externalMasterDir parameter");

rec {
  inherit masterSrc externalMasterDir; 

  externalSetupName = "_bbb-master-setup";

  externalSetupScript = ./scripts/external-master-setup.sh;

  installPhase =  let
     baseBBBCmd = "$out/bin/bbb-master";
     BBBExternalSetupScript = "$out/bin/${ externalSetupName }";
     configDir = "$out/etc/bbb-master";
     make3BWrapper = cmd: ''
       makeWrapper ${ buildbotPath }  ${ baseBBBCmd }-${ cmd } \
         --add-flags ${ cmd } \
         --add-flags $externalMasterDir \
         --set BBB_CONFIG_DIR "$CONFIG_DIR" \
         --set BBB_MASTER_PORT "${ masterPortStr }" \
         --set BBB_MASTER_UI_PORT "${ masterUIPortStr }"
     '';
   in ''
     CONFIG_DIR=${ configDir }

     mkdir -p $CONFIG_DIR

     cp -R  ${ masterSrc }/* $CONFIG_DIR

     pushd $CONFIG_DIR

     ${ buildbotPath } checkconfig $masterConfigFile;

     popd

     # delete the residual pyc from the check 
     find $out -name '*.pyc' -delete

     ${ make3BWrapper "start" }

     ${ make3BWrapper "stop" }

     ${ make3BWrapper "restart" }

     ${ make3BWrapper "reconfig" }

     ${ make3BWrapper "upgrade-master" }

     makeWrapper ${ buildbotPath } ${ baseBBBCmd } 

     makeWrapper ${ externalSetupScript }  ${ BBBExternalSetupScript } \
          --set CONFIG_DIR $CONFIG_DIR \
          --set UPGRADE_MASTER_CMD $out/bin/bbb-master-upgrade-master \
          --set externalMasterDir $externalMasterDir \
          --set ORIGIN $out
     '';
}
