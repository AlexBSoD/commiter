# Changelog

Все значимые изменения в этом проекте будут документированы в этом файле.

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.0.0/),
и этот проект придерживается [Semantic Versioning](https://semver.org/lang/ru/).

## [0.0.2] - 2026-01-23

### Добавлено
- Nix flake для установки через NixOS home-manager
- Файл VERSION для отслеживания версий
- Флаг `--version` для отображения версии
- Файл INSTALL.md с подробной инструкцией по установке через home-manager
- Файл home-manager-example.nix с примером конфигурации
- Автоматическое добавление зависимостей (git, wl-clipboard, xclip, xsel) в PATH
- Development shell для разработки

### Изменено
- README.md обновлен с информацией о Nix flake
- .gitignore дополнен записями для Nix (result, result-*, .direnv/)

## [0.0.1] - 2026-01-23

### Добавлено
- Начальная версия проекта
- Скрипт на Python для генерации коммитов с помощью OpenWebUI
- Поддержка русского и английского языков
- Конфигурация через файл ~/.config/commiter/config
- Поддержка параметров командной строки
- Копирование результата в буфер обмена
- Обработка git diff для staged и unstaged изменений
- Таймауты для API запросов
- Обработка ошибок git и API

[0.0.2]: https://github.com/yourusername/commiter/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/yourusername/commiter/releases/tag/v0.0.1
