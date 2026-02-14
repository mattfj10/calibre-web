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
        python = pkgs.python3;
      in {
        packages.default = pkgs.stdenvNoCC.mkDerivation {
          pname = "calibre-web";
          version = "git";
          src = self;
          nativeBuildInputs = [ pkgs.makeWrapper ];

          installPhase = ''
            runHook preInstall

            mkdir -p $out/share/calibre-web
            cp -r . $out/share/calibre-web

            mkdir -p $out/bin
            makeWrapper ${python}/bin/python $out/bin/calibre-web \
              --add-flags "$out/share/calibre-web/cps.py"

            runHook postInstall
          '';
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/calibre-web";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            python
            pkgs.python3Packages.pip
            pkgs.python3Packages.virtualenv
          ];

          shellHook = ''
            echo "Calibre-Web dev shell ready."
            echo "Create a venv and install dependencies with: pip install -r requirements.txt"
          '';
        };
      });
}
