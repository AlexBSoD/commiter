# Пример конфигурации для home-manager
# Добавьте этот код в ваш home-manager конфиг

{ config, pkgs, ... }:

{
  # Вариант 1: Установка через inputs (рекомендуется)
  # В flake.nix вашей системы добавьте:
  #
  # inputs = {
  #   commiter.url = "github:yourusername/commiter";  # или path:/path/to/commiter
  #   # ... другие inputs
  # };
  #
  # Затем в home-manager модуле:
  # home.packages = [ inputs.commiter.packages.${pkgs.system}.default ];

  # Вариант 2: Установка из локальной директории
  home.packages = [
    (import /path/to/commiter {
      inherit (pkgs) system;
    }).packages.${pkgs.system}.default
  ];

  # Вариант 3: Прямой вызов flake из домашней директории
  # home.packages = [
  #   (builtins.getFlake "path:/home/uzz/projects/commiter").packages.${pkgs.system}.default
  # ];

  # Создание конфигурационного файла (опционально)
  home.file.".config/commiter/config" = {
    text = ''
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

      # Таймаут запроса в секундах
      timeout = 60
    '';
    # Важно: установите правильные права доступа для файла с токеном
    onChange = ''
      chmod 600 ~/.config/commiter/config
    '';
  };
}
