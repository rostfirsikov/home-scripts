#!/bin/bash

# Automatic backup of multiple folders
# Author: Rostyslav Firsikov <https://github.com/rostfirsikov/>
# License: Unlicense - free distribution and modification
# Version: 1.4.1 (2025-09-09) — added colored output via IS_COLOR

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

# Initialize colors
if [ "$IS_COLOR" = true ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Check if backup directory exists, if not create it
if [ ! -d "$BACKUP_DIR" ]; then
echo -e "${OFFSET}${YELLOW}═══ Creating backup directory:${NC} $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
fi

# Function to calculate folder checksum
calculate_checksum() {
local dir="$1"
if command -v md5sum > /dev/null 2>&1; then
    find "$dir" -type f -exec md5sum {} \; 2>/dev/null | sort | md5sum | cut -d' ' -f1
elif command -v md5 > /dev/null 2>&1; then
    find "$dir" -type f -exec md5 {} \; 2>/dev/null | sort | md5
else
    find "$dir" -type f -exec shasum {} \; 2>/dev/null | sort | shasum | cut -d' ' -f1
fi
}

# Function to get folder name from full path
get_folder_name() {
local path="$1"
basename "$path"
}

# Function to delete old backups for a specific folder
cleanup_old_backups() {
local folder_name="$1"
local backup_pattern="${folder_name}_backup_*.zip"

echo -e "${OFFSET}├── Checking number of backups for ${BLUE}$folder_name${NC}..."
BACKUP_COUNT=$(find "$BACKUP_DIR" -name "$backup_pattern" | wc -l)
echo -e "${OFFSET}├── Found backups for ${BLUE}$folder_name${NC}: $BACKUP_COUNT"

if [ $BACKUP_COUNT -gt $MAX_BACKUPS_TO_KEEP ]; then
    NUM_TO_DELETE=$(($BACKUP_COUNT - $MAX_BACKUPS_TO_KEEP))
    echo -e "${OFFSET}├── ${YELLOW}Found $NUM_TO_DELETE old backups${NC} for ${BLUE}$folder_name${NC}. Deleting (keeping last $MAX_BACKUPS_TO_KEEP)..."
    
    DELETED_FILES=$(find "$BACKUP_DIR" -name "$backup_pattern" -type f | sort | head -n $NUM_TO_DELETE)
    
    if [ -n "$DELETED_FILES" ]; then
        echo "$DELETED_FILES" | xargs rm -f
        echo -e "${OFFSET}├── ${GREEN}Old backups for $folder_name deleted.${NC}"
        echo -e "${OFFSET}└── Deleted files:"
        echo "$DELETED_FILES"
    else
        echo -e "${OFFSET}└── ${YELLOW}No files to delete${NC} for $folder_name."
    fi
else
    echo -e "${OFFSET}└── Number of backups for ${BLUE}$folder_name${NC} ($BACKUP_COUNT) does not exceed the limit ($MAX_BACKUPS_TO_KEEP). No deletion needed."
fi
}

# Function to back up a single folder
backup_single_folder() {
local source_dir="$1"
local folder_name=$(get_folder_name "$source_dir")
local checksum_file="$BACKUP_DIR/${folder_name}_checksum.md5"
local current_date=$(date "+%Y-%m-%d_%H-%M-%S")
local backup_filename="${folder_name}_backup_${current_date}.zip"

echo ""
echo -e "${OFFSET}╤══ Processing folder: ${BLUE}$folder_name${NC} ($source_dir)"

if [ ! -d "$source_dir" ]; then
    echo -e "${OFFSET}└── ${YELLOW}⚠️ WARNING:${NC} Folder $source_dir does not exist! Skipping."
    return 2
fi

echo -e "${OFFSET}├── Calculating checksum for ${BLUE}$folder_name${NC}..."
CURRENT_CHECKSUM=$(calculate_checksum "$source_dir")

if [ -f "$checksum_file" ]; then
    PREVIOUS_CHECKSUM=$(cat "$checksum_file")
    echo -e "${OFFSET}├── Previous checksum: ${YELLOW}$PREVIOUS_CHECKSUM${NC}"
    echo -e "${OFFSET}├── Current checksum:  ${YELLOW}$CURRENT_CHECKSUM${NC}"
    
    if [ "$CURRENT_CHECKSUM" = "$PREVIOUS_CHECKSUM" ]; then
        echo -e "${OFFSET}└── ${GREEN}No changes detected${NC} for ${BLUE}$folder_name${NC}. Backup not needed."
        return 1
    else
        echo -e "${OFFSET}├── ${YELLOW}Changes detected${NC} in ${BLUE}$folder_name${NC}! Creating backup..."
    fi
else
    echo -e "${OFFSET}├── ${YELLOW}First run${NC} for ${BLUE}$folder_name${NC} - no previous checksum found."
    echo -e "${OFFSET}├── Creating initial backup..."
fi

cd "$(dirname "$source_dir")"

echo -e "${OFFSET}├── Creating archive: ${BLUE}$backup_filename${NC}"
if zip -r "$BACKUP_DIR/$backup_filename" "$(basename "$source_dir")" -x "*.DS_Store" "*/.*" > /dev/null 2>&1; then
    echo -e "${OFFSET}├── ${GREEN}✅ Archive successfully created:${NC} $backup_filename"
    
    echo "$CURRENT_CHECKSUM" > "$checksum_file"
    echo -e "${OFFSET}├── Checksum saved"
    
    ARCHIVE_SIZE=$(du -h "$BACKUP_DIR/$backup_filename" | cut -f1)
    echo -e "${OFFSET}├── Archive size: ${YELLOW}$ARCHIVE_SIZE${NC}"
    
    cleanup_old_backups "$folder_name"
    
    return 0
else
    echo -e "${OFFSET}└── ${RED}❌ ERROR:${NC} Failed to create archive for $folder_name!"
    return 2
fi
}

# MAIN SCRIPT
echo -e "[${YELLOW}$(date "+%Y-%m-%d %H-%M-%S")${NC}] Starting backup check"
echo -e "${OFFSET}├── Folders to monitor: ${YELLOW}${#SOURCE_DIRS[@]}${NC}"
echo -e "${OFFSET}└── Max backups per folder: ${YELLOW}${MAX_BACKUPS_TO_KEEP}${NC}"

TOTAL_SUCCESS=0
TOTAL_SKIPPED=0
TOTAL_ERRORS=0

for source_dir in "${SOURCE_DIRS[@]}"; do
backup_single_folder "$source_dir"
result_code=$?
case $result_code in
    0) TOTAL_SUCCESS=$((TOTAL_SUCCESS + 1)) ;;
    1) TOTAL_SKIPPED=$((TOTAL_SKIPPED + 1)) ;;
    2) TOTAL_ERRORS=$((TOTAL_ERRORS + 1)) ;;
esac
done

echo ""
echo -e "${OFFSET}${BLUE}SUMMARY:${NC}"
echo -e "${OFFSET}├── ${GREEN}Successfully processed:${NC} $TOTAL_SUCCESS"
echo -e "${OFFSET}├── ${YELLOW}Skipped (no changes):${NC} $TOTAL_SKIPPED"
echo -e "${OFFSET}└── ${RED}Errors:${NC} $TOTAL_ERRORS"
echo -e "[${YELLOW}$(date "+%Y-%m-%d %H-%M-%S")${NC}] Finished"
echo ""
# END OF SCRIPT