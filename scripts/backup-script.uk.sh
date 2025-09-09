#!/bin/bash

# Автоматичний бекап кількох тек
# Автор: Ростислав Фірсіков <firsikov@gmail.com>
# Ліцензія: Unlicense - вільне поширення та модифікація
# Версія: 1.4.1 (2025-09-09) — додано кольоровий вивід через IS_COLOR

# ======== НАЛАШТУВАННЯ ========

SOURCE_DIRS=(
    "/path/to/folder1"
    "/path/to/folder2"
) # Додайте сюди інші папки, які потрібно відслідковувати

BACKUP_DIR="/path/to/backup" # Тека для збереження бекапів

MAX_BACKUPS_TO_KEEP=20 # Максимальна кількість бекапів для кожної папки
OFFSET="  " # Відступ для виводу повідомлень
IS_COLOR=true  # true = кольоровий вивід, false = без кольорів

# ======== КІНЕЦЬ НАЛАШТУВАННЯ ========

# Ініціалізація кольорів
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

# Перевіряємо чи існує тека для бекапів
if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${OFFSET}${YELLOW}═══ Створюємо теку для бекапів:${NC} $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
fi

# Функція для створення контрольної суми теки
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

# Функція для отримання назви папки з повного шляху
get_folder_name() {
    local path="$1"
    basename "$path"
}

# Функція для видалення старих бекапів конкретної папки
cleanup_old_backups() {
    local folder_name="$1"
    local backup_pattern="${folder_name}_backup_*.zip"
    
    echo -e "${OFFSET}├── Перевіряємо кількість бекапів для ${BLUE}$folder_name${NC}..."
    BACKUP_COUNT=$(find "$BACKUP_DIR" -name "$backup_pattern" | wc -l)
    echo -e "${OFFSET}├── Знайдено бекапів для ${BLUE}$folder_name${NC}: $BACKUP_COUNT"
    
    if [ $BACKUP_COUNT -gt $MAX_BACKUPS_TO_KEEP ]; then
        NUM_TO_DELETE=$(($BACKUP_COUNT - $MAX_BACKUPS_TO_KEEP))
        echo -e "${OFFSET}├── ${YELLOW}Виявлено $NUM_TO_DELETE старих бекапів${NC} для ${BLUE}$folder_name${NC}. Видаляємо (залишаємо останні $MAX_BACKUPS_TO_KEEP)..."
        
        DELETED_FILES=$(find "$BACKUP_DIR" -name "$backup_pattern" -type f | sort | head -n $NUM_TO_DELETE)
        
        if [ -n "$DELETED_FILES" ]; then
            echo "$DELETED_FILES" | xargs rm -f
            echo -e "${OFFSET}├── ${GREEN}Старі бекапи для $folder_name видалено.${NC}"
            echo -e "${OFFSET}└── Видалені файли:"
            echo "$DELETED_FILES"
        else
            echo -e "${OFFSET}└── ${YELLOW}Немає файлів для видалення${NC} для $folder_name."
        fi
    else
        echo -e "${OFFSET}└── Кількість бекапів для ${BLUE}$folder_name${NC} ($BACKUP_COUNT) не перевищує ліміт ($MAX_BACKUPS_TO_KEEP). Видалення не потрібне."
    fi
}

# Функція для бекапу однієї папки
backup_single_folder() {
    local source_dir="$1"
    local folder_name=$(get_folder_name "$source_dir")
    local checksum_file="$BACKUP_DIR/${folder_name}_checksum.md5"
    local current_date=$(date "+%Y-%m-%d_%H-%M-%S")
    local backup_filename="${folder_name}_backup_${current_date}.zip"
    
    echo ""
    echo -e "${OFFSET}╤══ Обробляємо папку: ${BLUE}$folder_name${NC} ($source_dir)"
    
    if [ ! -d "$source_dir" ]; then
        echo -e "${OFFSET}└── ${YELLOW}⚠️ ПОПЕРЕДЖЕННЯ:${NC} Папка $source_dir не існує! Пропускаємо."
        return 2
    fi
    
    echo -e "${OFFSET}├── Обчислюємо контрольну суму для ${BLUE}$folder_name${NC}..."
    CURRENT_CHECKSUM=$(calculate_checksum "$source_dir")
    
    if [ -f "$checksum_file" ]; then
        PREVIOUS_CHECKSUM=$(cat "$checksum_file")
        echo -e "${OFFSET}├── Попередня контрольна сума: ${YELLOW}$PREVIOUS_CHECKSUM${NC}"
        echo -e "${OFFSET}├── Поточна контрольна сума:   ${YELLOW}$CURRENT_CHECKSUM${NC}"
        
        if [ "$CURRENT_CHECKSUM" = "$PREVIOUS_CHECKSUM" ]; then
            echo -e "${OFFSET}└── ${GREEN}Зміни не виявлено${NC} для ${BLUE}$folder_name${NC}. Бекап не потрібен."
            return 1
        else
            echo -e "${OFFSET}├── ${YELLOW}Виявлено зміни${NC} в ${BLUE}$folder_name${NC}! Створюємо бекап..."
        fi
    else
        echo -e "${OFFSET}├── ${YELLOW}Перший запуск${NC} для ${BLUE}$folder_name${NC} - попередня контрольна сума не знайдена."
        echo -e "${OFFSET}├── Створюємо початковий бекап..."
    fi
    
    cd "$(dirname "$source_dir")"
    
    echo -e "${OFFSET}├── Створюємо архів: ${BLUE}$backup_filename${NC}"
    if zip -r "$BACKUP_DIR/$backup_filename" "$(basename "$source_dir")" -x "*.DS_Store" "*/.*" > /dev/null 2>&1; then
        echo -e "${OFFSET}├── ${GREEN}✅ Архів успішно створено:${NC} $backup_filename"
        
        echo "$CURRENT_CHECKSUM" > "$checksum_file"
        echo -e "${OFFSET}├── Контрольна сума збережена"
        
        ARCHIVE_SIZE=$(du -h "$BACKUP_DIR/$backup_filename" | cut -f1)
        echo -e "${OFFSET}├── Розмір архіву: ${YELLOW}$ARCHIVE_SIZE${NC}"
        
        cleanup_old_backups "$folder_name"
        
        return 0
    else
        echo -e "${OFFSET}└── ${RED}❌ ПОМИЛКА:${NC} Не вдалося створити архів для $folder_name!"
        return 2
    fi
}

# ОСНОВНА ЧАСТИНА СКРИПТА
echo -e "[${YELLOW}$(date "+%Y-%m-%d %H-%M-%S")${NC}] Початок перевірки бекапів"
echo -e "${OFFSET}├── Папок для відслідковування: ${YELLOW}${#SOURCE_DIRS[@]}${NC}"
echo -e "${OFFSET}└── Максимальна кількість бекапів для кожної папки: ${YELLOW}${MAX_BACKUPS_TO_KEEP}${NC}"

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
echo -e "${OFFSET}${BLUE}ПІДСУМОК:${NC}"
echo -e "${OFFSET}├── ${GREEN}Успішно оброблено:${NC} $TOTAL_SUCCESS"
echo -e "${OFFSET}├── ${YELLOW}Пропущено (без змін):${NC} $TOTAL_SKIPPED"
echo -e "${OFFSET}└── ${RED}Помилки:${NC} $TOTAL_ERRORS"
echo -e "[${YELLOW}$(date "+%Y-%m-%d %H-%M-%S")${NC}] Завершено"
echo ""
# КІНЕЦЬ СКРИПТА