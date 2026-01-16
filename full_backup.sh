#!/bin/bash

# Повний бекап Home Assistant + Matter + система + Google Drive
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/backups"
BACKUP_NAME="full_backup_${DATE}"
GDRIVE_REMOTE="gdrive"  # Назва rclone remote для Google Drive
GDRIVE_PATH="HomeAssistant_Backups"  # Папка на Google Drive

echo "🚀 Створення повного бекапу: $BACKUP_NAME"

# Створюємо директорію для бекапів
mkdir -p $BACKUP_DIR

# 1. Бекап Home Assistant (через API)
echo "📦 Створення HA бекапу..."
curl -X POST -H "Authorization: Bearer $(docker exec homeassistant cat /config/.storage/auth | jq -r '.data.access_tokens[0].token' 2>/dev/null || echo 'LONG_LIVED_TOKEN')" \
     -H "Content-Type: application/json" \
     -d '{"name": "auto_backup_'$DATE'", "compressed": true}' \
     http://localhost:8123/api/hassio/backups/new/full >/dev/null 2>&1

# 2. Копіюємо HA конфіг
echo "📁 Копіювання HA конфігу..."
tar -czf $BACKUP_DIR/${BACKUP_NAME}_ha_config.tar.gz -C /opt/homeassistant config/

# 3. Бекап Matter Server
echo "🔗 Копіювання Matter даних..."
tar -czf $BACKUP_DIR/${BACKUP_NAME}_matter.tar.gz -C /opt matter-server/

# 4. Бекап Cloudflared
echo "☁️ Копіювання Cloudflare конфігу..."
tar -czf $BACKUP_DIR/${BACKUP_NAME}_cloudflared.tar.gz -C /root .cloudflared/

# 5. Системні сервіси
echo "⚙️ Копіювання системних сервісів..."
cp /etc/systemd/system/cloudflared.service $BACKUP_DIR/${BACKUP_NAME}_cloudflared.service 2>/dev/null || true

# 6. Список Docker контейнерів та образів
echo "🐳 Створення списку Docker образів..."
docker images --format "{{.Repository}}:{{.Tag}}" > $BACKUP_DIR/${BACKUP_NAME}_docker_images.txt
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" > $BACKUP_DIR/${BACKUP_NAME}_docker_containers.txt

# 7. Мережеві налаштування
echo "🌐 Копіювання мережевих налаштувань..."
ip addr > $BACKUP_DIR/${BACKUP_NAME}_network_config.txt
cat /etc/resolv.conf > $BACKUP_DIR/${BACKUP_NAME}_dns_config.txt 2>/dev/null || true

# 8. Створення загального архіву
echo "📦 Створення фінального архіву..."
tar -czf $BACKUP_DIR/${BACKUP_NAME}_FULL.tar.gz -C $BACKUP_DIR ${BACKUP_NAME}_*

# Очищення тимчасових файлів
rm -f $BACKUP_DIR/${BACKUP_NAME}_*.tar.gz $BACKUP_DIR/${BACKUP_NAME}_*.txt $BACKUP_DIR/${BACKUP_NAME}_*.service

echo "✅ Повний бекап створено: $BACKUP_DIR/${BACKUP_NAME}_FULL.tar.gz"
echo "📊 Розмір бекапу:"
ls -lh $BACKUP_DIR/${BACKUP_NAME}_FULL.tar.gz

# 9. Завантаження на Google Drive
if rclone listremotes | grep -q "^${GDRIVE_REMOTE}:$"; then
    echo "☁️ Завантаження на Google Drive..."
    rclone copy $BACKUP_DIR/${BACKUP_NAME}_FULL.tar.gz ${GDRIVE_REMOTE}:${GDRIVE_PATH}/ --progress
    if [ $? -eq 0 ]; then
        echo "✅ Бекап успішно завантажено на Google Drive!"
        
        # Видаляємо старі бекапи з Google Drive (більше 14 днів)
        echo "🧹 Очищення старих бекапів з Google Drive..."
        rclone delete ${GDRIVE_REMOTE}:${GDRIVE_PATH}/ --min-age 14d --include "full_backup_*_FULL.tar.gz"
    else
        echo "❌ Помилка завантаження на Google Drive!"
    fi
else
    echo "⚠️ Google Drive не налаштований (rclone remote '${GDRIVE_REMOTE}' не знайдено)"
    echo "   Запустіть: rclone config"
fi

# Видаляємо локальні старі бекапи (більше 7 днів)
find $BACKUP_DIR -name "full_backup_*_FULL.tar.gz" -mtime +7 -delete 2>/dev/null || true

echo "🎉 Бекап завершено!"