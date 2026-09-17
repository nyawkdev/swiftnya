# Swiftnya Monorepo (Telegram iOS / Swiftgram)

Закрытый репозиторий с интеграцией исходного кода **[Swiftgram/Telegram-iOS](https://github.com/Swiftgram/Telegram-iOS)**, дополнительными модулями и автоматической сборкой `.ipa` через GitHub Actions.

---

## Структура репозитория

```text
swiftnya/
├── .github/
│   └── workflows/
│       └── build.yml          # GitHub Actions workflow для сборки .ipa на macOS
├── Telegram-iOS/              # Исходный код Swiftgram (подключен как git subtree)
├── modules/                   # Папка для ваших дополнительных модулей/файлов
├── scripts/
│   ├── sync-upstream.ps1      # Скрипт обновления Telegram-iOS для Windows (PowerShell)
│   └── sync-upstream.sh       # Скрипт обновления для Linux / macOS
├── .gitignore
└── README.md
```

---

## 1. Внесение изменений в код

- Весь исходный код Telegram iOS находится в папке `Telegram-iOS/`.
- Вы можете свободно изменять любые файлы, добавлять функции и делать коммиты:
  ```powershell
  git add .
  git commit -m "My custom feature"
  git push origin main
  ```
- Репозиторий является закрытым (Private), поэтому ваш код и изменения видны только вам.

---

## 2. Синхронизация с официальным репозиторием (Upstream)

Когда в Swiftgram выходят обновления или новые версии Telegram, вы можете подтянуть их **только в папку `Telegram-iOS/`**, не затрагивая остальные папки.

### На Windows:
Запустите PowerShell-скрипт:
```powershell
.\scripts\sync-upstream.ps1
```

### На macOS / Linux:
```bash
./scripts/sync-upstream.sh
```

*(Под капотом скрипт выполняет `git subtree pull --prefix=Telegram-iOS upstream master --squash`).*

После проверки отправьте обновленный код на GitHub:
```bash
git push origin main
```

---

## 3. Сборка .IPA через GitHub Actions (без Mac)

Так как вы работаете на Windows 11, компиляция приложения настроена в облаке на раннерах Apple Silicon macOS:

1. Откройте ваш репозиторий на GitHub:  
   **[https://github.com/nyawkdev/swiftnya/actions](https://github.com/nyawkdev/swiftnya/actions)**
2. В левой колонке выберите workflow **"Build Telegram iOS IPA"**.
3. Нажмите кнопку **"Run workflow"** справа.
4. Оставьте флажок создания релиза включенным и нажмите зеленую кнопку **"Run workflow"**.
5. Процесс компиляции займет некоторое время.
6. По завершении:
   - Внизу страницы запуска сборки в блоке **Artifacts** появится файл `Telegram-...` для прямого скачивания `.ipa`.
   - В разделе **Releases** ([страница релизов](https://github.com/nyawkdev/swiftnya/releases)) будет создан релиз с прикрепленным `Telegram.ipa`.

Файл `.ipa` собирается с fake-codesigning и готов для установки через:
- AltStore / AltServer
- Sideloadly
- TrollStore
- LiveContainer
- Сервисы персонального подписания (Scarlet, ESign и т.д.)
