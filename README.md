# 🛠 Home Scripts Collection

**Personal collection of Bash scripts for backups, automation, and system maintenance.**  
These scripts are designed for Linux/macOS environments and help automate routine tasks such as backups, monitoring, and housekeeping.

---

## 📌 Features
- 📂 **Backup automation** — create and rotate backups for multiple folders
- 🖥 **System maintenance** — clean old files, monitor changes
- ⚙ **Configurable** — easy to adjust settings via variables
- 🎨 **Optional colored output** — toggle colors with a single variable
- 📝 **Logging support** — save script output to log files

---

## 📂 Repository Structure
<pre>├── backup_script.sh # Main backup automation script 
├── other_script.sh # Example of another utility 
├── README.md # This file 
└── docs/ # Documentation and notes</pre>

---

## 🚀 Usage

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/home-scripts.git
cd home-scripts
```

### 2. Make scripts executable

```bash
chmod +x *.sh
```

### 3. Run a script

```bash
./backup_script.sh
```

### 4. Run with logging

```bash
./backup_script.sh >> /path/to/backup.log 2>&1
```
---
## ⚙ Configuration

Most scripts have a **settings block** at the top.  
Example from `backup_script.sh`:

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

## 🎨 Colored Output

Enable colors: `IS_COLOR=true`

Disable colors: `IS_COLOR=false`

Colors are ANSI escape sequences and will display in terminal or with `less -R` for logs.

---

## 📅 Cron Job Example

To run the backup script every day at 02:00:

```bash
0 2 * * * /path/to/backup_script.sh >> /path/to/backup.log 2>&1
```