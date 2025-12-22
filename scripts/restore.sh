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
