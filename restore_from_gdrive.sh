#!/bin/bash

# Скрипт відновлення з Google Drive
GDRIVE_REMOTE="gdrive"
GDRIVE_PATH="HomeAssistant_Backups"
RESTORE_DIR="/opt/restore"

echo "🔄 Відновлення з Google Drive бекапу"

# Перевіряємо доступність Google Drive
if ! rclone listremotes | grep -q "^${GDRIVE_REMOTE}:$"; then
    echo "❌ Google Drive не налаштований!"
    echo "   Запустіть: /root/setup_gdrive.sh"
    exit 1
fi

# Показуємо доступні бекапи
echo "📋 Доступні бекапи на Google Drive:"
rclone ls ${GDRIVE_REMOTE}:${GDRIVE_PATH}/ | grep "full_backup_.*_FULL.tar.gz" | sort

echo ""
echo "Введіть назву бекапу для відновлення (або 'latest' для останнього):"
read BACKUP_CHOICE

if [ "$BACKUP_CHOICE" = "latest" ]; then
    BACKUP_FILE=$(rclone ls ${GDRIVE_REMOTE}:${GDRIVE_PATH}/ | grep "full_backup_.*_FULL.tar.gz" | sort | tail -1 | awk '{print $2}')
else
    BACKUP_FILE="$BACKUP_CHOICE"
fi

if [ -z "$BACKUP_FILE" ]; then
    echo "❌ Бекап не знайдено!"
    exit 1
fi

echo "📥 Завантаження бекапу: $BACKUP_FILE"
mkdir -p $RESTORE_DIR
rclone copy ${GDRIVE_REMOTE}:${GDRIVE_PATH}/${BACKUP_FILE} $RESTORE_DIR/ --progress

echo "📦 Розпаковування бекапу..."
cd $RESTORE_DIR
tar -xzf $BACKUP_FILE

echo "✅ Бекап завантажено в $RESTORE_DIR"
echo ""
echo "Для відновлення:"
echo "1. Зупиніть контейнери: docker stop homeassistant matter-server"
echo "2. Відновіть конфігурацію: tar -xzf *_ha_config.tar.gz -C /opt/homeassistant/"
echo "3. Відновіть Matter: tar -xzf *_matter.tar.gz -C /opt/"
echo "4. Відновіть Cloudflare: tar -xzf *_cloudflared.tar.gz -C /root/"
echo "5. Запустіть контейнери: docker start homeassistant matter-server"