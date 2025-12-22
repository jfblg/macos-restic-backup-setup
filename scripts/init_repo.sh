#!/bin/bash

# Configuration
CONFIG_FILE="${HOME}/.restic-backup/restic.env"

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
else
    echo "Error: Configuration file not found at $CONFIG_FILE"
    echo "Please copy config/restic.env.template to $CONFIG_FILE and edit it."
    exit 1
fi

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
