#!/bin/bash

# Configuration
CONFIG_FILE="${HOME}/.restic-backup/restic.env"

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
else
    echo "Error: Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Select Repository
REPO_URL=""

if [ -n "$RESTIC_REPOSITORY_LOCAL" ] && [ -n "$RESTIC_REPOSITORY_REMOTE" ]; then
    echo "Multiple repositories found."
    echo "1) Local:  $RESTIC_REPOSITORY_LOCAL"
    echo "2) Remote: $RESTIC_REPOSITORY_REMOTE"
    read -p "Select repository to restore from (1 or 2): " REPO_CHOICE
    
    case $REPO_CHOICE in
        1) REPO_URL="$RESTIC_REPOSITORY_LOCAL" ;;
        2) REPO_URL="$RESTIC_REPOSITORY_REMOTE" ;;
        *) echo "Invalid choice."; exit 1 ;;
    esac
elif [ -n "$RESTIC_REPOSITORY_LOCAL" ]; then
    REPO_URL="$RESTIC_REPOSITORY_LOCAL"
    echo "Using Local Repository: $REPO_URL"
elif [ -n "$RESTIC_REPOSITORY_REMOTE" ]; then
    REPO_URL="$RESTIC_REPOSITORY_REMOTE"
    echo "Using Remote Repository: $REPO_URL"
elif [ -n "$RESTIC_REPOSITORY" ]; then
    REPO_URL="$RESTIC_REPOSITORY"
    echo "Using Default Repository: $REPO_URL"
else
    echo "Error: No repositories configured."
    exit 1
fi

export RESTIC_REPOSITORY="$REPO_URL"

echo "Fetching snapshots..."
restic snapshots

echo ""
echo "Enter the Snapshot ID to restore from (or 'latest'):"
read -r SNAPSHOT_ID

if [ -z "$SNAPSHOT_ID" ]; then
    echo "Error: Snapshot ID is required."
    exit 1
fi

echo "Enter the Target Directory to restore to:"
read -r TARGET_DIR

if [ -z "$TARGET_DIR" ]; then
    echo "Error: Target Directory is required."
    exit 1
fi

# Confirm
echo ""
echo "Restoring snapshot '$SNAPSHOT_ID' to '$TARGET_DIR'..."
read -p "Are you sure? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

mkdir -p "$TARGET_DIR"
restic restore "$SNAPSHOT_ID" --target "$TARGET_DIR"

echo "Restore complete."
