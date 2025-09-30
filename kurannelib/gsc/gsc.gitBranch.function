gitBranchCreate() {
    git checkout -b "$branchName" || { echo "$ERROR Failed to create branch $branchName"; errorExit; }
    echo "$SUCCESS Created and switched to branch: $branchName"
}

gitBranchList() {
    git branch -a
}

gitBranchDelete() {
    git branch -d "$branchDeleteName" || { echo "$ERROR Failed to delete branch $branchDeleteName"; errorExit; }
    echo "$SUCCESS Deleted branch $branchDeleteName"
}

gitDeleteMergeBranches() {
    local currentBranch=$(git rev-parse --abbrev-ref HEAD)
    git branch --merged | egrep -v "(^\*|master|main|dev)" | while read branchBranch; do
        echo "${WARNING} Deleting merged branch: $branchBranch"
        git branch -d "$branchBranch" || echo "${ERROR} Failed to delete branch: $branchBranch"
    done
    echo "${SUCCESS} Merged branches deleted (not master/main/dev and $currentBranch)"
}
gitMergeBranch() {
    local branches=($(git branch --format='%(refname:short)'))
    if [ ${#branches[@]} -eq 0 ]; then
        echo "$ERROR Not found branch."
        errorExit
    elif [ ${#branches[@]} -lt 2 ]; then
        echo "$ERROR Found only one branch."
        errorExit
    fi
    echo "$CHOICE Select a branch to merge"
    select selbranch in $branches[@]; do
        if [ -n $selbranch ]; then
            break
        fi
    done
    newbranches=()
    for bchs in ${branches[@]}; do
        if [[ "$bchs" != "$selbranch" ]]; then
            newbranches+=$bchs
        fi
    done
    echo "$CHOICE Select branch to merge ${selbranch} into"
    select branchsel in $newbranches; do
        if [ -n $branchsel ]; then
            break
        fi
    done
    echo -n "$CHOICE Want to pull before?[y/N]"
    if read -q; then
        gitPull && echo -e "\n$SUCCESS Pulled"   
    fi
    echo
    git checkout "$branchsel" || { echo "$ERROR Failed to switch tp $branchsel"; errorExit; }
    git merge "$selbranch" || { echo "$ERROR Failed to merge."; errorExit; }
    echo "$SUCCESS Merge!"
}   