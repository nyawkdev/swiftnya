#!/usr/bin/env bash
set -e

echo "=== Синхронизация Telegram-iOS с апстримом Swiftgram ==="

if ! git remote | grep -q "^upstream$"; then
    echo "Добавляем remote upstream..."
    git remote add upstream https://github.com/Swiftgram/Telegram-iOS.git
fi

echo "Получение последних обновлений из upstream/master..."
git fetch upstream master

echo "Объединение обновлений в папку Telegram-iOS..."
git subtree pull --prefix=Telegram-iOS upstream master --squash -m "Merge upstream Swiftgram/Telegram-iOS updates"

echo ""
echo "=== Синхронизация успешно завершена! ==="
echo "Не забудьте отправить изменения: git push origin main"
