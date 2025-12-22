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

if [ ${#BACKUP_PATHS[@]} -eq 0 ]; then
    log "Error: BACKUP_PATHS not configured (empty array)."
    exit 1
fi

# Function to perform backup for a specific repository
perform_backup() {
    local REPO_URL="$1"
    local REPO_NAME="$2"
    
    # Export the repository variable for restic to use
    export RESTIC_REPOSITORY="$REPO_URL"
    
    log "--- Starting backup for: $REPO_NAME ($REPO_URL) ---"
    
    if [ -t 1 ]; then
        # Interactive mode: Show progress to user and log to file
        # shellcheck disable=SC2068
        restic backup "${BACKUP_PATHS[@]}" --verbose 2>&1 | tee -a "$LOG_FILE"
        local EXIT_CODE=${PIPESTATUS[0]}
    else
        # Background mode: Log only to file
        # shellcheck disable=SC2068
        restic backup "${BACKUP_PATHS[@]}" >> "$LOG_FILE" 2>&1
        local EXIT_CODE=$?
    fi

    if [ $EXIT_CODE -eq 0 ]; then
        log "Backup to $REPO_NAME finished successfully."
        
        # Prune old snapshots
        KEEP_DAILY=${RETENTION_DAILY:-7}
        KEEP_WEEKLY=${RETENTION_WEEKLY:-4}
        KEEP_MONTHLY=${RETENTION_MONTHLY:-12}

        log "Pruning old snapshots for $REPO_NAME..."
        if [ -t 1 ]; then
             restic forget --keep-daily $KEEP_DAILY --keep-weekly $KEEP_WEEKLY --keep-monthly $KEEP_MONTHLY --prune 2>&1 | tee -a "$LOG_FILE"
        else
             restic forget --keep-daily $KEEP_DAILY --keep-weekly $KEEP_WEEKLY --keep-monthly $KEEP_MONTHLY --prune >> "$LOG_FILE" 2>&1
        fi
    else
        log "Backup to $REPO_NAME failed with exit code $EXIT_CODE."
        # We don't exit here to allow other backups to proceed
    fi
}

# Counter for repositories processed
REPO_COUNT=0

# Check and run for Local Repository
if [ -n "$RESTIC_REPOSITORY_LOCAL" ]; then
    perform_backup "$RESTIC_REPOSITORY_LOCAL" "Local Repository"
    ((REPO_COUNT++))
fi

# Check and run for Remote Repository
if [ -n "$RESTIC_REPOSITORY_REMOTE" ]; then
    perform_backup "$RESTIC_REPOSITORY_REMOTE" "Remote Repository"
    ((REPO_COUNT++))
fi

# Check Legacy Repository (if no others were run, or if explicitly set and not clashing)
# If local/remote are unset, but RESTIC_REPOSITORY is set, use it.
if [ $REPO_COUNT -eq 0 ] && [ -n "$RESTIC_REPOSITORY" ]; then
    perform_backup "$RESTIC_REPOSITORY" "Default Repository"
    ((REPO_COUNT++))
fi

if [ $REPO_COUNT -eq 0 ]; then
    log "Error: No repositories configured (RESTIC_REPOSITORY_LOCAL, RESTIC_REPOSITORY_REMOTE, or RESTIC_REPOSITORY)."
    exit 1
fi

log "All backup jobs finished."
exit 0
