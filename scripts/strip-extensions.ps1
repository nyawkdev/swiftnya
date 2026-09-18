# Скрипт для удаления App Extensions (папки PlugIns) из .ipa файла.
# Это устраняет ошибку SideStore "Mismatched bundle IDs" и позволяет установить Telegram на бесплатный Apple ID.

param(
    [Parameter(Mandatory=$false)]
    [string]$IpaPath = ""
)

if (-not $IpaPath) {
    # Ищем любой .ipa в текущей директории или в папке Загрузки
    $downloads = [System.IO.Path]::Combine($env:USERPROFILE, "Downloads")
    $found = Get-ChildItem -Path . , $downloads -Filter "*.ipa" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $IpaPath = $found.FullName
        Write-Host "Найден файл IPA: $IpaPath" -ForegroundColor Cyan
    } else {
        Write-Host "Использование: .\scripts\strip-extensions.ps1 -IpaPath 'путь_к_файлу.ipa'" -ForegroundColor Yellow
        exit 1
    }
}

if (-not (Test-Path $IpaPath)) {
    Write-Host "Файл не найден: $IpaPath" -ForegroundColor Red
    exit 1
}

$directory = [System.IO.Path]::GetDirectoryName((Resolve-Path $IpaPath).Path)
$filename = [System.IO.Path]::GetFileNameWithoutExtension($IpaPath)
$outputIpa = Join-Path $directory "$filename-no-plugins.ipa"

Write-Host "Обработка: $IpaPath -> $outputIpa" -ForegroundColor Green

python -c @"
import zipfile, sys

source = r'$IpaPath'
target = r'$outputIpa'

print('Чтение исходного архива...')
with zipfile.ZipFile(source, 'r') as zin, zipfile.ZipFile(target, 'w', compression=zipfile.ZIP_DEFLATED) as zout:
    removed_count = 0
    kept_count = 0
    for item in zin.infolist():
        # Пропускаем все файлы из папки PlugIns и Watch
        if '/PlugIns/' in item.filename or item.filename.endswith('/PlugIns') or '/Watch/' in item.filename:
            removed_count += 1
            continue
        buffer = zin.read(item.filename)
        zout.writestr(item, buffer)
        kept_count += 1

print(f'Готово! Удалено {removed_count} файлов расширений, сохранено {kept_count} файлов.')
"@

if (Test-Path $outputIpa) {
    Write-Host "`nУспешно создан оптимизированный билд:`n$outputIpa" -ForegroundColor Green
    Write-Host "Теперь установите этот файл через SideStore или LiveContainer!" -ForegroundColor Cyan
} else {
    Write-Host "Произошла ошибка при создании файла." -ForegroundColor Red
}
