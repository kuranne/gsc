#--- Remove gsc or directory ---#

gitrpstryRemove() {
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

        echo -ne "${WARNING} Want to backup?(Y/y to confirm): "
        read -k 1 varBackup
        if [[ "$varBackup" == "Y" || "$varBackup" == "y" ]]; then
            backupAll || errorExit
        fi
        echo "$WARNING Are you sure to remove $(basename "${hereDir}")?[y/N]: "

        while true; do
            read -k 1 varRemoveAns
            if [[ "$varRemoveAns" == "Y" || "$varRemoveAns" == "y" ]]; then
                rm -rf "${hereDir}" || { echo "$ERROR Failed to remove"; errorExit; }
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

    fi

}