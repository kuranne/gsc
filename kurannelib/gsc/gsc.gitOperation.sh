#--- Blame ---#
gitBlame() {
    gitValidateRepo || errorExit
    git blame "$blameFile" || { echo "$ERROR Failed to blame $blameFile"; errorExit; }
}

#--- Clone ---#
gitrpstryClone() {
    gitValidateURL "$gitCloneUrl" || errorExit
    local varRepoName=$(basename "$gitCloneUrl" .git)
    [[ -d "$varRepoName" ]] && { echo "$ERROR Directory $varRepoName already exists"; errorExit; }
    git clone "${gitCloneUrl}" || { echo "$ERROR Failed to clone repository"; errorExit; }
    cd "$varRepoName" || { echo "$ERROR Failed to enter cloned directory"; errorExit; }
    echo "$SUCCESS Cloned directory: ${PINK}$varRepoName${NC}"
    
    if [ $yesSkip -eq 0 ]; then
        echo -n "$CHOICE pull?[y/N]: "
        if read -q; then
            echo
            gitPull || { echo "${WARNING} Failed to pull $varRepoName"; }
        fi
    fi
}

#--- Init ---#
gitrpstryInit() {
    if [ -d .git ]; then
        echo -e "${DETECTED} Already initialized"
        return 0
    fi
    git init >/dev/null || { echo "$ERROR Failed to initialize repository"; errorExit; }
    echo -e "${GREEN}Alright! ${NC}Init Successful"
    # if we just switched account, configure it for this repo
    if [ -n "$currentAccount" ] && [ -n "${gitAccounts[$currentAccount]}" ]; then
        git config user.name "$currentAccount" || echo -e "${YELLOW}WARNING: Failed to set user name${NC}"
        git config user.email "${gitAccounts[$currentAccount]}" || echo -e "${YELLOW}WARNING: Failed to set user email${NC}"
    fi
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

    if [[ ! $gitPullFlag -eq 1 && $yesSkip -eq 0 ]]; then
        echo -n "${WARNING} Want to pull before push?[y/N]: "
        if read -q ;then
            echo
            git pull "$varPush" "$varBranch" || { echo "$ERROR Failed to pull from $varPush"; errorExit; }
        fi
        git push "$varPush" "$varBranch" || { echo "$ERROR Failed to push to $varPush/$varBranch"; errorExit; }
    fi

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

#--- Diff ---#
gitDiff() {
    gitValidateRepo || errorExit
    git diff
}

#--- gitignore ---#
gitrpstryGitignore() {
    if [ -f .gitignore ]; then
        echo -e "$DETECTED .gitignore already exists, skipping..."
        return 0
    fi
    if [ -n "$gitIgnorePath" ] && [ -f "$gitIgnorePath" ]; then
        cat "$gitIgnorePath" >> .gitignore || { echo "$ERROR Failed to copy .gitignore template"; errorExit; }
        [[ $(grep -c .gsc.config .gitignore) -eq 0 ]] && echo -e "\n# gsc Script\n.gsc.config" >> .gitignore
    else
        echo -e "$ANNOUNCE Template not found, creating basic .gitignore"
        cat > .gitignore << 'EOF'

#--- System ---#
# OSX
.DS_STORE
# NT
Thumbs.db

#--- tool ---#
.vscode/
.git/
.gitignore
.gsc.config

#--- executeable ---#
*.exe
*.app
*.out

EOF
    fi
    echo -e "${SUCCESS} .gitignore created successfully"
}