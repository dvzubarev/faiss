{
  description = "faiss";

  inputs = {
    nixpkgs.url = "nixpkgs";
  };

  outputs = { self, nixpkgs }:
    let pkgs = import nixpkgs {
          system = "x86_64-linux";
          overlays = [ self.overlays.default ];
          config = {
            allowUnfree = true;
          };
        };
    in {
      overlays.default = final: prev: {
        ccls_18 = prev.ccls.override({llvmPackages=final.llvmPackages_18;});
      };

      devShells.x86_64-linux = {
        #dev env with clang compiler
        default = pkgs.mkShell.override { stdenv = pkgs.llvmPackages_18.stdenv; } {

          inputsFrom = [];
          buildInputs = [
            pkgs.ccls_18
            pkgs.cmake
            pkgs.llvmPackages.openmp.dev
            pkgs.blas
            #for llvm-symbolizer
            pkgs.llvmPackages_18.libllvm
            pkgs.gdb
          ];

          shellHook = ''
          '';
        };
      };
    };

}
