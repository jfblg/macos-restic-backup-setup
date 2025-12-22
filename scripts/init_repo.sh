#!/bin/bash

# Configuration
CONFIG_FILE="${HOME}/.restic-backup/restic.env"
TEMPLATE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config/restic.env.template"

# Ensure config directory exists
mkdir -p "$(dirname "$CONFIG_FILE")"

# Check if configuration exists, if not, copy template
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file not found. Copying template to $CONFIG_FILE..."
    cp "$TEMPLATE_FILE" "$CONFIG_FILE"
    echo "Please edit $CONFIG_FILE with your repository details and passwords before continuing."
    
    # Set secure permissions immediately
    chmod 0600 "$CONFIG_FILE"
    echo "Secure permissions (0600) set on $CONFIG_FILE."
    exit 0
fi

# Enforce secure permissions even if file already exists
chmod 0600 "$CONFIG_FILE"
echo "Enforcing secure permissions (0600) on $CONFIG_FILE..."

# Load configuration
# shellcheck disable=SC1090
source "$CONFIG_FILE"

if ! command -v restic &> /dev/null; then
    echo "Error: restic is not installed."
    exit 1
fi

init_repo() {
    local REPO_URL="$1"
    local REPO_NAME="$2"
    
    export RESTIC_REPOSITORY="$REPO_URL"
    
    echo "----------------------------------------------------------------"
    echo "Initializing $REPO_NAME..."
    echo "Target: $REPO_URL"
    
    # Check if already initialized (check if config file exists in repo)
    # This is tricky for S3 vs Local. Simplest is to try init and catch error, 
    # or check snapshots. restic init fails safely if repo exists.
    
    restic init
    local EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
        echo "Initialization successful."
    else
        echo "Initialization finished with code $EXIT_CODE (It might already exist)."
    fi
}

REPO_COUNT=0

if [ -n "$RESTIC_REPOSITORY_LOCAL" ]; then
    init_repo "$RESTIC_REPOSITORY_LOCAL" "Local Repository"
    ((REPO_COUNT++))
fi

if [ -n "$RESTIC_REPOSITORY_REMOTE" ]; then
    init_repo "$RESTIC_REPOSITORY_REMOTE" "Remote Repository"
    ((REPO_COUNT++))
fi

if [ $REPO_COUNT -eq 0 ] && [ -n "$RESTIC_REPOSITORY" ]; then
    init_repo "$RESTIC_REPOSITORY" "Default Repository"
    ((REPO_COUNT++))
fi

if [ $REPO_COUNT -eq 0 ]; then
    echo "Error: No repositories configured in $CONFIG_FILE."
    exit 1
fi
