# backup-script.sh

## 1. ⚙ Configuration

Most scripts have a **settings block** at the top.  
Example from `backup-script.sh`:

```bash
# ======== SETTINGS
IS_COLOR=true  # true = colored output, false = plain text
SOURCE_DIRS=(
"/path/to/folder1"
"/path/to/folder2"
)
BACKUP_DIR="/path/to/backup"
MAX_BACKUPS_TO_KEEP=20
OFFSET="  "
# ======== END SETTINGS
```

---

### 🎨 Colored Output

Enable colors: `IS_COLOR=true`

Disable colors: `IS_COLOR=false`

Colors are ANSI escape sequences and will display in terminal or with `less -R` for logs.

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

To run the backup script every day at 02:00:

```bash
0 2 * * * /path/to/backup-script.sh >> /path/to/backup.log 2>&1
```