#!/usr/bin/env bash
set -e 

BACKUP_DIR=$externalMasterDir/.backups    
STATE_DB="$externalMasterDir/state.sqlite"
EXT_MASTER_CFG="$externalMasterDir/master.cfg"
EXT_MASTER_TAC="$externalMasterDir/buildbot.tac"
TWISTD_PID="$externalMasterDir/twistd.pid"
LAST_SETUP_FILE="$externalMasterDir/.last_setup_by"

if [[ -e $LAST_SETUP_FILE ]] && [[ $(cat $LAST_SETUP_FILE) == $ORIGIN ]]; then
    echo "The directory has already been provisioned by this version: $ORIGIN"
    echo "If you wan to force the setup, remove the file $LAST_SETUP_FILE"
    exit 
fi
   

function backupSetup(){
    local was_running=0
    local this_backup_dir="$BACKUP_DIR/$(date +'%Y%m%d_%H%M%S')"
    local current_bbb_bin="$(readlink  -f $EXT_MASTER_CFG  | cut -d/ -f 1-4)/bin"
    if [[ -e $TWISTD_PID ]] && [[ -d  /proc/$(cat $TWISTD_PID) ]]; then
        was_running=1
        echo "Running instance detected, stopping."
        $current_bbb_bin/bbb-master-stop
    fi
    mkdir $this_backup_dir
    mv $EXT_MASTER_TAC $EXT_MASTER_CFG  $this_backup_dir
    if [[ -e $STATE_DB ]]; then
        cp $STATE_DB $this_backup_dir/
    fi
    ln -s  $CONFIG_DIR/master.cfg $EXT_MASTER_CFG
    ln -s  $CONFIG_DIR/buildbot.tac  $EXT_MASTER_TAC
    echo "Old setup backed up to: $this_backup_dir"
    if (( was_running )); then
        echo "Starting new instance"
        $ORIGIN/bin/bbb-master-start
    fi
}


# the directory must exist
if [[ ! -d $externalMasterDir ]]; then
    echo "The directory $externalMasterDir does not exist" >&2
    exit 1
fi

## if the backup dir does not exists, create one
if [[ ! -d $BACKUP_DIR ]]; then
  mkdir  $BACKUP_DIR
fi


# if the master config file is a symlink
# proceed with the backup
if [[ -L $EXT_MASTER_CFG ]] && [[ -L $EXT_MASTER_TAC ]]; then
    echo "Previous symlinks for master.cfg and builtbot.tac detected"
    echo "Backing up previous setup"
    backupSetup
else
    ln -s -f $CONFIG_DIR/master.cfg $EXT_MASTER_CFG
    ln -s -f $CONFIG_DIR/buildbot.tac  $EXT_MASTER_TAC
    # required, otherwise the first run will not work
    $UPGRADE_MASTER_CMD
    rm $externalMasterDir/master.cfg.sample
fi

echo "$ORIGIN" > $LAST_SETUP_FILE
echo "External configuration ready at: $externalMasterDir"
