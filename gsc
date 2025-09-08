#!/bin/zsh

nowDir="$(cd -- "$(dirname -- "${(%):-%x}")" && pwd)"
hereDir="$(pwd)"

#--- Import ---#
for COREUTIL in "$nowDir/kurannelib/"core.*.sh; do
    source "$COREUTIL" || { echo "\033[0;31mERROR:\033[0m Can't load $COREUTIL"; exit 1 ; }
done
for PATHforgsc in "$nowDir/kurannelib/gsc/"gsc.*.sh; do
    source "$PATHforgsc" || { echo "\033[0;31mERROR:\033[0m Can't load $PATHforgsc"; exit 1 ; }
done

#--- Origin Variables ---#

# utils
gitNotFoundFlag=0 
# reset
resetHardFlag=0
# account
switchAccountFlag=0
showNowAccountFlag=0
accountName=""
# ssh
sshActivateFlag=0
# init and gitignore
initRepoFlag=0
gitignoreFlag=0
# clone
cloneFlag=0
cloneUrl=""
# add, commit and push
addFlag=0
commitFlag=0
commitMessage=""
pushFlag=0
# sync( pull, fetch )
syncFlag=0
# pull
pullFromGitFlag=0
# blame
blameFile=""
blameFlag=0
# log and status
logFlag=0
statusFlag=0
# branch
branchCreateFlag=0 
branchName=""
branchListFlag=0
branchDeleteFlag=0
branchDeleteName="" 
deleteMergeBranchFlag=0
# stash
stashFlag=0
stashMessage=""
stashPopFlag=0
# tag
tagCreateFlag=0
tagName=""
tagListFlag=0
tagDeleteFlag=0
tagDeleteName=""
# remote
remoteListFlag=0
# diff
diffFlag=0
# -h
helpFlag=0

#--- Options ---#
while getopts "A:C:c:d:b:t:T:DSIiaPpsluMbRBh" opt; do
    case $opt in
        A) switchAccountFlag=1; accountName="$OPTARG" ;; ##
        C) cloneFlag=1; cloneUrl="$OPTARG" ;; ##
        c) commitFlag=1; commitMessage="$OPTARG" ;; ##
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
        b) branchCreateFlag=1; branchName="$OPTARG" ;; ##
        B) branchListFlag=1 ;;
        d) branchDeleteFlag=1; branchDeleteName="$OPTARG" ;; ##
        t) tagCreateFlag=1; tagName="$OPTARG" ;; ##
        T) tagDeleteFlag=1; tagDeleteName="$OPTARG" ;; ##
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

gitValidateNotFoundGit || errorExit # Check if git was installed
gsc_main # main
gscClear # clear .gsc.config