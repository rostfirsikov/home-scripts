# Nextcloud OCC Scan Script

This Bash script runs the Nextcloud `occ files:scan` command for a specific user path, logs the results, and optionally sends an HTML email report.

It is designed to be run manually or via `cron` to keep Nextcloud's file cache in sync with the actual filesystem.

---

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Log Rotation](#log-rotation)
- [Email Reporting](#email-reporting)
- [Example Email Report](#example-email-report)
- [Scheduling with Cron](#scheduling-with-cron)

---

## Features <a name="features"></a>

- Runs `occ files:scan` for a specific Nextcloud user path.
- Logs all scan results to a file with automatic log rotation.
- Configurable email reporting levels:
- **All** – Always send a report.
- **Error** – Send only if `Errors > 0`.
- **Changes** – Send if `New`, `Updated`, `Removed`, or `Errors` > 0.
- **None** – Never send a report.
- Sends HTML-formatted email reports with a summary table.
- Optionally includes the full OCC output in the email if the scan fails.
- Works with `sendmail` or compatible MTAs (e.g., `msmtp`, `postfix`).

---

## Requirements <a name="requirements"></a>

- **Bash** shell
- **Nextcloud OCC** CLI tool
- **sendmail** or compatible MTA
- `sudo` access for the web server user (e.g., `www-data`)

---

## Installation <a name="installation"></a>

1. Clone or download this repository.
2. Place the script in a directory of your choice, e.g.:

 ```bash
 mkdir -p ~/bin
 cp occscan.sh ~/bin/
 chmod +x ~/bin/occscan.sh
 ```

3. Edit the **SETTINGS** section in the script to match your environment:

 ```bash
 PATH_TO_NEXTCLOUD="/path/to/nextcloud"
 NC_USERNAME="username_here"
 LOG_FILE="$HOME/logs/occscan.log"
 EMAIL_FROM="noreply@example.com"
 EMAIL_TO="admin@example.com"
 email_level_reporting="All"
 ```

4. Ensure `occ` can be run without a password via `sudo`:

 ```bash
 sudo visudo
 ```

 Add a line like:

 ```
 youruser ALL=(www-data) NOPASSWD: /path/to/nextcloud/occ
 ```

---

## Usage <a name="usage"></a>

Run the script manually:

```bash
./occscan.sh [<relative_path_inside_user_files>]
```

Examples:

```bash
# Scan the entire user files directory
./occscan.sh

# Scan a specific folder inside the user's files
./occscan.sh "documents/projectX"
```

---

## Log Rotation <a name="log-rotation"></a>

- The script automatically rotates the log file if it exceeds the size defined in `MAX_LOG_SIZE` (default: 512 KB).
- The old log is renamed to `occscan.log.old`.

---

## Email Reporting <a name="email-reporting"></a>

- The script sends HTML email reports using `sendmail`.
- Reporting level is controlled by the `email_level_reporting` variable:
- `All` – Always send a report.
- `Error` – Send only if there are errors.
- `Changes` – Send if there are changes or errors.
- `None` – Never send a report.
- If the scan fails (`status=ERROR`), the full OCC output is included in the email.

---

## Example Email Report <a name="example-email-report"></a>

**Subject:**
```
[SUCCESS] Nextcloud OCC Scan Report - 2025-09-21 15:42:00
```

**Body:**
- Date
- Status
- Parameter (path scanned)
- Results table
- Full OCC output (only if status is ERROR)

## Scheduling with Cron <a name="scheduling-with-cron"></a>

You can automate the execution of this script using `cron` so that it runs at a specific time every day.

For example, to run the scan every night at **02:00 AM**:

1. Open the crontab editor for your user:

```bash
crontab -e
```

2. Add one of the following lines at the end of the file:

**Option 1 — run directly (script must be executable):**
```cron
0 2 * * * /path/to/occscan.sh >> /path/to/occscan_cron.log 2>&1
```
In this case:
- The script must have execute permissions:
  ```bash
  chmod +x /path/to/occscan.sh
  ```
- The first line of the script (`#!...`) must point to the correct shell (e.g., `#!/bin/bash`).

**Option 2 — run via Bash (no execute bit required):**
```cron
0 2 * * * /usr/bin/bash /path/to/occscan.sh >> /path/to/occscan_cron.log 2>&1
```
In this case:
- The script only needs read permissions (`chmod +r`).
- The execute bit (`+x`) is not required because `bash` reads the file directly.

3. Save and exit the editor.

4. Verify your cron jobs:

```bash
crontab -l
```

**Notes:**
- Always use **absolute paths** in cron jobs (both for the script and any files it uses), because cron runs with a minimal environment.
- Redirecting output (`>> /path/to/occscan_cron.log 2>&1`) is optional but recommended for debugging.
- If the script sends email reports, make sure your system's `sendmail` or MTA is properly configured.
