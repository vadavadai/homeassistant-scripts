#!/bin/bash

echo "🔧 Налаштування Google Drive для автоматичних бекапів"
echo ""
echo "Зараз відкриється конфігурація rclone."
echo "Виберіть:"
echo "1. New remote -> введіть: gdrive"
echo "2. Storage -> виберіть: drive (Google Drive)"
echo "3. Client ID/Secret -> натисніть Enter (використаємо стандартні)"
echo "4. Scope -> виберіть: 1 (read/write access)"
echo "5. Use web browser -> виберіть: N (No)"
echo "6. Скопіюйте URL і відкрийте в браузері"
echo "7. Авторизуйтесь в Google і скопіюйте код"
echo "8. Вставте код в термінал"
echo "9. Team Drive -> натисніть Enter"
echo "10. Confirm -> Y"
echo ""
echo "Натисніть Enter для продовження..."
read

rclone config