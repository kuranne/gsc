#--- gscUpdate ---#
update() {
    gitValidateNotFoundGit || errorExit
    gscUpdateConfig() {
        { [[ -f "$hereDir/.gsc.config" ]] && cp "$nowDir/kurannelib/gsc.config" "$hereDir/.gsc.config"; } || errorExit
        echo "$SUCCESS Update config Successful"
    }

    gscUpdateIgnore() {
        { [[ -f "$hereDir/.gitignore" ]] && cp "$gitIgnorePath" "$hereDir/.gitignore"; } || errorExit
        echo "$SUCCESS Update gitignore Successful"
    }
    
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
            gscUpdateConfig && gscUpdateIgnore
            echo -e "\n$SUCCESS Update both!"
        else
            echo -e "\n$ANNOUNCE Cancel update."
        fi
    fi
}

#--- Remove gsc or directory ---#
remove() {
    removeRepo() {
        echo "$WARNING All for remove this directory."
        gitRemoveChioce=("All" "gsc Only")

        select removeChoice in "${gitRemoveChioce[@]}"; do
            [ -n "$removeChoice" ] && break
        done

        if [[ "${removeChoice}" == "gsc Only" ]]; then
            echo -ne "${WARNING} ${RED} Remove? ${NC}[y/N]: "
            while true; do
                read -k 1 varRemoveAns
                if [[ "$varRemoveAns" == "Y" || "$varRemoveAns" == "y" ]]; then
                    [ -f .gsc.config ] && rm .gsc.config
                    echo -e "\n${RED}REMOVED${NC} :>"
                    break
                elif [[ "$varRemoveAns" == "N" || "$varRemoveAns" == "n" ]]; then
                    echo -e "\n${CYAN}CANCELLED${NC}"
                    break
                else
                    echo -e "\n$ERROR CANCELLED"
                    break
                fi
            done

        elif [[ "${removeChoice}" == "All" ]]; then
            gitValidateRepo

            echo -n "$CHOICE Want to backup?[y/N]: "
            if read -q; then
                backup || errorExit
            fi
            echo -n "$WARNING Are you sure to remove $(basename "${hereDir}")?[y/N]: "
            if read -q; then
                rm -rf "${hereDir}" || { echo "$ERROR Failed to remove"; errorExit; }
                echo -e "\n${RED}REMOVED${NC} :>"
            else
                echo -e "\n${CYAN}CANCELLED${NC}"
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
                echo "${RED}REMOVED:)${NC}"
                break
            elif [[ "$removeChoice" == "N" || "$removeChoice" == "n" ]]; then
                echo "${CYAN}CANNCLED:)${NC}"
                break
            else
                ehco "[y/N] y is yes and n is no: "
            fi
        done
    }
    
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
    mkdir "${backupDir}/${backupName}" || { echo "${ERROR} Failed to backup"; errorExit; }
    cp -r "${hereDir}" "${backupDir}/${backupName}" || { echo "${ERROR} Failed to backup"; errorExit; }
    echo "${SUCCESS} Backup!"
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