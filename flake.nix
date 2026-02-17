{
  description = "Calibre-Web - Web app for browsing, reading and downloading eBooks stored in a Calibre database";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        python = pkgs.python312;

        calibre-web = python.pkgs.buildPythonApplication {
          pname = "calibre-web";
          version = "0.6.24";
          pyproject = true;

          src = ./.;

          # calibre-web doesn't follow setuptools directory structure.
          # Restructure so setuptools can find the package.
          postPatch = ''
            mkdir -p src/calibreweb
            mv cps.py src/calibreweb/__init__.py
            mv cps src/calibreweb

            substituteInPlace pyproject.toml \
              --replace-fail 'cps = "calibreweb:main"' 'calibre-web = "calibreweb:main"'
          '';

          build-system = [ python.pkgs.setuptools ];

          dependencies = with python.pkgs; [
            apscheduler
            babel
            bleach
            certifi
            chardet
            cryptography
            flask
            flask-babel
            flask-httpauth
            flask-limiter
            flask-principal
            flask-wtf
            iso-639
            lxml
            netifaces-plus
            pycountry
            pypdf
            python-magic
            pytz
            regex
            requests
            sqlalchemy
            tornado
            unidecode
            urllib3
            wand
          ];

          optional-dependencies = {
            comics = with python.pkgs; [
              comicapi
              natsort
            ];
            kobo = with python.pkgs; [ jsonschema ];
            metadata = with python.pkgs; [
              faust-cchardet
              html2text
              markdown2
              mutagen
              py7zr
              pycountry
              python-dateutil
              rarfile
              scholarly
            ];
            oauth = with python.pkgs; [
              flask-dance
              sqlalchemy-utils
            ];
          };

          # Allow newer versions than what pyproject.toml pins
          pythonRelaxDeps = [
            "apscheduler"
            "bleach"
            "cryptography"
            "flask"
            "flask-limiter"
            "lxml"
            "pypdf"
            "regex"
            "tornado"
            "unidecode"
          ];

          doCheck = false;

          pythonImportsCheck = [ "calibreweb" ];

          meta = with pkgs.lib; {
            description = "Web app for browsing, reading and downloading eBooks stored in a Calibre database";
            homepage = "https://github.com/janeczku/calibre-web";
            license = licenses.gpl3Plus;
            platforms = platforms.all;
          };
        };
      in
      {
        packages = {
          default = calibre-web;
          calibre-web = calibre-web;
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ calibre-web ];

          packages = with pkgs; [
            python
            python.pkgs.pip
            python.pkgs.setuptools
            imagemagick
          ];

          shellHook = ''
            echo "calibre-web dev shell"
            echo "  Run:  python -m calibreweb"
          '';
        };
      }
    );
}
