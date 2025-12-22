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

echo "Initializing Restic Repository at: $RESTIC_REPOSITORY"

if command -v restic &> /dev/null; then
    restic init
else
    echo "Error: restic is not installed."
    exit 1
fi
