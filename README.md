# 🍊 Orange Pi Home Assistant - Автоматичне розгортання

Повний набір скриптів для автоматичного розгортання Home Assistant на Orange Pi Zero 3 з підтримкою Zigbee, Bluetooth, Matter та Cloudflare тунелів.

## 🚀 Швидкий старт

### 1. Після встановлення чистого Debian запустіть:

```bash
wget -O - https://raw.githubusercontent.com/vadavadai/homeassistant-scripts/main/auto_deploy.sh | bash
```

### 2. Пост-налаштування:

```bash
wget -O /root/post_setup.sh https://raw.githubusercontent.com/vadavadai/homeassistant-scripts/main/post_setup.sh
chmod +x /root/post_setup.sh
/root/post_setup.sh
```

## 📋 Що включено

### 🔧 Основні скрипти:
- **`auto_deploy.sh`** - Повне автоматичне розгортання системи
- **`post_setup.sh`** - Інтерактивне меню пост-налаштування  
- **`full_backup.sh`** - Повний бекап з завантаженням на Google Drive
- **`setup_gdrive.sh`** - Налаштування Google Drive (rclone)
- **`restore_from_gdrive.sh`** - Відновлення з Google Drive бекапу

### ✅ Що налаштовується автоматично:
- **Docker** + контейнери (HA, Matter Server)
- **Zigbee USB** - виправлення конфлікту з brltty
- **Bluetooth** - повне налаштування
- **Matter Server** - з правильною мережею  
- **Cloudflared** - для зовнішнього доступу
- **rclone** - для Google Drive бекапів
- **Автоматичні бекапи** - щоночі о 2:00

## 🔧 Ручне встановлення

Якщо потрібно завантажити скрипти окремо:

```bash
# Основне розгортання
wget https://raw.githubusercontent.com/vadavadai/homeassistant-scripts/main/auto_deploy.sh
chmod +x auto_deploy.sh
./auto_deploy.sh

# Додаткові скрипти
wget https://raw.githubusercontent.com/vadavadai/homeassistant-scripts/main/full_backup.sh
wget https://raw.githubusercontent.com/vadavadai/homeassistant-scripts/main/setup_gdrive.sh
wget https://raw.githubusercontent.com/vadavadai/homeassistant-scripts/main/restore_from_gdrive.sh
wget https://raw.githubusercontent.com/vadavadai/homeassistant-scripts/main/post_setup.sh

chmod +x *.sh
```

## 📱 Доступ до Home Assistant

Після успішного розгортання:
- **Локально**: `http://IP_ADDRESS:8123`
- **Зовні**: Налаштуйте Cloudflare тунель для зовнішнього доступу

## 🔄 Бекапи та відновлення

### Автоматичні бекапи:
- Створюються щоночі о 2:00
- Завантажуються на Google Drive
- Включають: HA конфіг, Matter дані, Cloudflare налаштування

### Відновлення:
```bash
/root/restore_from_gdrive.sh
```

## 🛠️ Вирішені проблеми

- ✅ **Zigbee USB конфлікт** - автоматично відключає brltty
- ✅ **Bluetooth проблеми** - правильне налаштування драйверів  
- ✅ **Matter мережеві помилки** - використання host network
- ✅ **Docker привілеї** - правильні права для USB/Bluetooth
- ✅ **Повільна microSD** - рекомендації з оптимізації

## 📊 Системні вимоги

- **Orange Pi Zero 3** (або сумісні)
- **Debian 12** (Bookworm) 
- **microSD карта** мін. 16GB (рекомендуємо 64GB Class 10)
- **Zigbee USB адаптер** (Silicon Labs CP210x)
- **Інтернет з'єднання**

## 🆘 Підтримка

Якщо виникли проблеми:
1. Перевірте логи: `docker logs homeassistant`
2. Статус системи: `/root/post_setup.sh`
3. Перевірте USB: `ls /dev/ttyUSB*`
4. Bluetooth: `hciconfig`

## 📝 Журнал змін

### v1.0.0
- Початковий релиз
- Повне автоматичне розгортання
- Підтримка всіх основних компонентів
- Google Drive бекапи