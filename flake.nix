{
  description = "Minimal Odin + Raylib development shell with OLS";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      raylibRuntime = with pkgs; [
        raylib
        libGL
        alsa-lib
        libxkbcommon
        wayland
        libX11
        libXcursor
        libXi
        libXinerama
        libXrandr
      ];
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          odin
          ols
          clang
          pkg-config
        ] ++ raylibRuntime;

        LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath raylibRuntime;

        shellHook = ''
          echo "Odin + Raylib shell"
        '';
      };
    };
}
