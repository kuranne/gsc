gitreset() {
    TheArgrument="${1}"
    if [[ "${TheArgrument}" == "Soft" ]]; then
        echo -n "${WARNING} Reset SOFT?[y/N]"
        if read -q; then
            echo
            git reset --soft HEAD~1 || { echo "${ERROR} failed to reset"; errorExit; }
        else 
            echo -e "\n$ANNOUNCE Cancelled."
        fi
    elif [[ "${TheArgrument}" == "Hard" ]]; then
        echo -n "${WARNING} Reset HARD?[y/N]: "
        if read -q; then
            echo
            git reset --hard HEAD~1 || { echo "${ERROR} reset failed"; errorExit; }        
            git clean -fd || { echo "${ERROR} clean failed"; errorExit; }
        else
            echo -e "\n$ANNOUNCE Cancelled."
        fi 
    fi
}

gitrename() {
    nametore="$1"
    git commit --amend -m "${nametore}" || { echo "$ERROR failed to recomment"; errorExit;}
    echo "$SUCCESS Finished to recomment."
}