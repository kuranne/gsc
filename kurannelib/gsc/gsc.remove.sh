gitrpstryRemove() { #gsc remove
    gitValidateRepo || errorExit
    
    echo -ne "${WARNING} Want to backup?(Y/y to confirm): "
    read -k 1 varBackup
    if [[ "$varBackup" == "Y" || "$varBackup" == "y" ]]; then
    backupAll || errorExit
    fi
    echo -ne "${WARNING} ${RED}¿Remove repo?${NC}(Y/y to confirm): "
    read -k 1 varRemoveAns
    if [[ "$varRemoveAns" == "Y" || "$varRemoveAns" == "y" ]]; then
        [ -f .gitignore ] && rm .gitignore
        [ -d .git ] && rm -rf .git
        [ -f .gsc.config ] && rm .gsc.config
        echo -e "${RED}REMOVED${NC} :>"
    else
        echo -e "${CYAN}CANCELLED${NC}"
    fi
    
}