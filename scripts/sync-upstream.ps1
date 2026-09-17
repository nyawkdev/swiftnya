# PowerShell script to synchronize Telegram-iOS with upstream Swiftgram/Telegram-iOS

Write-Host "=== Синхронизация Telegram-iOS с апстримом Swiftgram ===" -ForegroundColor Cyan

# 1. Проверяем наличие удаленного репозитория upstream
$remotes = git remote
if ($remotes -notcontains "upstream") {
    Write-Host "Добавляем remote upstream (https://github.com/Swiftgram/Telegram-iOS.git)..." -ForegroundColor Yellow
    git remote add upstream https://github.com/Swiftgram/Telegram-iOS.git
}

# 2. Подтягиваем свежие данные из upstream
Write-Host "Получение последних обновлений из upstream/master..." -ForegroundColor Yellow
git fetch upstream master
if ($LASTEXITCODE -ne 0) {
    Write-Host "Ошибка при выполнении git fetch upstream!" -ForegroundColor Red
    exit $LASTEXITCODE
}

# 3. Выполняем git subtree pull
Write-Host "Объединение обновлений в папку Telegram-iOS..." -ForegroundColor Yellow
git subtree pull --prefix=Telegram-iOS upstream master --squash -m "Merge upstream Swiftgram/Telegram-iOS updates"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Внимание: возникли конфликты при слиянии или ошибка git subtree pull." -ForegroundColor Red
    Write-Host "Пожалуйста, разрешите конфликты вручную и закоммитьте результат." -ForegroundColor Yellow
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "=== Синхронизация успешно завершена! ===" -ForegroundColor Green
Write-Host "Не забудьте отправить обновления в ваш репозиторий: git push origin main" -ForegroundColor Cyan
