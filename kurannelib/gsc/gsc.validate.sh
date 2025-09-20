#--- Validation functions (Create by chatGPT)---#
gscClear() {
    [[ ! -d .git && -f .gsc.config ]] && rm .gsc.config
}

errorExit() {
    gscClear; exit 1
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

gscValidateBackup(){
    [[ -d "$backupDir" ]] || { echo "$ERROR .gscbackup don't found"; errorExit; }
}