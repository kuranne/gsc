gscClear() {
    [[ ! -d .git && -f .gsc.config ]] && rm .gsc.config
}

errorExit() {
    gscClear; exit 1
}