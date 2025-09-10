# 🖱 macOS Automator Droplet — Замінює `_` на `-` у назвах файлів

Цей застосунок **Automator** (Droplet) дозволяє перетягнути один або кілька файлів з Finder, і він автоматично перейменує їх, замінивши всі символи підкреслення `_` на дефіси `-`.

---

## ⚙ Як це працює

- Створено в **Automator** як **Application** (Droplet).
- Використовує **Shell Script** всередині Automator для обробки перетягнутих файлів.
- Створює файл журналу `~/droplet-debug.log` для кожного запуску (перезаписується щоразу).
- Працює з кількома файлами одночасно.
- Без спливаючих вікон — працює тихо.

---

## 📋 Shell Script всередині Automator

В Automator, дія **Run Shell Script** містить:

```bash
#!/bin/bash
LOGFILE="$HOME/droplet-debug.log"

# Створюємо новий лог (перезаписуємо)
echo "=== Droplet started at $(date) ===" > "$LOGFILE"

for f in "$@"; do
echo "Processing: $f" >> "$LOGFILE"
dir=$(dirname "$f")
base=$(basename "$f")
newbase="${base//_/-}"
if [[ "$base" != "$newbase" ]]; then
    mv "$f" "$dir/$newbase"
    echo "Renamed to: $newbase" >> "$LOGFILE"
else
    echo "No change needed" >> "$LOGFILE"
fi
done

echo "=== Droplet finished ===" >> "$LOGFILE"
```

---

## 🛠 Як створити Droplet

1. Відкрийте **Automator**.  
![](../img/automator-icon.jpg)
2. Оберіть **New Document** → **Application**.  
![](../img/automator_application_create.jpg)
3. Додайте дію **Run Shell Script** (знайдіть *shell* і двічі клацніть по результату).  
![](../img/automator_shell_script.jpg)
4. Змініть оболонку за замовчуванням у верхньому лівому куті. У верхньому правому куті дії встановіть **Pass input:** → **as arguments**.  
![](../img/automator_shell.jpg)
5. Вставте наведений вище скрипт у дію.  
6. Збережіть застосунок (наприклад, `Underscore to dash.app`) у зручному місці (наприклад, `~/Applications` або на Desktop).  

---

## 🚀 Використання

- Перетягніть один або кілька файлів на іконку Droplet.  
- Скрипт перейменує їх, замінивши `_` на `-`.  
- Перевірте лог командою:  

```bash
cat ~/droplet-debug.log
```

Приклад логу:  

```
=== Droplet started at Wed Sep 10 18:44:05 EEST 2025 ===
Processing: /path/to/file_name_with_underscores.jpg
Renamed to: file-name-with-underscores.jpg
=== Droplet finished ===
```

---

## 📌 Примітки

- Скрипт замінює **усі** символи підкреслення у назві файлу, а не лише перший.  
- Файл журналу перезаписується при кожному запуску.  
- Працює лише з файлами, не з папками (можна розширити для рекурсивної обробки).  
- Якщо файли знаходяться у захищених місцях, можливо, потрібно надати Droplet **Full Disk Access** у  
`System Settings → Privacy & Security → Full Disk Access`.

---

## ⚡ Додатково: створення як Quick Action (Сервіс)

Ви також можете використовувати цей самий скрипт як **Quick Action** у Finder, щоб запускати його з контекстного меню, не перетягуючи файли на Droplet.

---

### 🛠 Як створити Quick Action

1. Відкрийте **Automator**.  
2. Оберіть **New Document** → **Quick Action** (у старих версіях macOS — **Service**).  
![](../img/automator_services.jpg)
3. У верхній частині вікна робочого процесу встановіть:
 - **Workflow receives current:** `files or folders`
 - **in:** `Finder`
![](../img/automator_files.jpg)
4. Додайте дію **Run Shell Script**.  
5. У верхньому правому куті дії встановіть **Pass input:** → **as arguments**.  
![](../img/automator_arguments_2.jpg)
6. Вставте той самий shell‑скрипт, що й вище, у дію.  
7. Збережіть Quick Action (наприклад, `Underscore to dash`) — тепер він з’явиться у меню **Quick Actions** Finder.

---

### 🚀 Використання у Finder

- Клацніть правою кнопкою миші по одному або кількох файлах у Finder.  
- Оберіть **Quick Actions** → `Underscore to dash`.  
- Скрипт перейменує їх, замінивши `_` на `-`.  
- Перевірте лог командою:

```bash
cat ~/droplet-debug.log
```

---

### ⌨️ Порада: призначте клавіатурне скорочення

Для ще швидшого використання Quick Action можна призначити власне клавіатурне скорочення.  
Наприклад, `⌘ ⇧ -` зручно підходить для заміни підкреслень на дефіси.

**Як налаштувати:**

1. Відкрийте **System Settings** (або **System Preferences** у старих версіях macOS).
2. Перейдіть у **Keyboard** → **Keyboard Shortcuts…**.  
![](../img/automator_system_settings.jpg)
3. У лівій панелі оберіть **Services** (або **Quick Actions** у нових версіях macOS).  
![](../img/automator_system_settings_services.jpg)
4. Знайдіть у списку свій Quick Action (наприклад, `Underscore to dash`).  
![](../img/automator_system_settings_shortcut.jpg)
5. Натисніть **Add Shortcut** або двічі клацніть по `none` і введіть бажане поєднання клавіш — наприклад:  
 **`⌘ ⇧ -`**.
6. Натисніть `Done` — скорочення тепер активне.

Тепер ви можете просто виділити файли у Finder і натиснути свою комбінацію клавіш, щоб миттєво перейменувати їх без відкриття меню.

---

### 📌 Примітки для Quick Action

- Працює так само, як і Droplet, але доступний безпосередньо у контекстному меню Finder.  
- Можна призначити клавіатурне скорочення у  
`System Settings → Keyboard → Keyboard Shortcuts → Services`.  
- Файл для `Quick Action` зберігається у `~/Library/Services`.  
- Потребує тих самих дозволів, що й Droplet, для роботи у захищених місцях (Full Disk Access).
