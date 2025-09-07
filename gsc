#!/bin/zsh

nowDir="$(cd -- "$(dirname -- "${(%):-%x}")" && pwd)"
hereDir="$(pwd)"

[[ -f "${nowDir}/gsc.config" ]] || { echo "\033[0;31mERROR:\033[0m not found gsc.config in $nowDir"; exit 1 ; }

# origin variables
local initRepoFlag=0
local switchAccountFlag=0
local addFlag=0
local commitFlag=0
local pushFlag=0
local gitignoreFlag=0
local cloneFlag=0
local gitNotFoundFlag=0
local statusFlag=0
local logFlag=0
local showNowAccountFlag=0
local pullFromGitFlag=0
local sshActivateFlag=0
local resetHardFlag=0
local deleteMergeBranchFlag=0
local stashFlag=0
local stashMessage=""
local stashPopFlag=0
local branchCreateFlag=0
local branchName=""
local branchListFlag=0
local branchDeleteFlag=0
local branchDeleteName=""
local tagCreateFlag=0
local tagName=""
local tagListFlag=0
local tagDeleteFlag=0
local tagDeleteName=""
local remoteListFlag=0
local remoteSetFlag=0
local remoteName=""
local remoteUrl=""
local diffFlag=0
local blameFile=""
local blameFlag=0
local syncFlag=0
local helpFlag=0

# parameter storage
accountName=""
local cloneUrl=""
local commitMessage=""

# import
# Default
# Automation

if [ -f "${hereDir}/.gsc.config" ]; then
    source "${hereDir}/.gsc.config"
elif [ -f "${nowDir}/gsc.config" ]; then
    cp "${nowDir}/gsc.config" "${hereDir}/.gsc.config" || errorExit
    source "${hereDir}/.gsc.config"
else
    echo "${WARNING} Can't load gsc.config into this directory"
    RED='\033[0;31m'; PINK='\033[95m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BLUE='\033[34m'; NC='\033[0m'
    ERROR="${RED}ERROR:${NC}"; WARNING="${YELLOW}WARNING:${NC}"; SUCCESS="${GREEN}SUCCESS:${NC}"; CHOICE="${BLUE}CHOICE:${NC}"; USAGE="${BLUE}USAGE:${NC}"; HINT="${BLUE}HINT:${NC}"; ANNOUNCE="${CYAN}ANNOUNCE:${NC}"; DETECTED="${CYAN}DETECTED:${NC}"
fi

# Validation functions (code by chatGPT)
gscClear() {
    if [[ ! -d .git && -f .gsc.config ]]; then 
        rm .gsc.config 
    fi
}

errorExit() {
    gscClear
    exit 1
}

gitValidateURL() {
    local url="$1"
    [[ -n "$url" ]] || { echo "$ERROR URL cannot be empty"; errorExit; }
    echo "$url" | grep -Eq '^(https?|git|ssh)://|^git@.+:.+' || { echo "$ERROR Invalid Git URL format"; errorExit; }
}

gitValidateRepo() {
    [[ -d .git ]] || { echo "$ERROR No .git dir here"; errorExit; }
}

gitValidateUsername() {
    local accountName="$1"
    [[ -n "$accountName" ]] || { echo "$ERROR Account name cannot be empty"; errorExit; }
}

gitValidateCommitMessage() {
    local message="$1"
    [[ -n "$message" ]] || { echo "$ERROR Commit message cannot be empty"; errorExit; }
    [[ ${#message} -ge 3 ]] || { echo "$ERROR Commit message too short (minimum 3 characters)"; errorExit; }
}

gitValidateNotFoundGit() {
    command -v git >/dev/null 2>&1 || { echo "$ERROR Git is not installed"; errorExit; }
}

### MAIN FUNCTION BUT NOT OPTION ###
backupAll() {
    if [ ! -d "${HOME}/.gscbackup" ]; then
        mkdir "$HOME/.gscbackup" || errorExit
    fi
    mkdir "${HOME}/.gscbackup/$(date +%Y%m%d%H%M%S)" || { echo "${ERROR} Failed to backup"; errorExit; }
    cp -r "${hereDir}" "${HOME}/.gscbackup/$(date +%Y%m%d%H%M%S)" || { echo "${ERROR} Failed to backup"; errorExit; }
    echo "${SUCCESS} Backup!"
}

gitrpstryRestore() {
    local backupDir="$HOME/.gscbackup"
    if [ ! -d "$backupDir" ]; then
        echo "$ERROR No backup directory found at $backupDir"
        errorExit
    fi
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

# option
while getopts "A:C:c:SIiaPpsluMb:B:d:t:T:r:R:D:Bh" opt; do
    case $opt in
        A) switchAccountFlag=1; accountName="$OPTARG" ;;
        C) cloneFlag=1; cloneUrl="$OPTARG" ;;
        c) commitFlag=1; commitMessage="$OPTARG" ;;
        S) sshActivateFlag=1 ;;
        I) initRepoFlag=1 ;;
        i) gitignoreFlag=1 ;;
        a) addFlag=1 ;;
        P) pullFromGitFlag=1 ;;
        p) pushFlag=1 ;;
        s) statusFlag=1;;
        l) logFlag=1 ;;
        u) showNowAccountFlag=1 ;;
        M) deleteMergeBranchFlag=1 ;;
        b) branchCreateFlag=1; branchName="$OPTARG" ;;
        B) branchListFlag=1 ;;
        d) branchDeleteFlag=1; branchDeleteName="$OPTARG" ;;
        t) tagCreateFlag=1; tagName="$OPTARG" ;;
        T) tagDeleteFlag=1; tagDeleteName="$OPTARG" ;;
        r) remoteSetFlag=1; remoteName="$OPTARG"; remoteUrl="${!OPTIND}"; OPTIND=$((OPTIND+1)) ;;
        R) remoteListFlag=1 ;;
        D) diffFlag=1 ;;
        h) helpFlag=1 ;;
        \?) echo -e "$USAGE gsc is from git script
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
  -r <name> <url> Set remote
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
  gsc -SuA user -C git@github.com:user/repo.git -ac 'Initial commit' -psl">&2 ; errorExit ;;
    esac
done

shift $((OPTIND - 1)) # shift -

### END LINES ###

for arg in "$@"; do
    case $arg in
        remove) gitrpstryRemove ;;
        reset) resetHardFlag=1 ;;
        restore) gitrpstryRestore ;;
        stash) shift; stashFlag=1; stashMessage="$1";;
        stashpop) stashPopFlag=1 ;;
        blame) shift; blameFlag=1; blameFile="$1" ;;
        sync) syncFlag=1 ;;
        *) 
            if [[ $commitFlag -eq 1 && -z "$commitMessage" ]]; then
                commitMessage="$arg"
            fi
            ;;
    esac
done

# check git was installed
gitValidateNotFoundGit || errorExit

### MAIN FUNCTION FOR OPTION ###

gitrpstrySwitchAccount() { #gsc -A <username same as in .gsc.config>
    gitValidateUsername "$accountName" || errorExit  
    
    if [[ -n "${gitAccounts[$accountName]}" ]]; then
        if [ -d .git ]; then
            git config user.name "$accountName" || { echo "$ERROR Failed to set user name"; errorExit; }
            git config user.email "${gitAccounts[$accountName]}" || { echo "$ERROR Failed to set user email"; errorExit; }
        fi
        if [ $sshActivateFlag -eq 1 ]; then
            "${SHELL:-/bin/sh}" "$nowDir/sshsc.sh" -r
            [[ -f $HOME/.ssh/id_ssh_${accountName} ]] && "${SHELL:-/bin/sh}" "$nowDir/sshsc.sh" "${accountName}"
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

gitRemoteSet() {
    gitValidateRepo || errorExit
    git remote remove "$remoteName" >/dev/null 2>&1
    git remote add "$remoteName" "$remoteUrl" || { echo "$ERROR Failed to set remote"; errorExit; }
    echo "$SUCCESS Remote $remoteName set to $remoteUrl"
}

gitDiff() {
    gitValidateRepo || errorExit
    git diff
}

gitBlame() {
    gitValidateRepo || errorExit
    git blame "$blameFile" || { echo "$ERROR Failed to blame $blameFile"; errorExit; }
}

gitSync() {
    gitValidateRepo || errorExit
    git fetch --all --prune || { echo "$ERROR Failed to fetch"; errorExit; }
    git pull || { echo "$ERROR Failed to pull"; errorExit; }
    echo "$SUCCESS Synced with remote"
}

gscHelp() {
    echo -e "$USAGE gsc script options:
  -A <account>   Switch account
  -C <url>       Clone repository
  -c <msg>       Commit with message
  -S             Use SSH
  -I             Init repo
  -i             Create .gitignore
  -a             Add all
  -P             Pull
  -p             Push
  -s             Status
  -l             Log
  -u             Show account
  -M             Delete merged branches
  -b <name>      Create branch
  -B             List branches
  -d <name>      Delete branch
  -t <name>      Create tag
  -T <name>      Delete tag
  -R             List remotes
  -r <name> <url> Set remote
  -D             Show diff
  -h             Help
 Additional commands:
  stash <msg>    Save stash
  stashpop       Pop stash
  blame <file>   Git blame
  sync           Fetch+pull+prune
  remove         Remove repo
  reset          Hard reset
  restore        Restore from backup
"
}

### END OF MAIN FUNCTION ###

# Starting

[[ $removeRepoFlag -eq 1 ]] && gitrpstryRemove
[[ $switchAccountFlag -eq 1 ]] && gitrpstrySwitchAccount
[[ $cloneFlag -eq 1 ]] && gitrpstryClone
[[ $initRepoFlag -eq 1 ]] && gitrpstryInit
[[ $gitignoreFlag -eq 1 ]] && gitrpstryGitignore
[[ $showNowAccountFlag -eq 1 ]] && gitrpstryShowAccount
[[ $pullFromGitFlag -eq 1 ]] && gitPull
[[ $resetHardFlag -eq 1 ]] && gitrpstryResetHard
[[ $addFlag -eq 1 ]] && gitrpstryAdd
[[ $statusFlag -eq 1 ]] && gitStatus
[[ $commitFlag -eq 1 ]] && gitrpstryCommit
[[ $pushFlag -eq 1 ]] && gitrpstryPush
[[ $logFlag -eq 1 ]] && gitLog
[[ $deleteMergeBranchFlag -eq 1 ]] && gitDeleteMergeBranches
[[ $stashFlag -eq 1 ]] && gitStashSave "$stashMessage"
[[ $stashPopFlag -eq 1 ]] && gitStashPop
[[ $branchCreateFlag -eq 1 ]] && gitBranchCreate
[[ $branchListFlag -eq 1 ]] && gitBranchList
[[ $branchDeleteFlag -eq 1 ]] && gitBranchDelete
[[ $tagCreateFlag -eq 1 ]] && gitTagCreate
[[ $tagListFlag -eq 1 ]] && gitTagList
[[ $tagDeleteFlag -eq 1 ]] && gitTagDelete
[[ $remoteListFlag -eq 1 ]] && gitRemoteList
[[ $remoteSetFlag -eq 1 ]] && gitRemoteSet
[[ $diffFlag -eq 1 ]] && gitDiff
[[ $blameFlag -eq 1 ]] && gitBlame
[[ $syncFlag -eq 1 ]] && gitSync
[[ $helpFlag -eq 1 ]] && gscHelp

gscClear