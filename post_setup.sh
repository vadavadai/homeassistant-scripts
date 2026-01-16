#!/bin/bash

# 🔧 Пост-налаштування після автоматичного розгортання

echo "🔧 Пост-налаштування Home Assistant системи"
echo "============================================"

# Кольори
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Виберіть дії:${NC}"
echo "1. Налаштувати Google Drive (rclone)"
echo "2. Відновити з бекапу Google Drive"
echo "3. Налаштувати Cloudflare тунель"
echo "4. Показати інформацію про систему"
echo "5. Перевірити статус всіх сервісів"
echo "6. Вийти"
echo ""

read -p "Ваш вибір (1-6): " choice

case $choice in
    1)
        echo -e "${GREEN}Запуск налаштування Google Drive...${NC}"
        /root/setup_gdrive.sh
        ;;
    2)
        echo -e "${GREEN}Запуск відновлення з Google Drive...${NC}"
        /root/restore_from_gdrive.sh
        ;;
    3)
        echo -e "${GREEN}Налаштування Cloudflare тунель...${NC}"
        echo "Команди для налаштування:"
        echo "1. cloudflared tunnel login"
        echo "2. cloudflared tunnel create homeassistant-new"
        echo "3. cloudflared tunnel route dns <TUNNEL_ID> yourdomain.com"
        echo "4. Створити конфіг в /root/.cloudflared/config.yml"
        ;;
    4)
        echo -e "${GREEN}Інформація про систему:${NC}"
        cat /root/system_info.txt
        ;;
    5)
        echo -e "${GREEN}Статус сервісів:${NC}"
        echo "=== Docker контейнери ==="
        docker ps
        echo ""
        echo "=== USB пристрої ==="
        ls /dev/ttyUSB* 2>/dev/null || echo "USB пристрої не знайдено"
        echo ""
        echo "=== Bluetooth ==="
        hciconfig 2>/dev/null || echo "Bluetooth не налаштовано"
        echo ""
        echo "=== Мережа ==="
        ip addr show | grep -A 2 "state UP"
        ;;
    6)
        echo "До побачення!"
        exit 0
        ;;
    *)
        echo "Неправильний вибір!"
        exit 1
        ;;
esac