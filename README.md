# macOS Restic Backup Setup

This project provides a comprehensive set of scripts to configure, schedule, and manage backups on macOS using [restic](https://restic.net/). It supports backing up to AWS S3 or local/mounted filesystems.

## Features

- **3-2-1 Strategy Support**: Easily implement a [3-2-1 backup strategy](https://en.wikipedia.org/wiki/Backup#3-2-1_strategy) with sequential local and remote backups.
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

3.  **Initialize Configuration:**
    Run the initialization script to create your config directory and file:
    ```bash
    ./scripts/init_repo.sh
    ```
    This script will:
    - Create `~/.restic-backup/restic.env` from the template if it doesn't exist.
    - Set **secure permissions (0600)** so only your user can read the secrets.
    - Inform you to edit the file with your specific settings.

4.  **Configure Backend (Choose One):**

    *   **Option A: AWS S3**
        Run the helper script to create the bucket and IAM user:
        ```bash
        ./scripts/setup_aws.sh
        ```
        Follow the prompts. Copy the outputted credentials into `~/.restic-backup/restic.env`.

    *   **Option B: Local/Mounted Path**
        Edit `~/.restic-backup/restic.env` and set `RESTIC_REPOSITORY_LOCAL` (e.g., `/Volumes/BackupDrive/restic-repo`).

    *   **3-2-1 Backup Strategy (Recommended)**
        You can configure **both** `RESTIC_REPOSITORY_LOCAL` and `RESTIC_REPOSITORY_REMOTE` in `restic.env`. The backup script will automatically back up to both locations sequentially. See the [3-2-1 strategy](https://en.wikipedia.org/wiki/Backup#3-2-1_strategy) for more details.

5.  **Finalize Configuration:**
    Edit `~/.restic-backup/restic.env` and set your password and `BACKUP_PATHS`.

6.  **Initialize Repository Metadata:**
    Run the initialization script **again** after you've finished editing the config file to actually create the restic repositories:
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

If you ran the optional `./scripts/install_cli.sh` script, you can use the commands below from any directory. Otherwise, run the scripts directly from the `scripts/` folder.

### Check Logs
View the backup history and status:
```bash
# Using CLI tools:
restic-log

# Running script directly:
./scripts/log.sh
```
*Note: Run `restic-log -f` to follow logs in real-time.*

### Manual Backup
Trigger a backup job immediately:
```bash
# Using CLI tools:
restic-backup

# Running script directly:
./scripts/backup.sh
```

### Restore Files
Restore files from a specific snapshot:
```bash
# Using CLI tools:
restic-restore

# Running script directly:
./scripts/restore.sh
```
The script will prompt you to select the repository (if multiple are configured) and the snapshot ID.

For manual restoration using standard restic commands:
```bash
source ~/.restic-backup/restic.env
export RESTIC_REPOSITORY=$RESTIC_REPOSITORY_REMOTE # or RESTIC_REPOSITORY_LOCAL
restic restore latest --target /path/to/restore
```

## Directory Structure

- `scripts/`: Helper scripts for setup, backup, and restore.
- `config/`: Configuration templates.
- `templates/`: Launchd plist templates.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
