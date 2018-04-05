{ stdenv
, makeWrapper
, writeShellScriptBin 
, typeOfMaster ? "regular"
}:
let
  inherit(builtins) getAttr;

  skelMap = {
    regular = ./skel/regular;
    local-workers = ./skel/local-workers;
  };

  src = (getAttr typeOfMaster skelMap);

in
stdenv.mkDerivation rec {
  inherit src;

  name = "bbb-master-${ typeOfMaster }-init";

  phases = ["installPhase"];

  buildInputs = [ makeWrapper ];

  masterInitScript = writeShellScriptBin "init-script" ''
    TARGET_DIR=$1
    if [[ ! -d $TARGET_DIR ]]; then
      mkdir $TARGET_DIR
    fi
    cp $MASTER_FILE $BUILDBOT_TAC $TARGET_DIR
    chmod u+w $TARGET_DIR/{master.cfg,buildbot.tac}
    echo "Configured at $TARGET_DIR"
  '';

  installPhase = ''
    mkdir $out
    cp  $src/master.cfg $src/buildbot.tac $out/
    makeWrapper ${ masterInitScript }/bin/init-script "$out/bbb-master-init" \
       --set MASTER_FILE "$out/master.cfg" \
       --set BUILDBOT_TAC "$out/buildbot.tac" 
  '';
}
