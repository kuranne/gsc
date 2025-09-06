#!/bin/zsh

nowDir="$(cd -- "$(dirname -- "${(%):-%x}")" && pwd)"
hereDir="$(pwd)"

# origin variables
removeRepoFlag=0
initRepoFlag=0
switchAccountFlag=0
addFlag=0
commitFlag=0
pushFlag=0
gitignoreFlag=0
cloneFlag=0
gitNotFoundFlag=0
statusFlag=0
logFlag=0
showNowAccount=0
pullFromGit=0
varCreatedGscConfig=0
sshActivate=0

# parameter storage
accountName=""
cloneUrl=""
commitMessage=""

# import
if [ -f "${nowDir}/gsc.config" ]; then
    source "${nowDir}/gsc.config"
else
    RED='\033[0;31m'; PINK='\033[95m'
    GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    CYAN='\033[0;36m'; BLUE='\033[34m'
    NC='\033[0m'
    ERROR="${RED}ERROR:${NC}"; WARNING="${YELLOW}WARNING:${NC}"
    SUCCESS="${GREEN}SUCCESS:${NC}"; CHOICE="${BLUE}CHOICE:${NC}"
    USAGE="${BLUE}USAGE:${NC}"; HINT="${BLUE}HINT:${NC}"
    ANNOUNCE="${CYAN}ANNOUNCE:${NC}"; DETECTED="${CYAN}DETECTED:${NC}"
    typeset -A gitAccounts
    gitAccounts=(
        "blank" "blank@email.me"
    )
    gitIgnorePath="$HOME/.gitignore_global"
    echo "${WARNING} No gsc.config found in $nowDir"
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
# Automation
createGscConfig() {
    if [ $varCreatedGscConfig -eq 0 ]; then
        if [ -f "${hereDir}/.gsc.config" ]; then
            source "./.gsc.config"
        elif [ -f "${nowDir}/gsc.config" ]; then
            cp "${nowDir}/gsc.config" ./.gsc.config || errorExit
            source "./.gsc.config"
        else
            echo "${WARNING} Can't load gsc.config into this directory"
        fi
        varCreatedGscConfig=1
    fi
}

# option
while getopts "A:C:c:SIiaePpslu" opt; do
    case $opt in
        A) switchAccountFlag=1; accountName="$OPTARG" ;;
        C) cloneFlag=1; cloneUrl="$OPTARG" ;;
        c) commitFlag=1; commitMessage="$OPTARG" ;;
        S) sshActivate=1 ;;
        I) initRepoFlag=1 ;;
        i) gitignoreFlag=1 ;;
        a) addFlag=1 ;;
        P) pullFromGit=1 ;;
        p) pushFlag=1 ;;
        s) statusFlag=1;;
        l) logFlag=1 ;;
        u) showNowAccount=1 ;;
        \?) echo -e "$USAGE gsc is from git script
Options:
  -A <account>  Switch to account
  -C <url>      Clone repository  
  -c <message>  Commit with message
  -S            use SSH
  -I            Initialize repository
  -i            Create .gitignore
  -a            Add all files
  -P            Pull
  -p            Push to origin
  -s            Show status
  -l            Show log
  -u            Show now using account

Examples:
  gsc -AC user https://github.com/user/repo.git
  gsc -A user -acp 'Initial commit'
  gsc -Iacp 'First commit'">&2 ; errorExit ;;
    esac
done

shift $((OPTIND - 1)) # shift -

for arg in "$@"; do
    case $arg in
        remove) removeRepoFlag=1 ;;
        *) 
            if [[ $commitFlag -eq 1 && -z "$commitMessage" ]]; then
                commitMessage="$arg"
            fi
            ;;
    esac
done

# check git was installed
gitValidateNotFoundGit || errorExit

### MAIN FUNCTION ###

gitrpstryRemove() { #gsc remove
    gitValidateRepo || errorExit
    
    echo -ne "${YELLOW}WARNING:${NC} ${RED}¿Remove repo?${NC}(Y/y or Enter to confirm): ${NC}"
    read varRemoveAns
    if [[ "$varRemoveAns" == "Y" || "$varRemoveAns" == "y" || -z "$varRemoveAns" ]]; then
        [ -f .gitignore ] && rm .gitignore
        [ -d .git ] && rm -rf .git
        [ -f .gsc.config ] && rm .gsc.config
        echo -e "${RED}REMOVED${NC} :>"
        exit 0
    fi
    echo -e "\n${CYAN}CANCELLED${NC}"
    exit 0
}

gitrpstrySwitchAccount() { #gsc -A <username same as in .gsc.config>
    gitValidateUsername "$accountName" || errorExit
    createGscConfig
    
    if [[ -n "${gitAccounts[$accountName]}" ]]; then
        if [ -d .git ]; then
            git config user.name "$accountName" || { echo "$ERROR Failed to set user name"; errorExit; }
            git config user.email "${gitAccounts[$accountName]}" || { echo "$ERROR Failed to set user email"; errorExit; }
        fi
        if [ $sshActivate -eq 1 ]; then
            [[ -f $HOME/.ssh/id_ssh_${accountName} ]] && "${SHELL:-/bin/sh}" "$nowDir/sshsc.sh" "${accountName}"
            echo "$SUCCESS Switched to ssh account: $accountName"
        else
            echo "${HINT} If you want to use SSH key, must -S for SSH activate"
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
    createGscConfig
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
    createGscConfig
    
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
}

gitrpstryGitignore() {
    if [ -f .gitignore ]; then
        echo -e "$DETECTED .gitignore already exists, skipping..."
        return 0
    fi
    createGscConfig
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
    createGscConfig
    git add . || { echo "$ERROR Failed to add files"; errorExit; }
    echo "$SUCCESS Files added to staging"
}

gitrpstryCommit() {
    gitValidateRepo || errorExit
    createGscConfig

    if [ -z "$(git diff --cached --name-only)" ]; then
        git add . || { echo "$ERROR Failed to stage files"; errorExit; }
    fi

    gitValidateCommitMessage "$commitMessage" || errorExit
    
    git commit -m "$commitMessage" || { echo "$ERROR Failed to commit"; errorExit; }
    echo "$SUCCESS Committed with message: '$commitMessage'"
}

gitrpstryPush() {
    gitValidateRepo || errorExit
    createGscConfig

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

    git push "$varPush" "$varBranch" || { echo "$ERROR Failed to push to $varPush/$varBranch"; errorExit; }
    echo "$SUCCESS Pushed to $varPush/$varBranch"
}

gitStatus() {
    gitValidateRepo || errorExit
    git status
}

gitLog() {
    gitValidateRepo || errorExit
    git log --oneline --graph --decorate -n 10
}
gitPull() {
    gitValidateRepo || errorExit
    local varBranch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    local varPull=$(git config branch."$varBranch".remote 2>/dev/null || echo origin)
    git pull $varPull $varBranch
}

### END OF MAIN FUNCTION ###

# Starting

[[ $removeRepoFlag -eq 1 ]] && gitrpstryRemove
[[ $switchAccountFlag -eq 1 ]] && gitrpstrySwitchAccount
[[ $cloneFlag -eq 1 ]] && gitrpstryClone
[[ $initRepoFlag -eq 1 ]] && gitrpstryInit
[[ $gitignoreFlag -eq 1 ]] && gitrpstryGitignore
[[ $showNowAccount -eq 1 ]] && gitrpstryShowAccount
[[ $pullFromGit -eq 1 ]] && gitPull
[[ $addFlag -eq 1 ]] && gitrpstryAdd
[[ $statusFlag -eq 1 ]] && gitStatus
[[ $commitFlag -eq 1 ]] && gitrpstryCommit
[[ $pushFlag -eq 1 ]] && gitrpstryPush
[[ $logFlag -eq 1 ]] && gitLog

gscClear