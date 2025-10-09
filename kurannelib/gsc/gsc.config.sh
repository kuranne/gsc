gitConfigPullRebase(){
    git config pull.rebase "$1" || { echo "$ERROR Failed to config"; errorExit;}
}