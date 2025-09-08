gitrpstryRemove() { #gsc remove
    gitValidateRepo || errorExit
    
    echo -ne "${WARNING} ${RED}¿Remove repo?${NC}(Y/y or Enter to confirm): "
    read varRemoveAns
    echo -ne "${WARNING} Want to backup?(Y/y or Enter to confirm)"
    read varBackup
    if [[ "$varBackup" == "Y" || "$varBackup" == "y" || -z "$varBackup" ]]; then
    backupAll || errorExit
    fi
    if [[ "$varRemoveAns" == "Y" || "$varRemoveAns" == "y" || -z "$varRemoveAns" ]]; then
        [ -f .gitignore ] && rm .gitignore
        [ -d .git ] && rm -rf .git
        [ -f .gsc.config ] && rm .gsc.config
        echo -e "${RED}REMOVED${NC} :>"
    else
        echo -e "\n${CYAN}CANCELLED${NC}"
    fi
    
}

gitrpstryResetHard() {
    gitValidateRepo || errorExit

    echo -ne "${WARNING} ${RED}¿Reset HARD?${NC}(Y/y or Enter to confirm): "
    read varResetAns
    echo -ne "${WARNING} Want to backup?(Y/y or Enter to confirm)"
    read varBackup
    if [[ "$varBackup" == "Y" || "$varBackup" == "y" || -z "$varBackup" ]]; then
    backupAll || errorExit
    fi
    if [[ "$varResetAns" == "Y" || "$varResetAns" == "y" || -z "$varResetAns" ]]; then
        git reset --hard HEAD || { echo "${ERROR} reset failed"; errorExit; }        
        git clean -fd || { echo "${ERROR} clean failed"; errorExit; }
    else
        echo "${CYAN}CANCELLED${NC}"
    fi
    
}

gitSync() {
    gitValidateRepo || errorExit
    git fetch --all --prune || { echo "$ERROR Failed to fetch"; errorExit; }
    git pull || { echo "$ERROR Failed to pull"; errorExit; }
    echo "$SUCCESS Synced with remote"
}

gitStashSave() {
    gitValidateRepo || errorExit
    local msg="$1"
    git stash push -m "$msg" || { echo "$ERROR Failed to stash"; errorExit; }
    echo "$SUCCESS Stashed with message: $msg"
}

gitStashPop() {
    gitValidateRepo || errorExit
    git stash pop || { echo "$ERROR Failed to pop stash"; errorExit; }
    echo "$SUCCESS Stash popped"
}

gitBlame() {
    gitValidateRepo || errorExit
    git blame "$blameFile" || { echo "$ERROR Failed to blame $blameFile"; errorExit; }
}