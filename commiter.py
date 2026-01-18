#!/usr/bin/env python3

"""
Скрипт для генерации текста коммита с помощью OpenWebUI
Использует только стандартную библиотеку Python
"""

import argparse
import configparser
import json
import os
import subprocess
import sys
import urllib.request
import urllib.error
from pathlib import Path


def load_config():
    """Загружает конфигурацию из файла ~/.config/commiter/config"""
    config_file = Path.home() / ".config" / "commiter" / "config"
    config = {}

    if config_file.exists():
        parser = configparser.ConfigParser()
        try:
            parser.read(config_file)
            if 'DEFAULT' in parser:
                config = dict(parser['DEFAULT'])
        except Exception as e:
            print(f"Предупреждение: Не удалось прочитать конфиг {config_file}: {e}", file=sys.stderr)

    return config


def get_git_changes(git_folder):
    """Получает git status и git diff для репозитория"""
    try:
        # Проверка что это git репозиторий
        git_dir = Path(git_folder) / ".git"
        if not git_dir.exists():
            print(f"Ошибка: '{git_folder}' не является git репозиторием", file=sys.stderr)
            sys.exit(1)

        # Git status
        status_result = subprocess.run(
            ["git", "-C", git_folder, "status", "--short"],
            capture_output=True,
            text=True,
            check=True
        )
        git_status = status_result.stdout

        # Git diff (сначала проверяем staged изменения)
        diff_result = subprocess.run(
            ["git", "-C", git_folder, "diff", "--cached"],
            capture_output=True,
            text=True,
            check=True
        )
        git_diff = diff_result.stdout

        # Если нет staged изменений, проверяем unstaged
        if not git_diff.strip():
            diff_result = subprocess.run(
                ["git", "-C", git_folder, "diff"],
                capture_output=True,
                text=True,
                check=True
            )
            git_diff = diff_result.stdout

        return git_status, git_diff

    except subprocess.CalledProcessError as e:
        print(f"Ошибка при выполнении git команды: {e}", file=sys.stderr)
        sys.exit(1)


def generate_commit_message(api_url, api_token, model, language, git_status, git_diff):
    """Генерирует текст коммита используя OpenWebUI API"""

    # Формирование промпта в зависимости от языка
    if language == "ru":
        lang_instruction = "на русском языке"
        lang_note = "Используй русский язык для текста коммита."
    else:
        lang_instruction = "на английском языке"
        lang_note = "Use English for the commit message."

    prompt = f"""Проанализируй следующие изменения в git репозитории и предложи краткий и информативный текст коммита {lang_instruction} в стиле conventional commits (feat:, fix:, docs:, refactor: и т.д.).

Git status:
{git_status}

Git diff:
{git_diff}

{lang_note}
Предложи только текст коммита, без дополнительных объяснений. Текст должен быть кратким (до 72 символов в первой строке) и точно описывать суть изменений."""

    # Формирование запроса в формате OpenAI API
    request_data = {
        "model": model,
        "messages": [
            {
                "role": "user",
                "content": prompt
            }
        ],
        "stream": False
    }

    # Подготовка HTTP запроса
    url = f"{api_url.rstrip('/')}/api/v1/chat/completions"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_token}"
    }

    try:
        req = urllib.request.Request(
            url,
            data=json.dumps(request_data).encode('utf-8'),
            headers=headers,
            method='POST'
        )

        print(f"Генерирую предложение коммита с помощью {model}...")

        with urllib.request.urlopen(req) as response:
            response_data = json.loads(response.read().decode('utf-8'))

        # Извлечение текста коммита из ответа
        if 'choices' in response_data and len(response_data['choices']) > 0:
            commit_message = response_data['choices'][0]['message']['content'].strip()
            return commit_message
        else:
            print("Ошибка: Неожиданный формат ответа от API", file=sys.stderr)
            return None

    except urllib.error.HTTPError as e:
        error_body = e.read().decode('utf-8')
        print(f"Ошибка HTTP {e.code}: {e.reason}", file=sys.stderr)
        print(f"Детали: {error_body}", file=sys.stderr)
        return None
    except urllib.error.URLError as e:
        print(f"Ошибка подключения к API: {e.reason}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"Неожиданная ошибка при запросе к API: {e}", file=sys.stderr)
        return None


def copy_to_clipboard(text):
    """Копирует текст в буфер обмена"""
    clipboard_commands = [
        ['wl-copy'],
        ['xclip', '-selection', 'clipboard'],
        ['xsel', '--clipboard', '--input']
    ]

    for cmd in clipboard_commands:
        try:
            # Используем Popen для запуска в фоне без ожидания завершения
            proc = subprocess.Popen(
                cmd,
                stdin=subprocess.PIPE,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            proc.stdin.write(text.encode('utf-8'))
            proc.stdin.close()
            # Не ждем завершения процесса - он продолжит работать в фоне
            return cmd[0]
        except (OSError, FileNotFoundError):
            continue

    return None


def main():
    # Загружаем конфигурацию
    config = load_config()

    # Парсинг аргументов командной строки
    parser = argparse.ArgumentParser(
        description='Генерация текста коммита с помощью OpenWebUI',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Конфигурация:
  Файл: ~/.config/commiter/config
  Формат: INI (configparser)

  Пример содержимого:
  [DEFAULT]
  api_url = https://your-openwebui.com
  api_token = your-api-token-here
  model = llama3.2
  language = en

  Параметры командной строки переопределяют значения из конфига.
        """
    )

    parser.add_argument(
        '--git-folder',
        default=config.get('git_folder', './'),
        help='Путь к папке с git репозиторием (по умолчанию: ./)'
    )

    parser.add_argument(
        '--api-url',
        default=config.get('api_url'),
        help='URL OpenWebUI API (обязательный, если не указан в конфиге)'
    )

    parser.add_argument(
        '--api-token',
        default=config.get('api_token'),
        help='Токен доступа к OpenWebUI API (обязательный, если не указан в конфиге)'
    )

    parser.add_argument(
        '--model',
        default=config.get('model', 'llama3.2'),
        help='Имя модели (по умолчанию: llama3.2)'
    )

    parser.add_argument(
        '--language',
        choices=['ru', 'en'],
        default=config.get('language', 'en'),
        help='Язык коммита: ru или en (по умолчанию: en)'
    )

    args = parser.parse_args()

    # Проверка обязательных параметров
    if not args.api_url:
        print("Ошибка: Не указан --api-url (или api_url в конфиге)", file=sys.stderr)
        sys.exit(1)

    if not args.api_token:
        print("Ошибка: Не указан --api-token (или api_token в конфиге)", file=sys.stderr)
        sys.exit(1)

    # Проверка существования папки
    if not os.path.isdir(args.git_folder):
        print(f"Ошибка: Папка '{args.git_folder}' не существует", file=sys.stderr)
        sys.exit(1)

    # Получение изменений из git
    print("Анализирую изменения в репозитории...")
    git_status, git_diff = get_git_changes(args.git_folder)

    # Проверка наличия изменений
    if not git_diff.strip():
        print("Нет изменений для коммита")
        sys.exit(0)

    # Генерация текста коммита
    commit_message = generate_commit_message(
        args.api_url,
        args.api_token,
        args.model,
        args.language,
        git_status,
        git_diff
    )

    if not commit_message:
        print("Ошибка: Не удалось получить текст коммита", file=sys.stderr)
        sys.exit(1)

    # Вывод результата
    print()
    print("━" * 50)
    print("Предложенный текст коммита:")
    print("━" * 50)
    print(commit_message)
    print("━" * 50)
    print()
    print("Для применения выполните:")

    # Формирование команды git commit
    if '\n' in commit_message:
        git_command = f"git commit -m \"$(cat <<'EOF'\n{commit_message}\nEOF\n)\""
    else:
        git_command = f'git commit -m "{commit_message}"'

    print(f"  {git_command}")

    # Копирование в буфер обмена
    clipboard_tool = copy_to_clipboard(git_command)
    if clipboard_tool:
        print()
        print(f"Команда скопирована в буфер обмена ({clipboard_tool})")


if __name__ == "__main__":
    main()
