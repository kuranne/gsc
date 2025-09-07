#!/bin/zsh

local nowDir="$(cd -- "$(dirname -- "${(%):-%x}")" && pwd)"
local hereDir="$(pwd)"


local removeSsh=0
local createSsh=0

local selectedAccounts=()

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

gscClear() {
    if [[ ! -d .git && -f .gsc.config ]]; then 
        rm .gsc.config 
    fi
}

while getopts "rC" opt; do
    case $opt in
        r) removeSsh=1 ;;
        C) createSsh=1 ;;
        \?) echo "$USAGE ssc [-r|-C] [accountName...]" >&2; exit 1 ;;
    esac
done

shift $((OPTIND - 1))

for arg in "$@"; do
    if [[ -n "${gitAccounts[$arg]}" ]]; then
        selectedAccounts+=("$arg")
    else
        echo "$WARNING ${arg} is not a valid account!" >&2
    fi
done

# remove ssh keys
removeSshKey() {
    if [[ ${#selectedAccounts[@]} -eq 0 ]]; then

        # no specific accounts given, remove all keys matching gitAccounts

        for acct in "${(@k)gitAccounts}"; do
            if ssh-add -l | grep -q "${gitAccounts[$acct]}"; then
                ssh-add -d $HOME/.ssh/id_ssh_${acct} > /dev/null 2>&1
            fi
        done

    else
        for acct in "${selectedAccounts[@]}"; do
            if ssh-add -l | grep -q "${gitAccounts[$acct]}"; then
                ssh-add -d $HOME/.ssh/id_ssh_${acct} > /dev/null 2>&1
                echo "$SUCCESS Removed SSH key for $acct"
            fi
        done

    fi
}

# create ssh keys
createSshKey() {
    for acct in "${selectedAccounts[@]}"; do
        ssh-keygen -t rsa -b 4096 -C "${gitAccounts[$acct]}" -f $HOME/.ssh/id_ssh_${acct}
        cat $HOME/.ssh/id_ssh_${acct}.pub
    done
}

[[ $removeSsh -eq 1 ]] && removeSshKey
[[ $createSsh -eq 1 ]] && createSshKey

# add ssh keys
for acct in "${selectedAccounts[@]}"; do
    if [ -f $HOME/.ssh/id_ssh_${acct} ]; then
        ssh-add ~/.ssh/id_ssh_${acct} > /dev/null 2>&1
    else
        echo "${YELLOW}WARNING: ${NC}Can't find id_ssh_${acct} on your ~/.ssh do u want to create new one?"
        echo "${RED}CHOICE: ${NC}Enter for Yes, C for No: "
        read -k 1 createSshKeyAns
        if [[ "$createSshKeyAns" == "N" || "$createSshKeyAns" == "n" ]]; then
            echo "Did't do anything."
            gscClear
            exit 0
        fi
        createSshKey
    fi
done
gscClear