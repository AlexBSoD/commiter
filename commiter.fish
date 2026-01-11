#!/usr/bin/env fish

# Скрипт для генерации текста коммита с помощью Ollama
# Использование: suggest-commit.fish [git-folder] [ollama-server] [model-name] [language]
# Конфигурация: ~/.config/commiter/config

function show_usage
    echo "Использование: suggest-commit.fish [git-folder] [ollama-server] [model-name] [language]"
    echo ""
    echo "Параметры:"
    echo "  git-folder    - Путь к папке с git репозиторием (опционально, по умолчанию ./)"
    echo "  ollama-server - Адрес Ollama сервера (опционально, из конфига или http://localhost:11434)"
    echo "  model-name    - Имя модели на сервере (опционально, из конфига или llama3)"
    echo "  language      - Язык коммита: 'ru' или 'en' (опционально, из конфига или 'en')"
    echo ""
    echo "Конфигурация:"
    echo "  Файл: ~/.config/commiter/config"
    echo "  Параметры командной строки переопределяют значения из конфига"
    echo ""
    echo "Примеры:"
    echo "  suggest-commit.fish                              # использует текущую директорию"
    echo "  suggest-commit.fish /path/to/repo"
    echo "  suggest-commit.fish /path/to/repo http://localhost:11434"
    echo "  suggest-commit.fish /path/to/repo http://localhost:11434 llama3"
    echo "  suggest-commit.fish /path/to/repo http://localhost:11434 llama3 ru"
end

# Функция для чтения конфига
function load_config
    set config_file "$HOME/.config/commiter/config"

    if test -f $config_file
        while read -l line
            # Пропускаем пустые строки и комментарии
            if test -z "$line"; or string match -q "#*" "$line"
                continue
            end

            # Разбираем строки формата KEY=VALUE
            set parts (string split "=" -- $line)
            if test (count $parts) -eq 2
                set key (string trim $parts[1])
                set value (string trim $parts[2])

                switch $key
                    case OLLAMA_SERVER
                        set -g config_ollama_server $value
                    case MODEL_NAME
                        set -g config_model_name $value
                    case LANGUAGE
                        set -g config_language $value
                end
            end
        end < $config_file
    end
end

# Загружаем конфигурацию
load_config

# Проверка количества параметров
set argc (count $argv)
if test $argc -gt 4
    show_usage
    exit 1
end

# git-folder по умолчанию - текущая директория
if test $argc -ge 1
    set git_folder $argv[1]
else
    set git_folder "./"
end

# Определяем значения параметров (приоритет: CLI > config > defaults)
if test $argc -ge 2
    set ollama_server $argv[2]
else if set -q config_ollama_server
    set ollama_server $config_ollama_server
else
    set ollama_server "http://localhost:11434"
end

if test $argc -ge 3
    set model_name $argv[3]
else if set -q config_model_name
    set model_name $config_model_name
else
    set model_name "llama3"
end

if test $argc -eq 4
    set language $argv[4]
else if set -q config_language
    set language $config_language
else
    set language "en"
end

# Проверка корректности языка
if test "$language" != "ru" -a "$language" != "en"
    echo "Ошибка: Язык должен быть 'ru' или 'en'"
    show_usage
    exit 1
end

# Проверка существования папки
if not test -d $git_folder
    echo "Ошибка: Папка '$git_folder' не существует"
    exit 1
end

# Проверка что это git репозиторий
if not test -d $git_folder/.git
    echo "Ошибка: '$git_folder' не является git репозиторием"
    exit 1
end

# Переход в папку репозитория
cd $git_folder
or begin
    echo "Ошибка: Не удалось перейти в папку '$git_folder'"
    exit 1
end

# Получение git diff
echo "Анализирую изменения в репозитории..."
set git_status (git status --short)
set git_diff (git diff --cached)

# Если нет staged изменений, проверяем unstaged
if test -z "$git_diff"
    set git_diff (git diff)
end

# Если вообще нет изменений
if test -z "$git_diff"
    echo "Нет изменений для коммита"
    exit 0
end

# Формирование промпта для модели в зависимости от языка
if test "$language" = "ru"
    set lang_instruction "на русском языке"
    set lang_note "Используй русский язык для текста коммита."
else
    set lang_instruction "на английском языке"
    set lang_note "Use English for the commit message."
end

set prompt "Проанализируй следующие изменения в git репозитории и предложи краткий и информативный текст коммита $lang_instruction в стиле conventional commits (feat:, fix:, docs:, refactor: и т.д.).

Git status:
$git_status

Git diff:
$git_diff

$lang_note
Предложи только текст коммита, без дополнительных объяснений. Текст должен быть кратким (до 72 символов в первой строке) и точно описывать суть изменений."

# Создание JSON для запроса к Ollama
set json_data (jq -n \
    --arg model "$model_name" \
    --arg prompt "$prompt" \
    '{model: $model, prompt: $prompt, stream: false}')

# Отправка запроса к Ollama
echo "Генерирую предложение коммита с помощью $model_name..."
set response (curl -s -X POST "$ollama_server/api/generate" \
    -H "Content-Type: application/json" \
    -d "$json_data")

# Проверка ответа
if test $status -ne 0
    echo "Ошибка: Не удалось подключиться к Ollama серверу"
    exit 1
end

# Извлечение текста коммита из ответа
set commit_message (echo $response | jq -r '.response')

if test -z "$commit_message"
    echo "Ошибка: Не удалось получить ответ от модели"
    exit 1
end

# Вывод результата
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Предложенный текст коммита:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$commit_message"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Для применения выполните:"
echo "  git commit -m \"$commit_message\""
