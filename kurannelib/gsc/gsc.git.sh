#--- Reset ---#
gitrpstryResetHard() {
    gitValidateRepo || errorExit

    echo -ne "${WARNING} ${RED}¿Reset HARD?${NC}(Y/y to confirm): "
    read -k 1 varResetAns
    echo -ne "${WARNING} Want to backup?(Y/y to confirm)"
    read -k 1varBackup
    if [[ "$varBackup" == "Y" || "$varBackup" == "y" ]]; then
    backupAll || errorExit
    fi
    if [[ "$varResetAns" == "Y" || "$varResetAns" == "y" ]]; then
        git reset --hard HEAD || { echo "${ERROR} reset failed"; errorExit; }        
        git clean -fd || { echo "${ERROR} clean failed"; errorExit; }
    else
        echo "${CYAN}CANCELLED${NC}"
    fi
    
}

#--- Sync ---#
gitSync() {
    gitValidateRepo || errorExit
    git fetch --all --prune || { echo "$ERROR Failed to fetch"; errorExit; }
    gitPull || { echo "$ERROR Failed to pull"; errorExit; }
    echo "$SUCCESS Synced with remote"
}

#--- Stash ---#
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

#--- Blame ---#
gitBlame() {
    gitValidateRepo || errorExit
    git blame "$blameFile" || { echo "$ERROR Failed to blame $blameFile"; errorExit; }
}

#--- Clone ---#
gitrpstryClone() { #gsc -C <git repository url or ssh>
    gitValidateURL "$cloneUrl" || errorExit
    
    local varRepoName=$(basename "$cloneUrl" .git)
    [[ -d "$varRepoName" ]] && { echo "$ERROR Directory $varRepoName already exists"; errorExit; }
    
    git clone "${cloneUrl}" || { echo "$ERROR Failed to clone repository"; errorExit; }
    cd "$varRepoName" || { echo "$ERROR Failed to enter cloned directory"; errorExit; }
    
    echo "$SUCCESS Cloned directory: ${PINK}$varRepoName${NC}"
    echo "$WARNING Want to pull?(Y/y to confirm): "
    read -k 1 varPull
    { [[ $varPull == "Y" ]] || [[ $varPull == "y" ]];} && { gitPull || { echo "${WARNING} Failed to pull $varRepoName"; }}
}


#--- Init ---#
gitrpstryInit() {
    if [ -d .git ]; then
        echo -e "${DETECTED} Already initialized"
        return 0
    fi
    
    git init 2>/dev/null || { echo "$ERROR Failed to initialize repository"; errorExit; }
    echo -e "${GREEN}Alright! ${NC}Init Successful"
    
    
    # if we just switched account, configure it for this repo
    if [ -n "$currentAccount" ] && [ -n "${gitAccounts[$currentAccount]}" ]; then
        git config user.name "$currentAccount" || echo -e "${YELLOW}WARNING: Failed to set user name${NC}"
        git config user.email "${gitAccounts[$currentAccount]}" || echo -e "${YELLOW}WARNING: Failed to set user email${NC}"
    fi
}

#--- gitignore ---#
gitrpstryGitignore() {
    if [ -f .gitignore ]; then
        echo -e "$DETECTED .gitignore already exists, skipping..."
        return 0
    fi
    
    if [ -n "$gitIgnorePath" ] && [ -f "$gitIgnorePath" ]; then
        cat "$gitIgnorePath" >> .gitignore || { echo "$ERROR Failed to copy .gitignore template"; errorExit; }
        echo -e "\n# gsc Script\n.gsc.config" >> .gitignore

    else
        echo -e "${YELLOW}WARNING: ${NC}Template not found, creating basic .gitignore"
        cat > .gitignore << 'EOF'

#MacOS
.DS_Store

#vscode
.vscode/

#logs
*.log

#dependencies
node_modules/
EOF
        echo -e "\n# gsc Script\n.gsc.config" >> .gitignore

    fi
    echo -e "${SUCCESS} .gitignore created successfully"
}

#--- git Add ---#
gitrpstryAdd() {
    gitValidateRepo || errorExit
    
    git add . || { echo "$ERROR Failed to add files"; errorExit; }
    echo "$SUCCESS Files added to staging"
}

#--- git Commit ---#
gitrpstryCommit() {
    gitValidateRepo || errorExit
    

    if [ -z "$(git diff --cached --name-only)" ]; then
        git add . || { echo "$ERROR Failed to stage files"; errorExit; }
    fi

    gitValidateCommitMessage "$commitMessage" || errorExit
    
    git commit -m "$commitMessage" || { echo "$ERROR Failed to commit"; errorExit; }
    echo "$SUCCESS Committed with message: '$commitMessage'"
}

#--- git Pull ---#
gitPull() {
    gitValidateRepo || errorExit
    
    local remotes=($(git remote))
    if [ ${#remotes[@]} -eq 0 ]; then
        echo "$ERROR No remote found. Add a remote first with: git remote add <name> <url>"
        errorExit
    elif [ ${#remotes[@]} -gt 1 ]; then
        echo "${CHOICE} Multiple remotes found:"
        select chosenRemote in "${remotes[@]}"; do
            [ -n "$chosenRemote" ] && break
        done
        varPull="$chosenRemote"
    else
        varPull="${remotes[1]}"
    fi

    local branches=($(git branch --format='%(refname:short)'))
    if [ ${#branches[@]} -eq 0 ]; then
        echo "$ERROR No branches found."
        errorExit
    elif [ ${#branches[@]} -gt 1 ]; then
        echo "${CHOICE} Multiple branches found:"
        select chosenBranch in "${branches[@]}"; do
            [ -n "$chosenBranch" ] && break
        done
        varBranch="$chosenBranch"
    else
        varBranch="${branches[1]}"
    fi
    git push "$varPull" "$varBranch" || { echo "$ERROR Failed to pusll to $varPull/$varBranch"; errorExit; }
    echo "$SUCCESS Pushed to $varPull/$varBranch"
}

#--- git Push ---#
gitrpstryPush() {
    gitValidateRepo || errorExit

    local remotes=($(git remote))
    if [ ${#remotes[@]} -eq 0 ]; then
        echo "$ERROR No remote found. Add a remote first with: git remote add <name> <url>"
        errorExit
    elif [ ${#remotes[@]} -gt 1 ]; then
        echo "${CHOICE} Multiple remotes found:"
        select chosenRemote in "${remotes[@]}"; do
            [ -n "$chosenRemote" ] && break
        done
        varPush="$chosenRemote"
    else
        varPush="${remotes[1]}"
    fi

    local branches=($(git branch --format='%(refname:short)'))
    if [ ${#branches[@]} -eq 0 ]; then
        echo "$ERROR No branches found."
        errorExit
    elif [ ${#branches[@]} -gt 1 ]; then
        echo "${CHOICE} Multiple branches found:"
        select chosenBranch in "${branches[@]}"; do
            [ -n "$chosenBranch" ] && break
        done
        varBranch="$chosenBranch"
    else
        varBranch="${branches[1]}"
    fi
    echo "${WARNING} Want to pull before push?(Y/y to confirm): "
    read -k 1 varPushPullAns
    if [[ "$varPushPullAns" == "Y" || "$varPushPullAns" == "y" ]];then
        git pull "$varPush" || { echo "$ERROR Failed to pull from $varPush"; errorExit; }
    fi
    git push "$varPush" "$varBranch" || { echo "$ERROR Failed to push to $varPush/$varBranch"; errorExit; }
    echo "$SUCCESS Pushed to $varPush/$varBranch"
}

#--- Status ---#
gitStatus() {
    gitValidateRepo || errorExit
    git status
}

#--- Log ---#
gitLog() {
    gitValidateRepo || errorExit
    git log --oneline --graph --decorate -n 10
}

#--- Branch ---#
gitBranchCreate() {
    gitValidateRepo || errorExit
    git checkout -b "$branchName" || { echo "$ERROR Failed to create branch $branchName"; errorExit; }
    echo "$SUCCESS Created and switched to branch: $branchName"
}

gitBranchList() {
    gitValidateRepo || errorExit
    git branch -a
}

gitBranchDelete() {
    gitValidateRepo || errorExit
    git branch -d "$branchDeleteName" || { echo "$ERROR Failed to delete branch $branchDeleteName"; errorExit; }
    echo "$SUCCESS Deleted branch $branchDeleteName"
}

gitDeleteMergeBranches() {
    gitValidateRepo || errorExit
    local currentBranch=$(git rev-parse --abbrev-ref HEAD)
    git branch --merged | egrep -v "(^\*|master|main|dev)" | while read branch; do
        echo "${WARNING} Deleting merged branch: $branch"
        git branch -d "$branch" || echo "${ERROR} Failed to delete branch: $branch"
    done
    echo "${SUCCESS} Merged branches deleted (not master/main/dev and $currentBranch)"
}

#--- Tag ---#
gitTagCreate() {
    gitValidateRepo || errorExit
    git tag "$tagName" || { echo "$ERROR Failed to create tag $tagName"; errorExit; }
    echo "$SUCCESS Created tag: $tagName"
}

gitTagList() {
    gitValidateRepo || errorExit
    git tag
}

gitTagDelete() {
    gitValidateRepo || errorExit
    git tag -d "$tagDeleteName" || { echo "$ERROR Failed to delete tag $tagDeleteName"; errorExit; }
    echo "$SUCCESS Deleted tag: $tagDeleteName"
}

#--- Remote ---#
gitRemoteList() {
    gitValidateRepo || errorExit
    git remote -v
}

#--- Diff ---#
gitDiff() {
    gitValidateRepo || errorExit
    git diff
}