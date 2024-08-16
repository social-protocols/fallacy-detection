{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # for `flake-utils.lib.eachDefaultSystem`
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ ];
          config = {
            allowUnfree = false;
            packageOverrides = super: let self = super.pkgs; in
            {
              rStudioWithPackages = super.rstudioWrapper.override{
                packages = with super.rPackages; [
                  rmarkdown
                  DBI
                  dbplyr
                  RSQLite
                  lubridate
                  stringr
                  dplyr
                  tidyr
                  ggplot2
                  shiny
                  shinydashboard
                ];
              };
            };
          };
        };
        defaultBuildInputs = with pkgs; [
          julia-bin
          sqlite-interactive
          rStudioWithPackages
        ];
      in
      {
        devShells.default = with pkgs; pkgs.mkShellNoCC {
          name = "dev-shell";
          buildInputs = defaultBuildInputs;
        };
        packages.default = with pkgs; pkgs.mkShellNoCC {
          name = "pack";
          buildInputs = defaultBuildInputs;
        };
      }
    );
}

