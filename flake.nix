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
          pname = "calibreweb";
          version = "0.6.24";
          format = "pyproject";

          src = ./.;

          nativeBuildInputs = with python.pkgs; [
            setuptools
          ];

          propagatedBuildInputs = with python.pkgs; [
            apscheduler
            babel
            flask-babel
            flask-principal
            flask
            pypdf
            pytz
            requests
            sqlalchemy
            tornado
            wand
            unidecode
            lxml
            flask-wtf
            chardet
            urllib3
            flask-limiter
            regex
            bleach
            python-magic
            flask-httpauth
            cryptography
            certifi
            pycountry
            netifaces-plus
          ];

          # Runtime dependencies that aren't Python packages
          buildInputs = with pkgs; [
            imagemagick # Required by Wand
            libmagic    # Required by python-magic
          ];

          # Wrap the binary so native libs are found at runtime
          makeWrapperArgs = [
            "--prefix" "PATH" ":" "${pkgs.lib.makeBinPath [ pkgs.imagemagick ]}"
          ];

          # Tests require a running instance and calibre database
          doCheck = false;

          meta = with pkgs.lib; {
            description = "Web app for browsing, reading and downloading eBooks stored in a Calibre database";
            homepage = "https://github.com/janeczku/calibre-web";
            license = licenses.gpl3Plus;
            maintainers = [];
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

            # Native libraries needed at runtime
            imagemagick
            libmagic
          ];

          shellHook = ''
            echo "calibre-web dev shell"
            echo "  Run:  python -m calibreweb"
          '';
        };
      }
    );
}
