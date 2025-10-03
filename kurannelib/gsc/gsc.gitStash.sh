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