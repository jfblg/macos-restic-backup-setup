# macOS Restic Backup Setup

This project provides a comprehensive set of scripts to configure, schedule, and manage backups on macOS using [restic](https://restic.net/). It supports backing up to AWS S3 or local/mounted filesystems.

## Features

- **Automated Setup**: Helper scripts to install Restic and configure AWS S3 (IAM User, Policy, Bucket).
- **Scheduling**: Daily background backups using macOS `launchd` (runs automatically even if the computer was asleep).
- **Secure**: Credentials are stored in a separate, user-owned configuration file.
- **Maintenance**: Automatic pruning of old snapshots based on a configurable retention policy.
- **Logging**: Detailed logs of backup runs.
- **Restoration**: Interactive helper script to restore files.

## Prerequisites

- macOS
- `git` (to clone this repo)
- `brew` (optional, for installing restic automatically)
- AWS CLI (if using S3 backend)

## Installation & Setup

1.  **Clone the repository:**
    ```bash
    git clone <repository_url>
    cd backup-restic-macos
    ```

2.  **Install Restic:**
    ```bash
    ./scripts/install_restic.sh
    ```

3.  **Prepare Configuration:**
    Create the configuration directory and copy the template:
    ```bash
    mkdir -p ~/.restic-backup
    cp config/restic.env.template ~/.restic-backup/restic.env
    ```

4.  **Configure Backend (Choose One):**

    *   **Option A: AWS S3**
        Run the helper script to create the bucket and IAM user with restricted permissions:
        ```bash
        ./scripts/setup_aws.sh
        ```
        This script will also apply an S3 Lifecycle Rule to automatically transition all data to the **Intelligent-Tiering** storage class, optimizing storage costs.
        
        Follow the prompts. Copy the outputted credentials into `~/.restic-backup/restic.env`.

    *   **Option B: Local/Mounted Path**
        Edit `~/.restic-backup/restic.env` and set `RESTIC_REPOSITORY_LOCAL` to your local path (e.g., `/Volumes/BackupDrive/restic-repo`).

    *   **3-2-1 Backup Strategy (Recommended)**
        You can configure **both** `RESTIC_REPOSITORY_LOCAL` and `RESTIC_REPOSITORY_REMOTE` in `restic.env`. The backup script will automatically back up to both locations sequentially, ensuring you have a local copy for fast restores and an offsite copy for disaster recovery.

5.  **Finalize Configuration:**
    Edit `~/.restic-backup/restic.env` to set your password and the paths you want to backup (`BACKUP_PATHS`).

6.  **Initialize Repositories:**
    Run this once to initialize the configured repositories:
    ```bash
    ./scripts/init_repo.sh
    ```

7.  **Schedule Backups:**
    Install the daily schedule (default is 12:00 PM):
    ```bash
    ./scripts/schedule.sh
    ```
    *Note: If your Mac is asleep at the scheduled time, the backup will run when it wakes up.*

8.  **Install CLI Tools (Optional):**
    To run commands like `restic-backup` and `restic-restore` from anywhere in your terminal (without needing to cd into this directory), run:
    ```bash
    ./scripts/install_cli.sh
    ```
    This creates symlinks in `/usr/local/bin`.

## Usage

### Check Logs
Logs are written to `~/.restic-backup/backup.log`. You can view them using the CLI tool:
```bash
# Show last 50 lines
restic-log

# Follow the log in real-time
restic-log -f
```

### Manual Backup
You can trigger a backup manually at any time:
```bash
./scripts/backup.sh
```

### Restore Files
Use the interactive restore script, which will ask you which repository to use if multiple are configured:
```bash
./scripts/restore.sh
```
Or use standard restic commands (remember to source the config and export the correct repository):
```bash
source ~/.restic-backup/restic.env
export RESTIC_REPOSITORY=$RESTIC_REPOSITORY_REMOTE # or _LOCAL
restic restore latest --target /tmp/restore
```

## Directory Structure

- `scripts/`: Helper scripts for setup, backup, and restore.
- `config/`: Configuration templates.
- `templates/`: Launchd plist templates.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
