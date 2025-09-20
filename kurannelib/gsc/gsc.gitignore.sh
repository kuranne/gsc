#--- gitignore ---#
gitrpstryGitignore() {
    if [ -f .gitignore ]; then
        echo -e "$DETECTED .gitignore already exists, skipping..."
        return 0
    fi
    
    if [ -n "$gitIgnorePath" ] && [ -f "$gitIgnorePath" ]; then
        cat "$gitIgnorePath" >> .gitignore || { echo "$ERROR Failed to copy .gitignore template"; errorExit; }
        echo -e "\n# gsc Script\n.gsc.config" >> .gitignore
    else
        echo -e "$ANNOUNCE Template not found, creating basic .gitignore"
        cat > .gitignore << 'EOF'

#--- System ---#
# OSX
.DS_STORE
# NT
Thumbs.db

#--- tool ---#
.vscode/
.git/
.gitignore
.gsc.config

#--- executeable ---#
*.exe
*.app
*.out

EOF
    fi
    echo -e "${SUCCESS} .gitignore created successfully"
}