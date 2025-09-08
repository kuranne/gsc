#--- Start Function ---#
gsc_main(){
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
    [[ $diffFlag -eq 1 ]] && gitDiff
    [[ $blameFlag -eq 1 ]] && gitBlame
    [[ $syncFlag -eq 1 ]] && gitSync
    [[ $helpFlag -eq 1 ]] && gscHelp
}