gscUpdateConfig() {
    { [[ -f "$hereDir/.gsc.config" ]] && cp "$nowDir/kurannelib/gsc.config" "$hereDir/.gsc.config"; } || errorExit
    echo "$SUCCESS Update config Successful"
}

gscUpdateIgnore() {
    { [[ -f "$hereDir/.gitignore" ]] && cp "$gitIgnorePath" "$hereDir/.gitignore"; } || errorExit
    echo "$SUCCESS Update gitignore Successful"
}