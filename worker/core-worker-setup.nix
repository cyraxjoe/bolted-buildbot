{ buildbot-worker
, writeShellScriptBin
# worker specific params
, externalWorkerDir
, config }:
assert (externalWorkerDir == null)  -> 
   abort "Missing required externalWorkerDir parameter";
rec {
  inherit externalWorkerDir;
  externalSetupName = "_bbb-worker-${ config.name }-setup";

  externalSetupScript = writeShellScriptBin externalSetupName ''
     # the directory must exist
     # create the dir outside
     if [[ ! -d $externalWorkerDir ]]; then
         echo "The directory $externalWorkerDir does not exist" >&2
         exit 1
     fi
     (! [[ -d $externalWorkerDir/info ]]) && mkdir $externalWorkerDir/info      
     ln -s -f $CONFIG_DIR/buildbot.tac  $externalWorkerDir/buildbot.tac
     ln -s -f $INFO_DIR/admin  $externalWorkerDir/info/admin
     ln -s -f $INFO_DIR/host  $externalWorkerDir/info/host
     echo "External configuration ready at: $externalWorkerDir"
  '';

  installPhase = with rec {
      buildbotWorkerPath =  "${buildbot-worker}/bin/buildbot-worker";
      externalSetupScript' = "${externalSetupScript}/bin/${externalSetupName}";
      baseBBBWorkerCmd = "$out/bin/bbb-worker-${ config.name }"; 
      BBBWorkerExternalSetupScript = "$out/bin/${externalSetupName}";
      makeBBWorkerWrapper = cmd: ''
        makeWrapper ${buildbotWorkerPath}  ${baseBBBWorkerCmd}-${cmd} \
          --add-flags ${cmd} \
          --add-flags $externalWorkerDir
      '';
      configSubstitutes = ''\
        --subst-var externalWorkerDir  \
        --subst-var-by masterHost ${ config.master.host } \
        --subst-var-by masterPort ${ config.master.port } \
        --subst-var-by workerName ${ config.name }  \
        --subst-var-by workerKeepAlive ${ config.keepalive } \
        --subst-var-by workerUmask ${ config.umask } \
        --subst-var-by workerMaxDelay ${ config.maxdelay } \
        --subst-var-by workerNumCPUs ${ config.numcpus } \
        --subst-var-by workerAllowShutdown ${ config.allow_shutdown } \
        --subst-var-by workerMaxRetries ${ config.maxretries }
      '';
  }; ''
    CONFIG_DIR=$out/etc/bbb-worker
    INFO_DIR=$CONFIG_DIR/info
    mkdir -p $INFO_DIR # it also creates the base CONFIG_DIR
    substituteInPlace buildbot.tac ${ configSubstitutes }
    cp buildbot.tac $CONFIG_DIR
    echo "${ config.admin }" > $INFO_DIR/admin
    echo "${ config.description }" > $INFO_DIR/host
    echo "Configured externalWorkerDir: $externalWorkerDir" > $INFO_DIR/.external-worker-dir
    ${makeBBWorkerWrapper "start"}
    ${makeBBWorkerWrapper "stop"}
    ${makeBBWorkerWrapper "restart"}

    makeWrapper ${buildbotWorkerPath} ${baseBBBWorkerCmd} \
         --add-flags $externalWorkerDir

    makeWrapper ${externalSetupScript'}  ${BBBWorkerExternalSetupScript} \
         --set CONFIG_DIR $CONFIG_DIR \
         --set INFO_DIR $INFO_DIR \
         --set externalWorkerDir $externalWorkerDir
  '';
}
