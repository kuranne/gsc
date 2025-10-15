gscUpdateConfig() {
    { [[ -f "$hereDir/.gsc.config" ]] && cp "$nowDir/kurannelib/gsc.config" "$hereDir/.gsc.config"; } || errorExit
    echo "$SUCCESS Update config Successful"
}

gscUpdateIgnore() {
    gscConfigIgnoreDetected=0
    
    if [[ $(grep -c .gsc.config "$hereDir/.gitignore" ) -gt 0 && $(grep -c .gsc.config "$gitIgnorePath") -eq 0 ]]; then
        gscConfigIgnoreDetected=1
    fi
    
    { [[ -f "$hereDir/.gitignore" ]] && cp "$gitIgnorePath" "$hereDir/.gitignore"; } || errorExit
    [[ $gscConfigIgnoreDetected -eq 1 ]] && echo -e "\n# gsc Script\n.gsc.config" >> "$hereDir/.gitignore"
    echo "$SUCCESS Update gitignore Successful"
}