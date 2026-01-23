# Commiter

Скрипт на Python для автоматической генерации текста git коммита с помощью OpenWebUI.

## Возможности

- Анализирует изменения в git репозитории
- Генерирует текст коммита в стиле conventional commits
- Поддерживает русский и английский языки
- Гибкая конфигурация через файл или параметры командной строки
- Работает с OpenWebUI через интернет
- Использует только стандартную библиотеку Python (нет внешних зависимостей)

## Требования

- Python 3.6+
- `git` - система контроля версий
- Доступ к OpenWebUI серверу и API токен

## Установка

### NixOS / Nix Flakes (рекомендуется)

Проект предоставляет Nix flake для удобной установки через home-manager:

```nix
# В вашем home.nix
home.packages = [
  (builtins.getFlake "github:yourusername/commiter").packages.${pkgs.system}.default
];
```

Подробная инструкция по установке через home-manager: [INSTALL.md](INSTALL.md)

### Ручная установка

1. Скопируйте скрипт в удобное место:

```bash
cp commiter.py ~/bin/commiter
chmod +x ~/bin/commiter
```

2. Создайте конфигурационный файл:

```bash
mkdir -p ~/.config/commiter
cp config.example ~/.config/commiter/config
```

3. Отредактируйте `~/.config/commiter/config`:

```ini
[DEFAULT]
# URL вашего OpenWebUI сервера
api_url = https://your-openwebui.com

# Токен доступа к OpenWebUI API
# Получить можно в: Settings -> Account -> API Keys
api_token = your-api-token-here

# Название модели
model = llama3.2

# Язык коммитов: ru или en
language = en
```

### Получение API токена в OpenWebUI

1. Откройте ваш OpenWebUI в браузере
2. Перейдите в Settings (Настройки)
3. Откройте раздел Account (Аккаунт)
4. Найдите секцию API Keys
5. Создайте новый API ключ и скопируйте его в конфиг

## Использование

### Базовое использование

После настройки конфига просто запустите скрипт в папке с git репозиторием:

```bash
commiter
```

### С параметрами командной строки

Параметры командной строки переопределяют значения из конфига:

```bash
# Указать путь к репозиторию
commiter --git-folder /path/to/repo

# Указать модель
commiter --model qwen2.5-coder:7b

# Указать язык коммита
commiter --language ru

# Использовать другой API URL (переопределяет конфиг)
commiter --api-url https://another-openwebui.com --api-token your-token

# Комбинирование параметров
commiter --git-folder /path/to/repo --model llama3.2 --language ru
```

### Справка по параметрам

```bash
commiter --help
```

### Приоритет параметров

1. Параметры командной строки (высший приоритет)
2. Значения из файла конфигурации `~/.config/commiter/config`
3. Значения по умолчанию:
   - `git_folder`: `./` (текущая директория)
   - `model`: `llama3.2`
   - `language`: `en`

## Примеры

### Коммит на английском (из текущей папки)

```bash
commiter
```

### Коммит на русском

```bash
commiter --language ru
```

### С другой моделью

```bash
commiter --model deepseek-r1:7b
```

### Для другого репозитория

```bash
commiter --git-folder /path/to/another/repo --language ru
```

## Применение результата

Скрипт выведет предложенный текст коммита и команду для его применения:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Предложенный текст коммита:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
feat: add OpenWebUI integration with Python rewrite
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Для применения выполните:
  git commit -m "feat: add OpenWebUI integration with Python rewrite"

Команда скопирована в буфер обмена (wl-copy)
```

Команда автоматически копируется в буфер обмена (поддерживаются `wl-copy`, `xclip`, `xsel`).

## Доступные модели

Используйте любые модели, доступные в вашем OpenWebUI:

- `llama3.2` - быстрая и качественная модель
- `qwen2.5-coder:7b` - специализирована для кода
- `deepseek-r1:7b` - хорошо понимает код
- И любые другие модели из вашего OpenWebUI

## Лицензия

MIT
