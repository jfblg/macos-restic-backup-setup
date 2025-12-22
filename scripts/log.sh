#!/bin/bash

LOG_FILE="${HOME}/.restic-backup/backup.log"

if [ ! -f "$LOG_FILE" ]; then
    echo "No log file found at $LOG_FILE"
    exit 1
fi

# If arguments are provided (e.g. -f for follow), pass them to tail
# If no arguments, show the last 50 lines
if [ $# -eq 0 ]; then
    tail -n 50 "$LOG_FILE"
else
    tail "$@" "$LOG_FILE"
fi
