#!/bin/bash

# Скрипт для автоматичної перевірки оновлень Home Assistant
# Надсилає повідомлення тільки при наявності оновлень

LOG_FILE="/opt/homeassistant/homeassistant-scripts/update_check.log"
WEBHOOK_URL=""  # Додайте ваш webhook URL якщо потрібні сповіщення

echo "$(date): Перевірка оновлень Home Assistant..." >> $LOG_FILE

# Перевіряємо нову версію
docker pull ghcr.io/home-assistant/home-assistant:stable --quiet

# Порівнюємо версії
NEW_DIGEST=$(docker inspect ghcr.io/home-assistant/home-assistant:stable --format='{{.Id}}')
OLD_DIGEST=$(docker inspect homeassistant --format='{{.Image}}')

if [ "$NEW_DIGEST" != "$OLD_DIGEST" ]; then
    MESSAGE="🎉 Доступна нова версія Home Assistant! Поточна: $(echo $OLD_DIGEST | cut -c 1-12), Нова: $(echo $NEW_DIGEST | cut -c 1-12)"
    echo "$(date): $MESSAGE" >> $LOG_FILE
    
    # Відправка в Home Assistant через webhook (опціонально)
    if [ -n "$WEBHOOK_URL" ]; then
        curl -X POST -H "Content-Type: application/json" \
             -d "{\"message\":\"$MESSAGE\",\"title\":\"Home Assistant Update\"}" \
             "$WEBHOOK_URL" &>/dev/null
    fi
    
    # Відправка через ntfy (опціонально)
    # curl -d "$MESSAGE" ntfy.sh/your-topic &>/dev/null
else
    echo "$(date): Оновлень немає" >> $LOG_FILE
fi