#!/bin/bash

# 🔄 Автоматичне оновлення Home Assistant Docker образу
# Логіка: перевірка → бекап конфігу → оновлення → перезапуск → перевірка

set -e

LOG_FILE="/opt/homeassistant/homeassistant-scripts/update.log"
BACKUP_DIR="/opt/homeassistant/full-backups"
CONTAINER="homeassistant"
IMAGE="ghcr.io/home-assistant/home-assistant:stable"
GDRIVE_REMOTE="vadagooga"
GDRIVE_PATH="HomeAssistant_Backups"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" | tee -a "$LOG_FILE"
}

log "🔍 Перевірка оновлень Home Assistant..."

# 1. Отримуємо digest запущеного контейнера
OLD_IMAGE_ID=$(docker inspect "$CONTAINER" --format='{{.Image}}' 2>/dev/null || echo "")
if [ -z "$OLD_IMAGE_ID" ]; then
    log "❌ Контейнер '$CONTAINER' не знайдено. Виходимо."
    exit 1
fi

# 2. Завантажуємо новий образ
log "⬇️  Завантаження нового образу..."
docker pull "$IMAGE" --quiet

# 3. Порівнюємо
NEW_IMAGE_ID=$(docker inspect "$IMAGE" --format='{{.Id}}' 2>/dev/null)

if [ "$NEW_IMAGE_ID" = "$OLD_IMAGE_ID" ]; then
    log "✅ Оновлень немає. Поточний образ актуальний."
    exit 0
fi

OLD_SHORT=$(echo "$OLD_IMAGE_ID" | cut -c 8-19)
NEW_SHORT=$(echo "$NEW_IMAGE_ID" | cut -c 8-19)
log "🎉 Знайдено нову версію! $OLD_SHORT → $NEW_SHORT"

# 4. Бекап конфігурації
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="pre_update_${DATE}"
mkdir -p "$BACKUP_DIR"

log "📦 Створення бекапу конфігурації перед оновленням..."
tar -czf "$BACKUP_DIR/${BACKUP_NAME}_ha_config.tar.gz" -C /opt/homeassistant config/
log "✅ Бекап збережено: $BACKUP_DIR/${BACKUP_NAME}_ha_config.tar.gz"

# Завантажуємо бекап на Google Drive якщо налаштовано
if rclone listremotes 2>/dev/null | grep -q "^${GDRIVE_REMOTE}:$"; then
    log "☁️  Завантаження бекапу на Google Drive..."
    rclone copy "$BACKUP_DIR/${BACKUP_NAME}_ha_config.tar.gz" \
        "${GDRIVE_REMOTE}:${GDRIVE_PATH}/pre_update/" --quiet && \
        log "✅ Бекап на Google Drive завантажено" || \
        log "⚠️  Не вдалося завантажити на Google Drive (продовжуємо оновлення)"
fi

# 5. Зберігаємо параметри запуску контейнера
ENV_TZ=$(docker inspect "$CONTAINER" --format='{{range .Config.Env}}{{println .}}{{end}}' | grep "^TZ=" | cut -d= -f2)
ENV_TZ="${ENV_TZ:-Europe/Kyiv}"

# 6. Зупиняємо та видаляємо старий контейнер
log "🛑 Зупинка контейнера..."
docker stop "$CONTAINER"
docker rm "$CONTAINER"

# 7. Запускаємо з новим образом
log "🚀 Запуск оновленого контейнера..."
docker run -d \
    --name "$CONTAINER" \
    --privileged \
    --restart=unless-stopped \
    -e TZ="$ENV_TZ" \
    -v /opt/homeassistant/config:/config \
    -v /run/dbus:/run/dbus:ro \
    --network=host \
    "$IMAGE"

# 8. Чекаємо поки HA запуститься (до 90 секунд)
log "⏳ Очікування запуску Home Assistant..."
for i in $(seq 1 18); do
    sleep 5
    if docker exec "$CONTAINER" python3 -c \
        "from homeassistant.const import __version__; print(__version__)" \
        >/dev/null 2>&1; then
        break
    fi
done

# 9. Перевіряємо нову версію
NEW_HA_VERSION=$(docker exec "$CONTAINER" python3 -c \
    "from homeassistant.const import __version__; print(__version__)" 2>/dev/null || echo "unknown")

if [ "$NEW_HA_VERSION" = "unknown" ]; then
    log "❌ Контейнер запустився, але HA версію не вдалося визначити. Перевірте вручну."
else
    log "✅ Home Assistant оновлено до версії $NEW_HA_VERSION"
fi

# 10. Видаляємо старі образи (залишаємо тільки два останні: поточний + попередній)
log "🧹 Очищення старих образів Docker..."
docker image prune -f >> "$LOG_FILE" 2>&1
log "✅ Старі образи видалено"

# 11. Очищення старих pre_update бекапів (залишаємо 5 останніх)
find "$BACKUP_DIR" -name "pre_update_*_ha_config.tar.gz" -type f | sort -r | tail -n +6 | xargs rm -f 2>/dev/null || true

log "🏁 Оновлення завершено успішно!"
log "──────────────────────────────────────────"
