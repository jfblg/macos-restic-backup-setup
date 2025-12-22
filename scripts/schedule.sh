#!/bin/bash

# Define paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_SCRIPT="$PROJECT_ROOT/scripts/backup.sh"
TEMPLATE_FILE="$PROJECT_ROOT/templates/com.user.restic-backup.plist.template"
DEST_PLIST="$HOME/Library/LaunchAgents/com.user.restic-backup.plist"
LOG_FILE="$HOME/.restic-backup/backup.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

echo "Setting up daily backup schedule..."

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template file not found at $TEMPLATE_FILE"
    exit 1
fi

# Ensure LaunchAgents directory exists
mkdir -p "$(dirname "$DEST_PLIST")"

# Create the plist file from template
sed -e "s|{{SCRIPT_PATH}}|$BACKUP_SCRIPT|g" \
    -e "s|{{LOG_PATH}}|$LOG_FILE|g" \
    "$TEMPLATE_FILE" > "$DEST_PLIST"

if [ ! -f "$DEST_PLIST" ]; then
    echo "Error: Failed to create plist file at $DEST_PLIST"
    exit 1
fi

echo "Created plist at $DEST_PLIST"

# Unload previous if exists
if launchctl list | grep -q "com.user.restic-backup"; then
    echo "Unloading existing job..."
    launchctl unload "$DEST_PLIST"
fi

# Load the new plist
echo "Loading new job..."
launchctl load "$DEST_PLIST"

echo "Schedule setup complete! Backups will run daily at 12:00 PM."
echo "You can edit $DEST_PLIST to change the schedule."
