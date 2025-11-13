{
description = "A self-contained FreeCAD development environment using Qt6 and IfcOpenShell.";

inputs = {
# Pin to the latest bleeding edge of Nixpkgs for the most up-to-date
# FreeCAD dependencies, including Qt6 and IfcOpenShell.
nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
};

outputs = { self, nixpkgs, ... }:
let
# Define the systems this flake will support.
supportedSystems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];

  # A helper function to get the correct pkgs set for each system
  pkgsFor = system: import nixpkgs { inherit system; };

  # A helper that applies a function across all supported systems
  forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
in
{
  # --- 1. The Core Development Shell Definition ---
  devShells = forAllSystems (system:
    let
      pkgs = pkgsFor system;

      # Get the FreeCAD package derivation from unstable. This is our
      # "source of truth" for all dependencies.
      freecadPackage = pkgs.freecad;

      # Consolidate all dependency inputs. This pulls in everything:
      # Qt6, OCCT, Coin3D, Eigen, IfcOpenShell, all Python modules, etc.
      # We use lib.unique to avoid duplicates.
      allBuildDeps = pkgs.lib.unique (
        (freecadPackage.buildInputs or []) ++ 
        (freecadPackage.propagatedBuildInputs or [])
      );

      # Consolidate all tool inputs (compiler, cmake, etc.)
      allToolDeps = pkgs.lib.unique (
        (freecadPackage.nativeBuildInputs or []) ++ [
          # Add essential dev tools
          pkgs.gcc           # The full C/C++ toolchain (fixes CMake test failures)
          pkgs.cmake
          pkgs.ninja        # Recommended build generator
          pkgs.pkg-config
          pkgs.git
          pkgs.gdb          # Debugger
        ]
      );

    in
    {
      default = pkgs.mkShell {
        name = "freecad-qt6-ifc-shell";

        # buildInputs: Libraries and headers needed for linking/compilation
        buildInputs = allBuildDeps;

        # nativeBuildInputs: Tools needed to perform the build
        nativeBuildInputs = allToolDeps;

        # --- Environment Setup ---
        shellHook = ''
          echo "--------------------------------------------------------"
          echo "Entering FreeCAD Development Shell (Qt6 + IfcOpenShell)"
          echo "Dependencies are sourced from the 'freecad' package."
          echo ""
          echo "Use 'cmake --preset=nix-debug' or 'cmake --preset=nix-release'"
          echo "to configure your build."
          echo "--------------------------------------------------------"
        '';
      };
    }
  );
};


}
