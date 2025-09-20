#--- Account ---#
gitrpstrySwitchAccount() { #gsc -A <username same as in .gsc.config>
    gitValidateUsername "$accountName" || errorExit  
    
    if [[ -n "${gitAccounts[$accountName]}" ]]; then
        if [ -d .git ]; then
            git config user.name "$accountName" || { echo "$ERROR Failed to set user name"; errorExit; }
            git config user.email "${gitAccounts[$accountName]}" || { echo "$ERROR Failed to set user email"; errorExit; }
        fi
        if [ $sshActivateFlag -eq 1 ]; then
            "${SHELL:-/bin/sh}" "$nowDir/sshsc" -r
            [[ -f $HOME/.ssh/id_ssh_${accountName} ]] && "${SHELL:-/bin/sh}" "$nowDir/sshsc" "${accountName}"
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

#--- Show Account ---#
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