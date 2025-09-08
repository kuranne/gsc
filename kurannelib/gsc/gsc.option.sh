gitrpstrySwitchAccount() { #gsc -A <username same as in .gsc.config>
    gitValidateUsername "$accountName" || errorExit  
    
    if [[ -n "${gitAccounts[$accountName]}" ]]; then
        if [ -d .git ]; then
            git config user.name "$accountName" || { echo "$ERROR Failed to set user name"; errorExit; }
            git config user.email "${gitAccounts[$accountName]}" || { echo "$ERROR Failed to set user email"; errorExit; }
        fi
        if [ $sshActivateFlag -eq 1 ]; then
            "${SHELL:-/bin/sh}" "$nowDir/sshsc" -r
            [[ -f $HOME/.ssh/id_ssh_${accountName} ]] && "${SHELL:-/bin/sh}" "$nowDir/sshsc" "${accountName}"
            echo "$SUCCESS Switched to ssh account: $accountName"
        else
            echo "${HINT} If you want to use  key, must -S for SSH activate"
            echo "$SUCCESS Switched to non-ssh account: $accountName"
        fi
        currentAccount="$accountName"
    else
        echo "$ERROR Unknown account: $accountName"
        echo "$HINT Available accounts: ${(k)gitAccounts}"
        errorExit
    fi
}

gitrpstryClone() { #gsc -C <git repository url or ssh>
    gitValidateURL "$cloneUrl" || errorExit
    
    local varRepoName=$(basename "$cloneUrl" .git)
    [[ -d "$varRepoName" ]] && { echo "$ERROR Directory $varRepoName already exists"; errorExit; }
    
    git clone "${cloneUrl}" || { echo "$ERROR Failed to clone repository"; errorExit; }
    cd "$varRepoName" || { echo "$ERROR Failed to enter cloned directory"; errorExit; }
    
    echo "$SUCCESS Cloned directory: ${PINK}$varRepoName${NC}"
    gitPull || { echo "${WARNING} Failed to pull $varRepoName" }
}

gitrpstryInit() {
    if [ -d .git ]; then
        echo -e "${YELLOW}NOTICE: ${NC}Already initialized"
        return 0
    fi
    
    git init || { echo "$ERROR Failed to initialize repository"; errorExit; }
    echo -e "${GREEN}Alright! ${NC}Init Successful"
    
    
    # if we just switched account, configure it for this repo
    if [ -n "$currentAccount" ] && [ -n "${gitAccounts[$currentAccount]}" ]; then
        git config user.name "$currentAccount" || echo -e "${YELLOW}WARNING: Failed to set user name${NC}"
        git config user.email "${gitAccounts[$currentAccount]}" || echo -e "${YELLOW}WARNING: Failed to set user email${NC}"
    fi
}

gitrpstryShowAccount() {
    local userName=$(git config user.name 2>/dev/null)
    local userEmail=$(git config user.email 2>/dev/null)
    
    if [[ -n "$userName" && -n "$userEmail" ]]; then
        echo -e "${CYAN}Now using account: ${NC}$userName <$userEmail>"
    elif [ $cloneFlag -eq 1 ]; then
        echo -e "$SUCCESS don't forgot to cd into your clone directory!"
    else
        echo -e "$WARNING user.name and user.email didn't configured yet"
    fi

    if [ $sshActivateFlag -eq 1 ]; then
        echo -e "${CYAN}SSH Agent keys loaded:${NC}"
        if ssh-add -l >/dev/null 2>&1; then
            ssh-add -l | while read -r line; do
                echo "  $line"
            done

            if [[ -n "$currentAccount" && -f "$HOME/.ssh/id_ssh_${currentAccount}" ]]; then
                ssh-keygen -lf "$HOME/.ssh/id_ssh_${currentAccount}.pub" 2>/dev/null
            fi
        else
            echo "No SSH keys loaded in agent"
        fi
    fi
}

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

gitrpstryAdd() {
    gitValidateRepo || errorExit
    
    git add . || { echo "$ERROR Failed to add files"; errorExit; }
    echo "$SUCCESS Files added to staging"
}

gitrpstryCommit() {
    gitValidateRepo || errorExit
    

    if [ -z "$(git diff --cached --name-only)" ]; then
        git add . || { echo "$ERROR Failed to stage files"; errorExit; }
    fi

    gitValidateCommitMessage "$commitMessage" || errorExit
    
    git commit -m "$commitMessage" || { echo "$ERROR Failed to commit"; errorExit; }
    echo "$SUCCESS Committed with message: '$commitMessage'"
}

gitPull() {
    gitValidateRepo || errorExit
    local varBranch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    local varPull=$(git config branch."$varBranch".remote 2>/dev/null || echo origin)
    git pull $varPull $varBranch
}

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
    echo "${WARNING} Want to pull before push?(Y/y) or Enter to confirm: "
    read varPushPullAns
    if [[ "$varPushPullAns" == "Y" || "$varPushPullAns" == "y" || -z "$varPushPullAns" ]];then
        git pull "$varPush" || { echo "$ERROR Failed to pull from $varPush"; errorExit; }
    fi
    git push "$varPush" "$varBranch" || { echo "$ERROR Failed to push to $varPush/$varBranch"; errorExit; }
    echo "$SUCCESS Pushed to $varPush/$varBranch"
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

gitStatus() {
    gitValidateRepo || errorExit
    git status
}

gitLog() {
    gitValidateRepo || errorExit
    git log --oneline --graph --decorate -n 10
}

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

gitRemoteList() {
    gitValidateRepo || errorExit
    git remote -v
}

gitDiff() {
    gitValidateRepo || errorExit
    git diff
}

gscHelp() {
    echo -e $HELPCOMMAND
}

### END OF MAIN FUNCTION ###

HELPCOMMAND="$USAGE gsc is from git script
Options:
  -A <account>  Switch to account
  -S           use SSH to authorize
  -C <url>      Clone repository  
  -I            Initialize repository
  -i            Create .gitignore
  -a            Add all files
  -c <message>  Commit with message
  -P            Pull
  -p            Push to origin
  -M            Delete merged branches except master/main/dev
  -B            List branches
  -b <name>     Create branch
  -d <name>     Delete branch
  -t <name>     Create tag
  -T <name>     Delete tag
  -R            List remotes
  -D            Show diff
  -l            Show log
  -s            Show status
  -u            Show now using account
  -h            Help

Additional commands:
  stash <msg>    Save stash
  stashpop       Pop stash
  blame <file>   Git blame
  sync           Fetch+pull+prune
  remove         remove .git and .gitignore
  reset         Hard reset

Examples:
  gsc -SA user -C https://github.com/user/repo.git
  gsc -A user -ac 'Initial commit' -p
  gsc -Iac 'First commit' -p 
  gsc -SuA user -C git@github.com:user/repo.git -ac 'Initial commit' -psl"
