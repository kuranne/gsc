backupAll() {
    if [ ! -d "${HOME}/.gscbackup" ]; then
        mkdir "$HOME/.gscbackup" || errorExit
    fi
    local backupName="$(date +%Y%m%d%H%M%S)"
    mkdir "${HOME}/.gscbackup/${backupName}" || { echo "${ERROR} Failed to backup"; errorExit; }
    cp -r "${hereDir}" "${HOME}/.gscbackup/${backupName}" || { echo "${ERROR} Failed to backup"; errorExit; }
    echo "${SUCCESS} Backup!"
}

restoreAll() {
    local backupDir="$HOME/.gscbackup"
    if [ ! -d "$backupDir" ]; then
        echo "$ERROR No backup directory found at $backupDir"
        errorExit
    fi
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