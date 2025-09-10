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
<pre>├── README.md # This file 
├┬─ scripts/ 
│└── *.sh # Some automation scripts
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
cd scripts
chmod +x *.sh
```

## Index

1. [backup-script.sh](docs/backup-script.md) - Backup multiple folders ([Ukrainian version 🇺🇦](docs/backup-script.uk.md))
2. [macOS Automator Droplet — Replace `_` with `-` in filenames](docs/replace-underscores-to-dashes-droplet.md) ([Ukrainian version 🇺🇦](docs/replace-underscores-to-dashes-droplet.uk.md))