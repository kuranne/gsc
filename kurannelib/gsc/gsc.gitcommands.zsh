#--- Re-Something ---#
re() {
    source "$nowDir/kurannelib/gsc/gsc.re.sh" || { echo "$ERROR Failed to source gsc.re.sh"; errorExit; }
    gitValidateRepo || errorExit

    if [ $# -gt 0 ]; then
        while getopts "n:HS" opt; do
            case $opt in
                n) gitrename "$OPTARG";;
                H) gitreset "Hard";;
                S) gitreset "Soft";;
                \?) echo "
$ERROR Unknow argrument $opt, use
-n <commit message>         to rename the last commit
-H                          to reset hard
-S                          to reset soft";;
            esac
            break
        done
    else
        echo "$ANNOUNCE gsc re need only 1 opt."
    fi
}

#--- Sync ---#
sync() {
    gitValidateRepo || errorExit
    git fetch --all --prune || { echo "$ERROR Failed to fetch"; errorExit; }
    echo -n "$CHOICE Do you want to pull now?[y/N]: "
    if read -q; then
        gitPull || { echo "$ERROR Failed to pull"; errorExit; }
        echo "$SUCCESS Synced with remote"
    fi
}

#--- Stash ---#
stash() {
    source "${nowDir}/kurannelib/gsc/gsc.gitStash.sh" || { echo "$ERROR Failed to source gsc.gitStash.sh"; errorExit; }
    if [ $# -gt 0 ]; then
        while getopts "s:p" opt; do
            case $opt in
                s) gitStashSave "$OPTARG";;
                p) gitStashPop;;
                \?) echo -e "
$ERROR Unknow option, use
s <message>     stash push
p               stash pop

Usecase
gsc stash -s 'message'
"; errorExit;;
            esac
        done
    else
        stashchoice=("Push" "Pop")
        echo "$CHOICE select option to stash"
        select answer in $stashchoice[@]; do
            [ -n "$answer" ] && break
        done
        if [[ "$answer" == "Push" ]]; then
            echo -n "$ANNOUNCE Type message(s): "
            read pushmessage
            echo
            gitStashSave "$pushmessage" || errorExit
        else
            gitStashPop || errorExit
        fi
    fi
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

gitOperation() {
    source "${nowDir}/kurannelib/gsc/gsc.gitOperation.sh" || {echo "$ERROR Failed to source gsc.gitOperation.sh"; errorExit;}
    if [ $# -gt 0 ]; then
        accountFlag=0; accountName=""; sshActivateFlag=0
        currentAccountFlag=0
        local gitCloneFlag=0; local gitCloneUrl=""
        local gitInitFlag=0
        local gitPullFlag=0; local gitAddFlag=0; local gitCommitFlag=0; commitMessage=""; local gitPushFlag=0
        local gitLogFlag=0; local gitDiffFlag=0; local gitBlameFlag=0

        while getopts "C:A:c:SIPaipsldbu" opt; do
            case $opt in
                C) gitCloneFlag=1; gitCloneUrl="$OPTARG";;
                A) accountFlag=1; accountName="$OPTARG";;
                S) sshActivateFlag=1 ;;
                I) gitInitFlag=1 ;;
                P) gitPullFlag=1 ;;
                a) gitAddFlag=1 ;;
                c) gitCommitFlag=1; commitMessage="$OPTARG" ;;
                i) gitIgnoreFlag=1;;
                p) gitPushFlag=1 ;;
                s) gitStatusFlag=1 ;;
                l) gitLogFlag=1 ;;
                d) gitDiffFlag=1 ;;
                b) gitBlameFlag=1 ;;
                u) currentAccountFlag=1 ;;
                \?) echo -e "
$ERROR Unknow option, use
-C <url>        clone repository to $hereDir
-A <username>   assign username and password in gsc.config to git config
-S              use ssh
-I              git init
-i              copy gitignore to $hereDir
-a              git add
-c <message>    git commit -m 'message'
-p              git push
-P              git pull
-s              git status
-l              git log
-d              git diff
-b              git blame
-u              check current username

Usecase
gsc -SA username -Iiac message -psldb
gsc -SA username -C url
"; errorExit;;
            esac
        done

        [[ $accountFlag -eq 1 ]] && gitrpstrySwitchAccount
        [[ $currentAccountFlag -eq 1 ]] && gitrpstryShowAccount
        [[ $gitCloneFlag -eq 1 ]] && gitrpstryClone
        [[ $gitInitFlag -eq 1 ]] && gitrpstryInit
        [[ $gitIgnoreFlag -eq 1 ]] && gitrpstryGitignore
        [[ $gitPullFlag -eq 1 ]] && gitPull
        [[ $gitAddFlag -eq 1 ]] && gitrpstryAdd
        [[ $gitCommitFlag -eq 1 ]] && gitrpstryCommit
        [[ $gitPushFlag -eq 1 ]] && gitrpstryPush
        [[ $gitStatusFlag -eq 1 ]] && gitStatus
        [[ $gitLogFlag -eq 1 ]] && gitLog
        [[ $gitDiffFlag -eq 1 ]] && gitDiff
        [[ $gitBlameFlag -eq 1 ]] && gitBlame
    else
        echo "Hello! from gsc."
    fi

}

#--- Branch ---#
branch() {
    source "${nowDir}/kurannelib/gsc/gsc.gitBranch.sh" || { echo "$ERROR Failed to source gsc.gitBranch.sh"; errorExit; }
    gitValidateRepo || errorExit
    if [ $# -gt 0 ]; then
        while getopts "c:d:Dlm" opt; do
            case $opt in
                c) branchName="$OPTARG"; gitBranchCreate;;
                d) branchDeleteName="$OPTARG"; gitBranchDelete;;
                D) gitDeleteMergeBranches;;
                l) gitBranchList;;
                m) gitMergeBranch;;
                \?) echo -e "
$ERROR Unknow option, use
-c <branch name>     create branch with name
-d <branch name>     delete branch with name
-D                   delete all merged branch
-l                   list all branch
-m                   merge a branch

Usecase
gsc branch -c main

"; errorExit;;
            esac
        done
    else
        gitBranchList
    fi
}

#--- Tag ---#
tag(){
    source "${nowDir}/kurannelib/gsc/gsc.gitTag.sh" || { echo "$ERROR Failed to source gsc.gitTag.sh"; errorExit;}
    if [ $# -gt 0 ]; then
        while getopts "c:d:l" opt; do
            case $opt in
                c) tagName="$OPTARG"; gitTagCreate;;
                d) tagDeleteName="$OPTARG"; gitTagDelete;;
                l) gitTagList;;
                \?) echo -e "
$ERROR Unknow option, use
-c <name>       create tag with name
-d <name>       delete tag with name
-l              list tag
"; errorExit;;
            esac
        done
    else
        gitTagList
    fi
}
