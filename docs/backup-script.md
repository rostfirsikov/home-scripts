# backup-script.sh

## 1. ⚙ Configuration

The **settings block** at the top of `backup-script.sh`:

```bash
# ======== SETTINGS ========

SOURCE_DIRS=(
    "/path/to/folder1"
    "/path/to/folder2"
) # Folders to back up

BACKUP_DIR="/path/to/backup" # Folder to store backups
MAX_BACKUPS_TO_KEEP=20 # Maximum number of backups to keep per folder
OFFSET="  " # Indentation for output
IS_COLOR=true  # true = colored output, false = plain text

# ======== END SETTINGS ========
```

---

### 🎨 Colored Output

Enable colors: `IS_COLOR=true`

Disable colors: `IS_COLOR=false`

Colors are ANSI escape sequences and will display in terminal or with `less -R backup.log`, `tail backup.log` or `cat backup.log` for logs.

---

## 2. Run a script

```bash
./backup-script.sh
```

### Run with logging

```bash
./backup-script.sh >> /path/to/backup.log 2>&1
```
---

## 3. 📅 Cron Job Example

To run the backup script every day at 02:00, open the crontab for editing with the command `crontab -e` and add the following line:

```bash
0 2 * * * /path/to/backup-script.sh >> /path/to/backup.log 2>&1
```