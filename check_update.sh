#!/bin/bash

echo "🔍 Перевірка оновлень Home Assistant..."

# Отримуємо поточну версію
CURRENT_IMAGE=$(docker inspect homeassistant --format='{{.Image}}')
CURRENT_DIGEST=$(docker inspect homeassistant --format='{{.Image}}' | cut -d'@' -f2 2>/dev/null || echo "local")

echo "📦 Поточний образ: $CURRENT_IMAGE"

# Перевіряємо наявність нової версії
echo "🌐 Перевіряємо нову версію..."
docker pull ghcr.io/home-assistant/home-assistant:stable --quiet

# Порівнюємо digest'и
NEW_DIGEST=$(docker inspect ghcr.io/home-assistant/home-assistant:stable --format='{{.Id}}')
OLD_DIGEST=$(docker inspect homeassistant --format='{{.Image}}')

if [ "$NEW_DIGEST" != "$OLD_DIGEST" ]; then
    echo "🎉 Доступна нова версія!"
    echo "Поточна: $OLD_DIGEST"
    echo "Нова: $NEW_DIGEST"
    echo ""
    echo "Для оновлення виконайте:"
    echo "  docker stop homeassistant"
    echo "  docker rm homeassistant"
    echo "  docker run -d --name homeassistant --privileged --restart=unless-stopped -e TZ=Europe/Kiev -v /opt/homeassistant/config:/config -v /run/dbus:/run/dbus:ro --network=host ghcr.io/home-assistant/home-assistant:stable"
else
    echo "✅ Ви використовуєте найновішу версію!"
fi