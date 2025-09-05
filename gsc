#!/bin/zsh

nowDir="$(cd -- "$(dirname -- "${(%):-%x}")" && pwd)"
hereDir="$(pwd)"

# import
if [[ -f ".gsc.config" ]]; then
    source ".gsc.config"
else
    echo "\033[0;36mANNOUNCE:\033[0m .gsc.config not found, creating default"
    if [[ -f "${nowDir}/gsc.config" ]]; then
        cp "${nowDir}/gsc.config" "${hereDir}/.gsc.config"
    else
        echo "\033[0;31mERROR:\033[0m gsc.config not found in $nowDir"
        exit 1
    fi
    source ".gsc.config"
fi

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

# parameter storage
accountName=""
cloneUrl=""
commitMessage=""

# Validation functions (code by chatGPT)
gitValidateURL() {
    local url="$1"
    [[ -n "$url" ]] || { echo "$ERROR URL cannot be empty"; return 1; }
    echo "$url" | grep -Eq '^(https?|git|ssh)://|^git@.+:.+' || { echo "$ERROR Invalid Git URL format"; return 1; }
}

gitValidateRepo() {
    [[ -d .git ]] || { echo "$ERROR No .git dir here"; return 1; }
}

gitValidateUsername() {
    local accountName="$1"
    [[ -n "$accountName" ]] || { echo "$ERROR Account name cannot be empty"; return 1; }
}

gitValidateCommitMessage() {
    local message="$1"
    [[ -n "$message" ]] || { echo "$ERROR Commit message cannot be empty"; return 1; }
    [[ ${#message} -ge 3 ]] || { echo "$ERROR Commit message too short (minimum 3 characters)"; return 1; }
}

gitValidateNotFoundGit() {
    command -v git >/dev/null 2>&1 || { echo "$ERROR Git is not installed"; return 1; }
}

# option
while getopts "A:C:c:IiaePpslu" opt; do
    case $opt in
        A) switchAccountFlag=1; accountName="$OPTARG" ;;
        C) cloneFlag=1; cloneUrl="$OPTARG" ;;
        c) commitFlag=1; commitMessage="$OPTARG" ;;
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
  gsc -Iacp 'First commit'">&2 ; exit 1 ;;
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
gitValidateNotFoundGit || exit 1

### MAIN FUNCTION ###

gitrpstryRemove() { #gsc remove
    gitValidateRepo || return 1
    
    echo -ne "${YELLOW}WARNING:${NC} ${RED}¿Remove repo?${NC} (Enter to continue, C to cancel): ${NC}"
    read -k 1 varRemoveAns
    if [[ "$varRemoveAns" == "C" || "$varRemoveAns" == "c" ]]; then
        echo -e "\n${CYAN}CANCELLED${NC}"
        exit 0
    fi
    rm -rf .git .gsc.config
    echo -e "${RED}REMOVED${NC} :>"
    [ -f .gitignore ] && rm .gitignore
    exit 0
}

gitrpstrySwitchAccount() { #gsc -A <username same as in .gsc.config>
    gitValidateUsername "$accountName" || return 1
    
    if [[ -n "${gitAccounts[$accountName]}" ]]; then
        if [ -d .git ]; then
            git config user.name "$accountName" || { echo "$ERROR Failed to set user name"; return 1; }
            git config user.email "${gitAccounts[$accountName]}" || { echo "$ERROR Failed to set user email"; return 1; }
        fi
        [[ -f $HOME/.ssh/id_ssh_${accountName} ]] && "${SHELL:-/bin/sh}" "$nowDir/sshsc.sh" "${accountName}"
        currentAccount="$accountName"
        echo "$SUCCESS Switched to account: $accountName"
    else
        echo "$ERROR Unknown account: $accountName"
        echo "$HINT Available accounts: ${(k)gitAccounts}"
        return 1
    fi
}

gitrpstryClone() { #gsc -C <git repository url or ssh>
    gitValidateURL "$cloneUrl" || return 1
    
    local varRepoName=$(basename "$cloneUrl" .git)
    [[ -d "$varRepoName" ]] && { echo "$ERROR Directory $varRepoName already exists"; return 1; }
    
    git clone "${cloneUrl}" || { echo "$ERROR Failed to clone repository"; return 1; }
    cd "$varRepoName" || { echo "$ERROR Failed to enter cloned directory"; return 1; }
    echo "$SUCCESS Cloned and entered directory: $varRepoName"
}

gitrpstryInit() {
    if [ -d .git ]; then
        echo -e "${YELLOW}NOTICE: ${NC}Already initialized"
        return 0
    fi
    
    git init || { echo "$ERROR Failed to initialize repository"; return 1; }
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
}

gitrpstryGitignore() {
    if [ -f .gitignore ]; then
        echo -e "$DETECTED .gitignore already exists, skipping..."
        return 0
    fi
    
    if [ -n "$gitIgnorePath" ] && [ -f "$gitIgnorePath" ]; then
        cat "$gitIgnorePath" >> .gitignore || { echo "$ERROR Failed to copy .gitignore template"; return 1; }
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
    gitValidateRepo || return 1
    git add . || { echo "$ERROR Failed to add files"; return 1; }
    echo "$SUCCESS Files added to staging"
}

gitrpstryCommit() {
    gitValidateRepo || return 1
    
    if [ -z "$(git diff --cached --name-only)" ]; then
        git add . || { echo "$ERROR Failed to stage files"; return 1; }
    fi

    gitValidateCommitMessage "$commitMessage" || return 1
    
    git commit -m "$commitMessage" || { echo "$ERROR Failed to commit"; return 1; }
    echo "$SUCCESS Committed with message: '$commitMessage'"
}

gitrpstryPush() {
    gitValidateRepo || return 1
    
    if ! git remote; then
        echo "$ERROR No remote found. Add remote first with: git remote add <remote> <url>"
        return 1
    fi
    local varBranch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    local varPush=$(git config branch."$varBranch".remote 2>/dev/null || echo origin)    
    [[ -n "$varBranch" ]] || { echo "$ERROR Failed to get current branch"; return 1; }
    
    git push "$varPush" "$varBranch" || { echo "$ERROR Failed to push to $varPush/$varBranch"; return 1; }
    echo "$SUCCESS Pushed to $varPush/$varBranch"
}

gitStatus() {
    gitValidateRepo || return 1
    git status
}

gitLog() {
    gitValidateRepo || return 1
    git log --oneline --graph --decorate -n 10
}
gitPull() {
    gitValidateRepo || return 1
    local varBranch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    local varPull=$(git config branch."$varBranch".remote 2>/dev/null || echo origin)
    git pull $varPull $varBranch
}
gscAutoManagement() {
    if [ -d .git ]; then
        exit 0
    else
        if [ -f .gsc.config ]; then
            rm .gsc.config
            exit 0
        fi
    fi
}

### END OF MAIN FUNCTION ###

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

gscAutoManagement