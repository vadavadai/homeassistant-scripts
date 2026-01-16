#!/bin/bash

# 🚀 Автоматичне розгортання Home Assistant системи на Orange Pi
# Враховує всі проблеми: Zigbee, Bluetooth, Docker, Matter, Cloudflare

set -e  # Зупинка при помилках

echo "🍊 Автоматичне розгортання Home Assistant на Orange Pi"
echo "========================================================"

# Кольори для виводу
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 1. ОНОВЛЕННЯ СИСТЕМИ
log_info "Оновлення системи..."
export DEBIAN_FRONTEND=noninteractive
apt update && apt upgrade -y
apt install -y curl wget git jq nano htop

log_success "Система оновлена"

# 2. ВСТАНОВЛЕННЯ DOCKER
log_info "Встановлення Docker..."
curl -fsSL https://get.docker.com | sh
usermod -aG docker $USER
systemctl enable docker
systemctl start docker

log_success "Docker встановлено"

# 3. ВИПРАВЛЕННЯ ZIGBEE USB (ВІДКЛЮЧЕННЯ BRLTTY)
log_info "Налаштування Zigbee USB (відключення brltty)..."
systemctl stop brltty-udev.service 2>/dev/null || true
systemctl disable brltty-udev.service 2>/dev/null || true
systemctl stop brltty.service 2>/dev/null || true
systemctl disable brltty.service 2>/dev/null || true
systemctl mask brltty.service 2>/dev/null || true

# Видаляємо brltty правила udev
rm -f /lib/udev/rules.d/90-brltty-udev.rules 2>/dev/null || true
rm -f /lib/udev/rules.d/90-brltty-device-detection.rules 2>/dev/null || true

# Перезавантажуємо udev
udevadm control --reload-rules
udevadm trigger

log_success "Zigbee USB налаштовано"

# 4. НАЛАШТУВАННЯ BLUETOOTH
log_info "Налаштування Bluetooth..."
apt install -y bluetooth bluez bluez-tools
systemctl enable bluetooth
systemctl start bluetooth

# Перевіряємо Bluetooth адаптер
if hciconfig | grep -q "hci0"; then
    log_success "Bluetooth адаптер знайдено"
else
    log_warning "Bluetooth адаптер не знайдено - перевірте антену WiFi/BT"
fi

# 5. СТВОРЕННЯ ДИРЕКТОРІЙ
log_info "Створення директорій для даних..."
mkdir -p /opt/homeassistant/config
mkdir -p /opt/matter-server
mkdir -p /opt/backups
mkdir -p /opt/restore

log_success "Директорії створено"

# 6. ВСТАНОВЛЕННЯ CLOUDFLARED
log_info "Встановлення Cloudflared..."
if [ "$(uname -m)" = "aarch64" ]; then
    ARCH="arm64"
else
    ARCH="amd64"
fi

wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH} -O /usr/bin/cloudflared
chmod +x /usr/bin/cloudflared

log_success "Cloudflared встановлено"

# 7. ВСТАНОВЛЕННЯ RCLONE
log_info "Встановлення rclone для Google Drive..."
curl -s https://rclone.org/install.sh | bash

log_success "rclone встановлено"

# 8. ЗАПУСК MATTER SERVER
log_info "Запуск Matter Server..."
docker run -d \
  --name matter-server \
  --restart=unless-stopped \
  --security-opt apparmor=unconfined \
  --network host \
  -v /opt/matter-server:/data \
  -v /run/dbus:/run/dbus:ro \
  ghcr.io/home-assistant-libs/python-matter-server:stable

log_success "Matter Server запущено"

# 9. ЗАПУСК HOME ASSISTANT
log_info "Запуск Home Assistant..."
docker run -d \
  --name homeassistant \
  --privileged \
  --restart=unless-stopped \
  --network host \
  -e TZ=Europe/Kyiv \
  -v /opt/homeassistant/config:/config \
  -v /run/dbus:/run/dbus:ro \
  --device-cgroup-rule='c 166:* rmw' \
  ghcr.io/home-assistant/home-assistant:stable

log_success "Home Assistant запущено"

# 10. ПЕРЕВІРКА USB ПРИСТРОЇВ
log_info "Перевірка USB пристроїв..."
sleep 10
if ls /dev/ttyUSB* 2>/dev/null; then
    log_success "USB пристрої знайдено:"
    ls -la /dev/ttyUSB*
else
    log_warning "USB пристрої не знайдено - можливо Zigbee адаптер не підключений"
fi

# 11. СТВОРЕННЯ ТА ЗАВАНТАЖЕННЯ СКРИПТІВ БЕКАПУ
log_info "Завантаження та налаштування скриптів бекапу..."

# Базовий URL для скриптів
GITHUB_BASE="https://raw.githubusercontent.com/vadavadai/homeassistant-scripts/main"

# Завантажуємо скрипти з GitHub
wget -q "${GITHUB_BASE}/full_backup.sh" -O /root/full_backup.sh
wget -q "${GITHUB_BASE}/setup_gdrive.sh" -O /root/setup_gdrive.sh  
wget -q "${GITHUB_BASE}/restore_from_gdrive.sh" -O /root/restore_from_gdrive.sh
wget -q "${GITHUB_BASE}/post_setup.sh" -O /root/post_setup.sh

# Робимо скрипти виконуваними
chmod +x /root/*.sh

log_success "Скрипти бекапу завантажено та налаштовано"

# 12. НАЛАШТУВАННЯ АВТОЗАПУСКУ CRON
log_info "Налаштування автоматичних бекапів..."
(crontab -l 2>/dev/null; echo "0 2 * * * /root/full_backup.sh >> /var/log/backup.log 2>&1") | crontab -

log_success "Автоматичні бекапи налаштовано"

# 13. СТВОРЕННЯ СКРИПТУ ВІДНОВЛЕННЯ
cat > /root/quick_restore.sh << 'RESTORE_EOF'
#!/bin/bash
echo "🔄 Швидке відновлення з Google Drive"
echo "1. Налаштуйте Google Drive: /root/setup_gdrive.sh"
echo "2. Відновіть дані: /root/restore_from_gdrive.sh"
echo "3. Перезапустіть контейнери: docker restart homeassistant matter-server"
RESTORE_EOF
chmod +x /root/quick_restore.sh

# 14. ФІНАЛЬНІ ПЕРЕВІРКИ
log_info "Фінальні перевірки..."

# Перевірка Docker контейнерів
sleep 15
if docker ps | grep -q homeassistant && docker ps | grep -q matter-server; then
    log_success "Всі контейнери працюють"
else
    log_warning "Деякі контейнери можуть ще запускатися"
fi

# Створення інформаційного файлу
cat > /root/system_info.txt << INFO_EOF
🍊 Orange Pi Home Assistant - Інформація про систему
====================================================

📅 Дата встановлення: $(date)
🐳 Docker версія: $(docker --version)
📍 IP адреса: $(hostname -I | awk '{print $1}')

📱 Доступ до Home Assistant:
   Локально: http://$(hostname -I | awk '{print $1}'):8123
   
🔧 Корисні команди:
   Логи HA: docker logs homeassistant
   Логи Matter: docker logs matter-server
   Перезапуск: docker restart homeassistant matter-server
   Бекап: /root/full_backup.sh
   Відновлення: /root/quick_restore.sh

📊 Статус контейнерів:
$(docker ps --format "table {{.Names}}\t{{.Status}}")

🔌 USB пристрої:
$(ls /dev/ttyUSB* 2>/dev/null || echo "Не знайдено")

📡 Bluetooth:
$(hciconfig 2>/dev/null | head -5 || echo "Не налаштовано")

INFO_EOF

echo ""
echo "🎉 РОЗГОРТАННЯ ЗАВЕРШЕНО!"
echo "========================"
echo ""
log_success "Home Assistant доступний за адресою: http://$(hostname -I | awk '{print $1}'):8123"
echo ""
echo "📋 Наступні кроки:"
echo "1. Налаштуйте Google Drive: /root/setup_gdrive.sh"
echo "2. Відновіть дані з бекапу: /root/restore_from_gdrive.sh"
echo "3. Налаштуйте Cloudflare тунель для зовнішнього доступу"
echo "4. Додайте Zigbee/Matter пристрої"
echo ""
echo "📖 Інформація про систему збережена в: /root/system_info.txt"
echo ""
log_info "Система готова до використання! 🚀"