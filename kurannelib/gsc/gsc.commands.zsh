#--- gscUpdate ---#
update() {
    gitValidateNotFoundGit || errorExit
    source "${nowDir}/kurannelib/gsc/gsc.update.sh" || { echo "$ERROR Failed to source gsc.update.sh"; errorExit; }
    if [ $# -gt 0 ]; then
        local gitIgnoreFlag=0
        local config_Flag=0

        while getopts "ci" opt; do
            case $opt in
              c) config_Flag=1;;
              i) gitIgnoreFlag=1;;
              \?) echo -e "
$ERROR Unknow Option, use
-c    update .gsc.config
-i    update gitignore

Usecase
update -ci
"; errorExit;;
            esac
        done

        shift $((OPTIND - 1))

        [[ $gitIgnoreFlag -eq 1 ]] && gscUpdateIgnore
        [[ $config_Flag -eq 1 ]] && gscUpdateConfig
    else
        echo -n "$CHOICE This command will update .gsc.config and gitignore, confirm?[y/N]: "
        if read -q; then
            echo
            gscUpdateConfig && gscUpdateIgnore
            echo "$SUCCESS Update both!"
        else
            echo -e "\n$ANNOUNCE Cancelled update."
        fi
    fi
}

#--- Remove gsc or directory ---#
remove() {
    source "${nowDir}/kurannelib/gsc/gsc.remove.sh" || { echo "$ERROR Failed to source gsc.remove.sh"; errorExit; }
    if [ $# -gt 0 ]; then
        for arg in "$@"; do
            case $arg in
                repository) removeRepo ;;
                repo) removeRepo ;;
                rp) removeRepo ;;
                backup) removeBackup;;
                bu) removeBackup;;
                *)  echo -e "
$ERROR Unknow type, use
repository or repo or rp        remove repository
backup or bu                    remove backup

Usecase
gsc remove rp
"; errorExit;;
            esac
        done
    else
        local removechoice=("repository" "backup")
        echo "$CHOICE select which one to remove."
        select answer in "${removechoice[@]}"; do
            [ -n "$answer" ] && break
        done
        if [[ "$answer" == "repository" ]]; then
            removeRepo || errorExit
        else
            removeBackup || errorExit
        fi
    fi
}


backup() {
    if [ ! -d "$backupDir" ]; then
        mkdir "$backupDir" || errorExit
    fi
    local backupName="$(date +%Y%m%d%H%M%S)"
    mkdir "${backupDir}/${backupName}" || { echo  "${ERROR} Failed to create a backup directory"; errorExit; }
    cp -r "${hereDir}" "${backupDir}/${backupName}" || { echo "${ERROR} Failed to copy the directory to backup"; errorExit; }
    echo "${SUCCESS} Backup to ${backupDir}/${backupName}."
}

restore() {
    gscValidateBackup
    echo "${CHOICE} Available backups:"
    local backups=($(ls -1 "$backupDir"))
    if [ ${#backups[@]} -eq 0 ]; then
        echo "$ERROR No backups available"
        errorExit
    fi
    select chosenBackup in "${backups[@]}"; do
        [ -n "$chosenBackup" ] && break
    done
    local restorePath="$backupDir/$chosenBackup"
    if [ ! -d "$restorePath" ]; then
        echo "$ERROR Selected backup does not exist"
        errorExit
    fi
    echo "${WARNING} Restoring backup from $restorePath into current directory"
    cp -r "$restorePath"/* "$hereDir"/ || { echo "$ERROR Failed to restore backup"; errorExit; }
    echo "$SUCCESS Restored backup from $chosenBackup"
}

help() {
    echo -e "
gsc <option>        base function for git support
gsc re <option>     reset Hard or Soft or rename the commit message
gsc branch <option> branch command
gsc tag <option>    tag command
gsc remove          remove command
gsc backup          to backup directory to ~/.gscbackup
gsc restore         to restore directory from ~/.gscbackup
gsc update          update .gsc.config and else
gsc stash           stash command"
}