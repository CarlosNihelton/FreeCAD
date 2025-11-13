{
description = "A self-contained FreeCAD development environment using Qt6 from Nix unstable.";

inputs = {
# Pin to the latest bleeding edge of Nixpkgs for the most up-to-date FreeCAD dependencies, including Qt6.
nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
};

outputs = { self, nixpkgs, ... }:
let
# Define the systems this flake will support.
supportedSystems = [ "x86_64-linux" "aarch64-darwin" ];
forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
in
forAllSystems (system:
let
# Import the unstable Nixpkgs set for the target system.
pkgs = import nixpkgs { inherit system; };

    # Get the FreeCAD package derivation from unstable. This package holds references
    # to all its build-time and run-time dependencies (Qt6, Python, OCCT, Coin3D, etc.).
    freecadPackage = pkgs.freecad;

    # --- Extract Dependencies ---
    # The safest and most comprehensive approach for a development shell is to inherit
    # all inputs used by the freecad package itself. We merge buildInputs, nativeBuildInputs, 
    # and propagatedBuildInputs for full coverage.
    
    # Libraries and runtime dependencies (FreeCAD links against these)
    libraryInputs = freecadPackage.buildInputs 
      ++ freecadPackage.propagatedBuildInputs;
      
    # Build tools (CMake, compiler, pkg-config, etc.)
    toolInputs = freecadPackage.nativeBuildInputs;

    # Explicit development tools for convenience
    extraDevTools = with pkgs; [
      # Essential C/C++ toolchain
      pkgs.stdenv.cc.cc
      # Build systems
      cmake
      ninja  # Ninja is often faster than standard Make
      pkg-config
      # Version control and debugging
      git
      gdb
    ];

  in
  {
    devShells.default = pkgs.mkShell {
      name = "freecad-qt6-dev-shell";

      # nativeBuildInputs: Tools needed to perform the build
      nativeBuildInputs = pkgs.lib.unique (toolInputs ++ extraDevTools);

      # buildInputs: Libraries and headers needed for linking/compilation
      buildInputs = pkgs.lib.unique libraryInputs;

      # --- Environment Setup ---
      shellHook = ''
        echo "--------------------------------------------------------"
        echo "Entering FreeCAD Development Shell (Nix unstable, Qt6)"
        echo "All FreeCAD dependencies (C++, Python, Qt6) are available."
        echo ""
        echo "Suggested build steps (assuming source code is in current dir):"
        echo "  1. mkdir build"
        echo "  2. cmake -B build -S . -G Ninja"
        echo "  3. ninja -C build"
        echo "  4. run FreeCAD with: ./build/bin/FreeCAD"
        echo "--------------------------------------------------------"
      '';
    };
  }
);


}
