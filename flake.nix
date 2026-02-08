{
  description = "AI-powered git commit message generator using OpenWebUI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        commiter = pkgs.stdenv.mkDerivation rec {
          pname = "commiter";
          version = "0.0.3";

          src = ./.;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          buildInputs = [ pkgs.python3 ];

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            mkdir -p $out/share/doc/commiter

            # Устанавливаем основной скрипт
            cp commiter.py $out/bin/commiter
            chmod +x $out/bin/commiter

            # Оборачиваем скрипт, добавляя зависимости в PATH
            wrapProgram $out/bin/commiter \
              --prefix PATH : ${pkgs.lib.makeBinPath [
                pkgs.git
                pkgs.wl-clipboard  # для wl-copy (Wayland)
                pkgs.xclip         # для xclip (X11)
                pkgs.xsel          # для xsel (X11)
              ]}

            # Устанавливаем документацию и примеры
            cp README.md $out/share/doc/commiter/
            cp CHANGELOG.md $out/share/doc/commiter/
            cp INSTALL.md $out/share/doc/commiter/
            cp config.example $out/share/doc/commiter/
            cp VERSION $out/share/doc/commiter/

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "AI-powered git commit message generator using OpenWebUI";
            longDescription = ''
              Commiter analyzes git changes and generates conventional commit messages
              using OpenWebUI API. Supports Russian and English languages.
              Uses only Python standard library with no external dependencies.
            '';
            homepage = "https://github.com/yourusername/commiter";
            license = licenses.mit;
            maintainers = [ ];
            platforms = platforms.unix;
            mainProgram = "commiter";
          };
        };
      in
      {
        packages = {
          default = commiter;
          commiter = commiter;
        };

        apps = {
          default = {
            type = "app";
            program = "${commiter}/bin/commiter";
          };
        };

        # Development shell для разработки
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            python3
            git
            wl-clipboard
            xclip
            xsel
          ];
        };
      }
    );
}
