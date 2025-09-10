#!/bin/bash

# Description:
#   This script runs the Nextcloud OCC files:scan command for a specific user path,
#   logs the results, and optionally sends an email report in HTML format.
#   It supports log rotation based on file size and configurable email reporting levels:
#     - All:     Always send a report
#     - Error:   Send only if Errors > 0
#     - Changes: Send if New/Updated/Removed/Errors > 0
#     - None:    Never send a report
#
#   The script is intended to be run manually or via cron to keep Nextcloud's
#   file cache in sync with the actual filesystem.
#
# Requirements:
#   - Bash shell
#   - Nextcloud OCC CLI tool
#   - sendmail (or compatible MTA)
#   - sudo access for the web server user (e.g., www-data)
#
# Usage:
#   ./occscan.sh [<relative_path_inside_user_files>]
#
# Example:
#   ./occscan.sh "documents/projectX"
#
# Note:
#   Adjust the PATH_TO_NEXTCLOUD, email settings, and other parameters below
#   to match your environment.
#
# Author: Rostyslav Firsikov <https://github.com/rostfirsikov/>
# License: Unlicense - free distribution and modification
# Version: 0.5.0 (2025-09-22) — added colored output via IS_COLOR

# ======== SETTINGS ========

# Path to your Nextcloud installation
PATH_TO_NEXTCLOUD="/barracuda/www/nc" 

# Nextcloud username whose files will be scanned
NC_USERNAME="username_here" 

# Path to the log file
LOG_FILE="$HOME/logs/occscan.log"

# Maximum log file size in bytes before rotation (e.g., 524288 = 512KB)
MAX_LOG_SIZE=524288 

# Email reporting level: All, Error, Changes, None
# Change this after testing script from console to desired level if needed.
#
# email_level_reporting="All"      # Always send a report
# email_level_reporting="Error"    # Send only if Errors > 0
# email_level_reporting="Changes"  # Send if New/Updated/Removed/Errors >
email_level_reporting="None"     # Never send a report

# Email settings
EMAIL_FROM="noreply@example.com" # Sender email address
EMAIL_TO="admin@example.com" # Recipient email address
EMAIL_SUBJECT="Nextcloud OCC Scan Report - $(date '+%Y-%m-%d %H:%M:%S')" # Email subject

# ======== END SETTINGS ========

# Check if the script is run with at most one argument
if [[ "$1" =~ [^a-zA-Z0-9/_.-] ]]; then
    echo "Error: Invalid characters in path parameter"
    exit 1
fi

# Check if Nextcloud OCC exists
if [ ! -f "$PATH_TO_NEXTCLOUD/occ" ]; then
    echo "Error: Nextcloud OCC not found at $PATH_TO_NEXTCLOUD/occ"
    exit 1
fi

# Ensure the log directory exists
mkdir -p "$HOME/logs"

# Check log file size and rotate if necessary
if [ -f "$LOG_FILE" ]; then
    if command -v stat >/dev/null 2>&1; then
        size=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null)
        [ "$size" -gt $MAX_LOG_SIZE ] && mv "$LOG_FILE" "$LOG_FILE.old"
    fi
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting OCC scan for path: $1" >> "$LOG_FILE"

# Start the scan and capture output
TMP_RESULT=$(mktemp)
if sudo -u www-data php "$PATH_TO_NEXTCLOUD/occ" files:scan --path="$NC_USERNAME/files/$1" > "$TMP_RESULT" 2>&1; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: OCC scan completed successfully" >> "$LOG_FILE"
  status="SUCCESS"
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: OCC scan failed" >> "$LOG_FILE"
  status="ERROR"
fi


# Append the OCC output to the log file
cat "$TMP_RESULT" >> "$LOG_FILE"
echo "----------------------------------------" >> "$LOG_FILE"

# Parse the results from the OCC output
read -r folders files new updated removed errors < <(
  grep -E '^\| [0-9]+' "$TMP_RESULT" | awk -F'|' '{print $2,$3,$4,$5,$6,$7}' | xargs
)

# Determine if an email should be sent based on the reporting level

send_email=false

case "$email_level_reporting" in
  All)
    send_email=true
    ;;
  Error)
    [ "$errors" -gt 0 ] && send_email=true
    ;;
  Changes)
    if [ "$new" -gt 0 ] || [ "$updated" -gt 0 ] || [ "$removed" -gt 0 ] || [ "$errors" -gt 0 ]; then
      send_email=true
    fi
    ;;
  None)
    send_email=false
    ;;
esac

# Send email report if needed
if $send_email; then
  {
    echo "From: OCC Scan <$EMAIL_FROM>"
    echo "To: $EMAIL_TO"
    echo "Subject: [$status] $EMAIL_SUBJECT"
    echo "MIME-Version: 1.0"
    echo "Content-Type: text/html; charset=UTF-8"
    echo ""
    echo ""
    echo "<html lang=\"en\">"
    echo "<head>"
    echo "<meta charset=\"UTF-8\">"
    echo "<style>"
    echo "body { font-family: Arial, sans-serif; font-size: 14px; }"
    echo "table { border-collapse: collapse; margin-top: 10px; }"
    echo "th, td { border: 1px solid #ccc; padding: 4px 8px; text-align: center; }"
    echo "th { background-color: #f0f0f0; }"
    echo ".ok { color: green; }"
    echo ".err { color: red; font-weight: bold; }"
    echo "</style>"
    echo "</head>"
    echo "<body>"
    echo "<h2>OCC Scan Report</h2>"
    echo "<p><b>Date:</b> $(date '+%Y-%m-%d %H:%M:%S')</p>"
    echo "<p><b>Status:</b> $status</p>"
    echo "<p><b>Parameter:</b> ${1:-<i>not specified</i>}</p>"
    echo "<h3>Results:</h3>"
    echo "<table>"
    echo "<tr><th>Folders</th><th>Files</th><th>New</th><th>Updated</th><th>Removed</th><th>Errors</th></tr>"
    echo "<tr>"
    echo "<td>$folders</td>"
    echo "<td>$files</td>"
    echo "<td>$new</td>"
    echo "<td>$updated</td>"
    echo "<td>$removed</td>"
    if [ "$errors" -gt 0 ]; then
      echo "<td class=\"err\">$errors</td>"
    else
      echo "<td class=\"ok\">$errors</td>"
    fi
    echo "</tr>"
    echo "</table>"
    if [ "$status" = "ERROR" ]; then
      echo "<h3>Full report of OCC:</h3>"
      echo "<pre style=\"background:#f9f9f9; padding:10px; border:1px solid #ccc;\">"
      cat "$TMP_RESULT"
      echo "</pre>"
    fi
    echo "</body>"
    echo ""
  } | sendmail -t
fi

rm -f "$TMP_RESULT"
