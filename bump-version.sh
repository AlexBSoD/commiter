#!/usr/bin/env bash

# Скрипт для обновления версии проекта
# Использование: ./bump-version.sh <новая_версия>
# Пример: ./bump-version.sh 0.0.3

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Использование: $0 <новая_версия>"
    echo "Пример: $0 0.0.3"
    exit 1
fi

NEW_VERSION="$1"

# Проверка формата версии (semver)
if ! echo "$NEW_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "Ошибка: версия должна быть в формате X.Y.Z (например, 0.0.3)"
    exit 1
fi

echo "Обновление версии до $NEW_VERSION..."

# Обновление VERSION файла
echo "$NEW_VERSION" > VERSION
echo "✓ VERSION обновлен"

# Обновление версии в commiter.py
sed -i "s/^__version__ = .*/__version__ = \"$NEW_VERSION\"/" commiter.py
echo "✓ commiter.py обновлен"

# Обновление версии в flake.nix
sed -i "s/version = \".*\";/version = \"$NEW_VERSION\";/" flake.nix
echo "✓ flake.nix обновлен"

echo ""
echo "Версия успешно обновлена до $NEW_VERSION"
echo ""
echo "Не забудьте:"
echo "  1. Обновить CHANGELOG.md"
echo "  2. Закоммитить изменения: git commit -am \"chore: bump version to $NEW_VERSION\""
echo "  3. Создать git tag: git tag v$NEW_VERSION"
echo "  4. Отправить изменения: git push && git push --tags"
