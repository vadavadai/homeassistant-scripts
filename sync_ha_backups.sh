#!/bin/bash

# Синхронізація стандартних Home Assistant бекапів з Google Drive
BACKUP_DIR="/opt/homeassistant/config/backups"
GDRIVE_REMOTE="vadagooga"
GDRIVE_PATH="HomeAssistant_Backups/HA_Auto_Backups"

echo "🚀 Синхронізація HA бекапів з Google Drive..."

# Перевіряємо чи налаштований Google Drive
if ! rclone listremotes | grep -q "^${GDRIVE_REMOTE}:$"; then
    echo "❌ Google Drive не налаштований (rclone remote '${GDRIVE_REMOTE}' не знайдено)"
    exit 1
fi

# Перевіряємо чи існує папка з бекапами
if [ ! -d "$BACKUP_DIR" ]; then
    echo "❌ Папка з бекапами не знайдена: $BACKUP_DIR"
    exit 1
fi

# Підраховуємо кількість .tar файлів
backup_count=$(find "$BACKUP_DIR" -name "*.tar" -type f | wc -l)
echo "📦 Знайдено HA бекапів: $backup_count"

if [ $backup_count -eq 0 ]; then
    echo "⚠️ Бекапи не знайдені"
    exit 0
fi

# Завантажуємо тільки нові бекапи (синхронізуємо)
echo "☁️ Синхронізація з Google Drive..."
rclone sync "$BACKUP_DIR"/ "${GDRIVE_REMOTE}:${GDRIVE_PATH}/" \
    --include="*.tar" \
    --progress \
    --transfers=1 \
    --checkers=1

if [ $? -eq 0 ]; then
    echo "✅ Синхронізація завершена успішно!"
    
    # Показуємо статистику
    echo "📊 Статистика:"
    rclone size "${GDRIVE_REMOTE}:${GDRIVE_PATH}/"
    
    # Залишаємо тільки 10 останніх HA бекапів на Google Drive
    echo "🧹 Очищення старих HA бекапів..."
    rclone lsf "${GDRIVE_REMOTE}:${GDRIVE_PATH}/" --include "*.tar" | sort -r | tail -n +11 | while read file; do
        if [ -n "$file" ]; then
            echo "🗑️ Видаляємо старий HA бекап: $file"
            rclone delete "${GDRIVE_REMOTE}:${GDRIVE_PATH}/$file"
        fi
    done
    
else
    echo "❌ Помилка синхронізації!"
    exit 1
fi

echo "🎉 Синхронізація HA бекапів завершена!"