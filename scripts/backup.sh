#!/bin/bash

# Configuration
CONFIG_FILE="${HOME}/.restic-backup/restic.env"
LOG_FILE="${HOME}/.restic-backup/backup.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
else
    echo "Error: Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Check if restic is installed
if ! command -v restic &> /dev/null; then
    echo "Error: restic is not installed." >> "$LOG_FILE"
    exit 1
fi

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log "Starting backup..."

# Perform Backup
# We assume RESTIC_REPOSITORY, RESTIC_PASSWORD_FILE (or RESTIC_PASSWORD), and AWS credentials are set in env
# BACKUP_PATHS should be a bash array in the env file

if [ ${#BACKUP_PATHS[@]} -eq 0 ]; then
    log "Error: BACKUP_PATHS not configured (empty array)."
    exit 1
fi

# shellcheck disable=SC2068
restic backup "${BACKUP_PATHS[@]}" >> "$LOG_FILE" 2>&1
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    log "Backup finished successfully."
    
    # Prune old snapshots (retention policy can be configured via env vars)
    # Default: keep last 7 daily, 4 weekly, 12 monthly
    KEEP_DAILY=${RETENTION_DAILY:-7}
    KEEP_WEEKLY=${RETENTION_WEEKLY:-4}
    KEEP_MONTHLY=${RETENTION_MONTHLY:-12}

    log "Pruning old snapshots..."
    restic forget --keep-daily $KEEP_DAILY --keep-weekly $KEEP_WEEKLY --keep-monthly $KEEP_MONTHLY --prune >> "$LOG_FILE" 2>&1
    
else
    log "Backup failed with exit code $EXIT_CODE."
fi

exit $EXIT_CODE
