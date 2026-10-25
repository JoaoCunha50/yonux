{
  description = "yonux-shell: Quickshell desktop shell + Hyprland config";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      nixosModules.default = import ./nix/yonux.nix;
      devShells.${system} = {
        default = import ./nix/devshell.nix { inherit pkgs; };
        ci = pkgs.mkShell {
          packages = [
            pkgs.shellcheck
            pkgs.quickshell
            pkgs.kdePackages.qtdeclarative
          ];
          QML_IMPORT_PATH = "${pkgs.quickshell}/lib/qt-6/qml:${pkgs.kdePackages.qtdeclarative}/lib/qt-6/qml";
        };
      };
    };
}
