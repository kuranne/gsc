#!/bin/zsh

local nowDir="$(cd -- "$(dirname -- "${(%):-%x}")" && pwd)"
local hereDir="$(pwd)"

for COREUTIL in "$nowDir/kurannelib/"core.*.sh; do
    source "$COREUTIL" || { echo "\033[0;31mERROR:\033[0m Can't load $COREUTIL"; exit 1 ; }
done
for PATHforgsc in "$nowDir/kurannelib/gsc/"gsc.*.sh; do
    source "$PATHforgsc" || { echo "\033[0;31mERROR:\033[0m Can't load $PATHforgsc"; exit 1 ; }
done

### origin variables ###
# utils
local gitNotFoundFlag=0 
# reset
local resetHardFlag=0
# account
local switchAccountFlag=0; local showNowAccountFlag=0; accountName=""
# ssh
local sshActivateFlag=0
# init and gitignore
local initRepoFlag=0; local gitignoreFlag=0
# clone
local cloneFlag=0; local cloneUrl=""
# add, commit and push
local addFlag=0; local commitFlag=0;local commitMessage=""; local pushFlag=0
# sync( pull, fetch )
local syncFlag=0
# pull
local pullFromGitFlag=0
# blame
local blameFile=""; local blameFlag=0
# log and status
local logFlag=0; local statusFlag=0
# branch
local branchCreateFlag=0; local branchName=""; local branchListFlag=0; local branchDeleteFlag=0; local branchDeleteName=""; local deleteMergeBranchFlag=0
# stash
local stashFlag=0; local stashMessage=""; local stashPopFlag=0
# tag
local tagCreateFlag=0; local tagName=""; local tagListFlag=0; local tagDeleteFlag=0; local tagDeleteName=""
# remote
local remoteListFlag=0; local remoteSetFlag=0; local remoteName=""; local remoteUrl=""
# diff
local diffFlag=0
# -h
local helpFlag=0

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
        \?) echo -e $HELPCOMMAND>&2 ; errorExit ;;
    esac
done

shift $((OPTIND - 1)) # shift -

for arg in "$@"; do
    case $arg in
        remove) gitrpstryRemove ;;
        reset) resetHardFlag=1 ;;
        restore) restoreAll ;;
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