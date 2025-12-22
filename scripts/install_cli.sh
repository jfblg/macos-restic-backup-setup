#!/bin/bash

# Define installation directory
# /usr/local/bin is standard for user-installed binaries on macOS and is usually in PATH
INSTALL_DIR="/usr/local/bin"

# Get absolute path to the project scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing 'restic-backup' and 'restic-restore' to $INSTALL_DIR..."

# Function to link a file
link_file() {
    local SRC="$1"
    local DEST_NAME="$2"
    local DEST="$INSTALL_DIR/$DEST_NAME"

    # Check if we have write permissions
    if [ -w "$INSTALL_DIR" ]; then
        ln -sf "$SRC" "$DEST"
        echo "Linked: $DEST -> $SRC"
    else
        # Try with sudo
        echo "Permission denied. Trying with sudo..."
        sudo ln -sf "$SRC" "$DEST"
        echo "Linked (with sudo): $DEST -> $SRC"
    fi
}

link_file "$SCRIPT_DIR/backup.sh" "restic-backup"
link_file "$SCRIPT_DIR/restore.sh" "restic-restore"
link_file "$SCRIPT_DIR/log.sh" "restic-log"

echo "----------------------------------------------------------------"
echo "CLI tools installed successfully!"
echo "You can now run 'restic-backup', 'restic-restore', and 'restic-log' from anywhere."
