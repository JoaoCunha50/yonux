# Development only | direnv via .envrc - recommended
# Provides qmlls; its import paths come from yonux-shell/.qmlls.ini, which the
# running shell fills in.

{ pkgs }:
pkgs.mkShell {
  name = "yonux-shell-dev";

  packages = [
    pkgs.kdePackages.qtdeclarative
  ];
}
