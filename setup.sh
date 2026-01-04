#!/usr/bin/env bash

# Configuration
REPO_URL="https://github.com/kuranne/gsc.git"
INSTALL_DIR="$HOME/.local/share/gsc"
BACKUP_DIR="$INSTALL_DIR/backup"
BIN_DIR="$HOME/bin"
VENV_DIR="$INSTALL_DIR/.venv"

echo "Installing GSC..."

# 1. Setup Directories
mkdir -p "$BACKUP_DIR"
mkdir -p "$BIN_DIR"

# 2. Clone or Update Repository
if [ -d "$INSTALL_DIR/.git" ]; then
    echo "Updating existing repository at $INSTALL_DIR..."
    git -C "$INSTALL_DIR" pull || { echo "Failed to pull repository"; exit 1; }
else
    echo "Cloning repository to $INSTALL_DIR..."
    # Remove dir if it exists but not a git repo to avoid errors?
    if [ -d "$INSTALL_DIR" ]; then
        echo "Directory $INSTALL_DIR exists but is not a git repo. Backing up..."
        mv "$INSTALL_DIR" "${INSTALL_DIR}.bak.$(date +%s)"
    fi
    git clone "$REPO_URL" "$INSTALL_DIR" || { echo "Failed to clone repository"; exit 1; }
fi

# 3. Create Virtual Environment
echo "Setting up Python virtual environment..."
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR" || { echo "Failed to create venv"; exit 1; }
fi

# 4. Install Dependencies
echo "Installing dependencies..."
# Upgrade pip first?
"$VENV_DIR/bin/pip" install --upgrade pip > /dev/null
if [ -f "$INSTALL_DIR/source/requirements.txt" ]; then
    "$VENV_DIR/bin/pip" install -r "$INSTALL_DIR/source/requirements.txt" || { echo "Failed to install requirements"; exit 1; }
else
    echo "Warning: requirements.txt not found in $INSTALL_DIR/source"
fi

# 5. Compile/Create Executables
# We create shell wrappers to run the python scripts using the venv
echo "Creating executables..."

create_wrapper() {
    local name="$1"
    local script_path="$2"
    local wrapper_path="$INSTALL_DIR/$name"

    cat > "$wrapper_path" <<EOF
#!/bin/bash
exec "$VENV_DIR/bin/python3" "$script_path" "\$@"
EOF
    chmod +x "$wrapper_path"
    
    # Symlink to bin
    rm -f "$BIN_DIR/$name"
    ln -s "$wrapper_path" "$BIN_DIR/$name"
    echo "Linked $name to $BIN_DIR/$name"
}

create_wrapper "gsc" "$INSTALL_DIR/source/gsc.py"
create_wrapper "sshsc" "$INSTALL_DIR/source/sshsc.py"

# 6. Check PATH
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    # Detect shell
    SHELL_NAME=$(basename "$SHELL")
    RC_FILE=""
    case "$SHELL_NAME" in
        zsh) RC_FILE="$HOME/.zshrc" ;;
        bash) RC_FILE="$HOME/.bashrc" ;;
        *) RC_FILE="$HOME/.profile" ;; # Fallback
    esac

    if [ -n "$RC_FILE" ]; then
        if ! grep -q "export PATH=.*$HOME/bin" "$RC_FILE" && ! grep -q ":\$HOME/bin" "$RC_FILE"; then
            echo -e "\n# GSC path\nexport PATH=\$HOME/bin:\${PATH}" >> "$RC_FILE"
            echo "Added $HOME/bin to PATH in $RC_FILE. Please restart your shell."
        else
            echo "$HOME/bin is not in PATH, but appears to be configured in $RC_FILE. Please restart your shell."
        fi
    else
         echo "Warning: Could not detect shell config file. Please add $HOME/bin to your PATH."
    fi
fi

echo "Installation complete!"