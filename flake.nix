{
  description = "Calibre-Web flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        pythonEnv = pkgs.python3.withPackages (ps:
          with ps; [
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
            iso639
            lxml
            netifaces
            pypdf
            pycountry
            python-magic
            pytz
            regex
            requests
            sqlalchemy
            tornado
            unidecode
            urllib3
            wand
          ]);

        runtimeBinPath = pkgs.lib.makeBinPath [
          pkgs.file
          pkgs.imagemagick
        ];
      in {
        packages.default = pkgs.stdenvNoCC.mkDerivation {
          pname = "calibre-web";
          version = "git";
          src = self;
          nativeBuildInputs = [ pkgs.makeWrapper ];

          installPhase = ''
            runHook preInstall

            mkdir -p "$out/share/calibre-web"
            cp -r . "$out/share/calibre-web"

            mkdir -p "$out/bin"
            makeWrapper ${pythonEnv}/bin/python "$out/bin/calibre-web" \
              --set PYTHONPATH "$out/share/calibre-web" \
              --prefix PATH : ${runtimeBinPath} \
              --add-flags "$out/share/calibre-web/cps.py"

            runHook postInstall
          '';
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/calibre-web";
        };

        devShells.default = pkgs.mkShell {
          packages = [
            pythonEnv
            pkgs.file
            pkgs.imagemagick
          ];

          shellHook = ''
            echo "Calibre-Web self-contained dev shell ready."
            echo "Run: python cps.py"
          '';
        };
      });
}
