#--- Start Function ---#

main() {
    if [[ "$1" != -* && -n "$1" ]]; then
        local cmd="$1"
        shift
        if typeset -f "$cmd" >/dev/null; then
            "$cmd" "$@"
            normalExit
            return
        fi
    fi
    gitOperation "$@"
}