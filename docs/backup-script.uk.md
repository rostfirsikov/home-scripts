# backup-script.uk.sh

## 1. ⚙ Налаштування

**Блок налаштувань** на початку `backup-script.sh`:

```bash
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
```

---

### 🎨 Кольоровий вивід

Увімкнути кольори: `IS_COLOR=true`

Вимкнути кольори: `IS_COLOR=false`

Кольори — це ANSI escape‑послідовності, які відображаються у терміналі або при перегляді логів за допомогою команд `less -R backup.log`, `tail backup.log` або `cat backup.log`.

---

## 2. Запуск скрипта

```bash
./backup-script.sh
```

### Запуск з логуванням

```bash
./backup-script.sh >> /path/to/backup.log 2>&1
```
---

## 3. 📅 Приклад завдання Cron

Щоб запускати скрипт резервного копіювання щодня о 02:00 відкрийте для редагування crontab командою `crontab -e` та додайте наступний рядок:

```bash
0 2 * * * /path/to/backup-script.sh >> /path/to/backup.log 2>&1
```