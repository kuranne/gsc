backupAll() {
    if [ ! -d "$backupDir" ]; then
        mkdir "$backupDir" || errorExit
    fi
    local backupName="$(date +%Y%m%d%H%M%S)"
    mkdir "${backupDir}/${backupName}" || { echo "${ERROR} Failed to backup"; errorExit; }
    cp -r "${hereDir}" "${backupDir}/${backupName}" || { echo "${ERROR} Failed to backup"; errorExit; }
    echo "${SUCCESS} Backup!"
}

restoreAll() {
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

removeBackup() {
    gscValidateBackup

    local backups=($(ls -1 "$backupDir"))
    if [ ${#backups[@]} -eq 0 ]; then
        ehco "$ERROR No backups."
        errorExit
    fi

    local backupChoices=("All" "Select")
    echo "$CHOICE Remove all or select?"
    select backupChoice in "${backupChoices[@]}"; do
        [ -n "$backupChoice" ] && break
    done
    if [[ "$backupChoice" == "Select" ]]; then
        select backupChoose in "${backups[@]}"; do
            [ -n "$backupChoose" ] && break
        done
    elif [[ "$backupChoice" == "All" ]]; then
        backupChoose="*"  
    fi

    echo "$WARNING Are you sure to remove ${backupChoose}?[y/N]: "
    while true; do
        read -k 1 removeChoice
        if [[ "$removeChoice" == "Y" || "$removeChoice" == "y" ]]; then
            rm -rf "${backupDir}/${backupChoose}" || errorExit
            echo "${RED}REMOVED:)${NONE}"
            break
        elif [[ "$removeChoice" == "N" || "$removeChoice" == "n" ]]; then
            echo "${CYAN}CANNCLED:)${NONE}"
            break
        else
            ehco "[y/N] y is yes and n is no: "
        fi
    done
}