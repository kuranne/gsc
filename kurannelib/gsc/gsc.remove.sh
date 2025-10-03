removeRepo() {
    echo "$CHOICE Select the service."
    gitRemoveChioce=("remove this directory" "remove .gsc.config Only" "remove git and .gsc.config")
    select removeChoice in "${gitRemoveChioce[@]}"; do
        [ -n "$removeChoice" ] && break
    done
    if [[ "${removeChoice}" == "remove .gsc.config Only" ]]; then
        echo -n "${WARNING} This command will ${RED}REMOVE${NC} .gsc.config, confirm?[y/N]: "
        if read -q; then
            echo
            { [ -f .gsc.config ] && rm .gsc.config; } || { echo "$ERROR Failed to remove"; errorExit;}
            echo "$ANNOUNCE Remove .gsc.config Successful."
        else
            echo -e "\n$ANNOUNCE Cancelled."
        fi
    elif [[ "${removeChoice}" == "remove this directory" ]]; then
        echo -n "$CHOICE Do you want to backup this directory before remove?[y/N]: "
        if read -q; then
            echo
            backup || errorExit
        fi
        echo
        echo -n "$WARNING Do you sure to remove $(basename "${hereDir}")?[y/N]: "
        if read -q; then
            echo
            rm -rf "${hereDir}" || { echo "$ERROR Failed to remove"; errorExit; }
            echo "$ANNOUNCE Removed."
        else
            echo -e "\n$ANNOUNCE Calcelled."
        fi
    elif [[ "${removeChoice}" == "remove git and .gsc.config" ]]; then
        gitValidateRepo
        echo -n "$WARNING Do you sure to remove .git and .gsc.config there?[y/N]: "
        if read -q; then
            echo
            rm -rf .git .gitignore .gsc.config || { echo "Failed to remove"; errorExit; }
            echo "$ANNOUNCE .git and .gsc.config is Removed"
        else
            echo -e "\n$ANNOUNCE Cancelled."
        fi
    fi
}

removeBackup() {
    gscValidateBackup
    local backups=($(ls -1 "$backupDir"))
    if [ ${#backups[@]} -eq 0 ]; then
        ehco "$ERROR No backups."
        errorExit
    fi
    local backupChoices=("All" "Select")
    echo "$CHOICE Select a backup to remove of remove all backups?"
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
    echo -n "$WARNING Do you sure to remove ${backupChoose}?[y/N]: "
    if read -q; then
        echo
        rm -rf "${backupDir}/${backupChoose}" || { echo "$ERROR Failed to remove ${backupChoose}"; errorExit; }
        echo "$ANNOUNCE $backupChoose is Removed."
    else
        echo -e "\n$ANNOUNCE Cancelled."
    fi
}