# Suggest Commit

Скрипт на Fish shell для автоматической генерации текста git коммита с помощью Ollama.

## Возможности

- Анализирует изменения в git репозитории
- Генерирует текст коммита в стиле conventional commits
- Поддерживает русский и английский языки
- Гибкая конфигурация через файл или параметры командной строки

## Зависимости

- `fish` - Fish shell
- `git` - система контроля версий
- `curl` - для HTTP запросов
- `jq` - для работы с JSON
- `ollama` - локальный сервер с языковой моделью

На NixOS установите через:

```nix
environment.systemPackages = with pkgs; [ fish git curl jq ];
```

Или через home-manager:

```nix
home.packages = with pkgs; [ fish git curl jq ];
```

## Установка

1. Скопируйте скрипт в удобное место:

```bash
cp suggest-commit.fish ~/bin/
chmod +x ~/bin/suggest-commit.fish
```

2. Создайте конфигурационный файл:

```bash
mkdir -p ~/.config/commiter
cp config.example ~/.config/commiter/config
```

3. Отредактируйте `~/.config/commiter/config`:

```bash
# Конфигурационный файл для suggest-commit.fish

# Адрес Ollama сервера
OLLAMA_SERVER=http://localhost:11434

# Имя модели
MODEL_NAME=llama3

# Язык коммитов: 'ru' или 'en'
LANGUAGE=en
```

## Использование

### С конфигурационным файлом

После настройки конфига достаточно указать только путь к репозиторию:

```fish
suggest-commit.fish /path/to/repo
```

### С параметрами командной строки

Параметры командной строки переопределяют значения из конфига:

```fish
# Минимальный вариант (используются значения по умолчанию)
suggest-commit.fish /path/to/repo

# Указать адрес сервера
suggest-commit.fish /path/to/repo http://192.168.1.100:11434

# Указать сервер и модель
suggest-commit.fish /path/to/repo http://localhost:11434 mistral

# Указать все параметры, включая язык
suggest-commit.fish /path/to/repo http://localhost:11434 llama3 ru
```

### Приоритет параметров

1. Параметры командной строки (высший приоритет)
2. Значения из файла конфигурации
3. Значения по умолчанию:
   - `OLLAMA_SERVER`: `http://localhost:11434`
   - `MODEL_NAME`: `llama3`
   - `LANGUAGE`: `en`

## Примеры

### Коммит на английском (из текущей папки)

```fish
suggest-commit.fish .
```

### Коммит на русском

```fish
suggest-commit.fish . http://localhost:11434 llama3 ru
```

### С другой моделью

```fish
suggest-commit.fish /path/to/repo http://localhost:11434 mistral
```

## Применение результата

Скрипт выведет предложенный текст коммита и команду для его применения:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Предложенный текст коммита:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
feat: add commit message generation script with ollama integration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Для применения выполните:
  git commit -m "feat: add commit message generation script with ollama integration"
```

## Настройка Ollama

Убедитесь, что Ollama запущена и нужная модель загружена:

```bash
# Запустить Ollama
ollama serve

# Загрузить модель (в другом терминале)
ollama pull llama3

# Проверить доступные модели
ollama list
```

## Лицензия

MIT
