#!/bin/zsh

nowDir="$(cd -- "$(dirname -- "${(%):-%x}")" && pwd)"

removeSsh=0
createSsh=0

if [[ -f ".gsc.config" ]]; then
    source ".gsc.config"
else
    echo "$ERROR from sshsc.sh SAY: .gsc.config not found."
    exit 1
fi

selectedAccounts=()

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
            exit 0
        fi
        createSshKey
    fi
done