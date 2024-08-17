# List available recipes in the order in which they appear in this file
_default:
    @just --list --unsorted

serve:
  Rscript -e "library(shiny); runApp(appDir = 'app', port = 4321)"

classify:
  julia --project test.jl
