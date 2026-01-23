# Установка через NixOS home-manager

Этот проект предоставляет Nix flake для удобной установки через home-manager.

## Быстрый старт

### Вариант 1: Установка из локальной директории (для разработки)

В вашем `home.nix` или модуле home-manager добавьте:

```nix
{ config, pkgs, ... }:

{
  home.packages = [
    (builtins.getFlake "path:/home/uzz/projects/commiter").packages.${pkgs.system}.default
  ];
}
```

### Вариант 2: Установка через flake inputs (рекомендуется для продакшена)

1. В `flake.nix` вашей системы добавьте commiter в inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";

    # Добавьте commiter
    commiter = {
      url = "github:yourusername/commiter";  # замените на ваш репозиторий
      # или для локальной разработки:
      # url = "path:/home/uzz/projects/commiter";
    };
  };

  outputs = { nixpkgs, home-manager, commiter, ... }: {
    # Ваша конфигурация
    homeConfigurations.your-username = home-manager.lib.homeManagerConfiguration {
      # ...
      extraSpecialArgs = { inherit commiter; };
    };
  };
}
```

2. В вашем `home.nix`:

```nix
{ config, pkgs, commiter, ... }:

{
  home.packages = [
    commiter.packages.${pkgs.system}.default
  ];
}
```

### Вариант 3: Прямая установка (без flake inputs)

```nix
{ config, pkgs, ... }:

{
  home.packages = [
    (pkgs.callPackage /path/to/commiter/flake.nix {}).packages.${pkgs.system}.default
  ];
}
```

## Настройка конфигурации

После установки необходимо создать конфигурационный файл. Вы можете сделать это вручную или через home-manager:

### Вручную

```bash
mkdir -p ~/.config/commiter
cp $(nix build path:/home/uzz/projects/commiter --print-out-paths)/share/doc/commiter/config.example ~/.config/commiter/config
chmod 600 ~/.config/commiter/config
# Отредактируйте файл и добавьте ваши api_url и api_token
```

### Через home-manager (рекомендуется)

В вашем `home.nix`:

```nix
{ config, pkgs, ... }:

{
  home.file.".config/commiter/config" = {
    text = ''
      [DEFAULT]
      api_url = https://your-openwebui.com
      api_token = your-api-token-here
      model = llama3.2
      language = ru
      timeout = 60
    '';
    onChange = ''
      chmod 600 ~/.config/commiter/config
    '';
  };
}
```

**ВАЖНО:** Не коммитьте файл с токеном в git! Используйте secrets management (например, agenix или sops-nix) для безопасного хранения токена.

## Применение изменений

После изменения конфигурации home-manager:

```bash
home-manager switch
```

Или если используете flake:

```bash
home-manager switch --flake .#your-username
```

## Использование

После установки команда `commiter` будет доступна в вашем PATH:

```bash
# В любой git директории
commiter

# С параметрами
commiter --language ru
commiter --model qwen2.5-coder:7b
commiter --git-folder /path/to/repo
```

## Проверка установки

```bash
# Проверить версию и помощь
commiter --help

# Проверить, что все зависимости доступны
which commiter
which git
which wl-copy  # или xclip, xsel
```

## Разработка

Для разработки можно использовать development shell:

```bash
cd /home/uzz/projects/commiter
nix develop

# Теперь все зависимости доступны в shell
python3 commiter.py --help
```

## Обновление

Если используете flake inputs:

```bash
nix flake update commiter
home-manager switch --flake .#your-username
```

Если используете локальный путь, просто сделайте `git pull` в директории проекта и пересоберите:

```bash
home-manager switch
```

## Удаление

Удалите commiter из `home.packages` в вашем `home.nix` и выполните:

```bash
home-manager switch
```

Конфигурационный файл останется в `~/.config/commiter/config`, удалите его вручную при необходимости.

## Troubleshooting

### "commiter: command not found"

- Убедитесь, что вы выполнили `home-manager switch`
- Проверьте, что `~/.nix-profile/bin` в вашем PATH
- Попробуйте перезагрузить shell или выполнить `source ~/.bashrc` (или `~/.zshrc`)

### Ошибка "git не найден"

- git должен быть автоматически добавлен в PATH через wrapper
- Если проблема сохраняется, проверьте `nix-store -qR $(which commiter)`

### Проблемы с буфером обмена

Пакет включает поддержку `wl-clipboard`, `xclip` и `xsel`. Если ни один не работает:

```nix
home.packages = [
  pkgs.wl-clipboard  # для Wayland
  pkgs.xclip         # для X11
];
```

## Полный пример конфигурации

Смотрите файл `home-manager-example.nix` в репозитории для полного примера.
