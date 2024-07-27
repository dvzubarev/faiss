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
        faiss-git = final.callPackage ./nix {src=self;};
        faiss-clang-git = final.callPackage ./nix {
          src=self;
          stdenv = pkgs.llvmPackages_18.stdenv;
          llvmPackages = pkgs.llvmPackages_18;
        };
        python3 = prev.python3.override {
          packageOverrides = pyfinal: pyprev: {
            faiss-python = pyfinal.callPackage ./nix/faiss-python.nix {src=self;};
          };
        };

        ccls_18 = prev.ccls.override({llvmPackages=final.llvmPackages_18;});
      };
      packages.x86_64-linux = {
        inherit (pkgs)
          faiss-git
          faiss-clang-git
          python3;

        default = pkgs.faiss-git;
      };


      devShells.x86_64-linux = {
        #dev env with clang compiler
        default = pkgs.mkShell.override { stdenv = pkgs.llvmPackages_18.stdenv; } {

          inputsFrom = [pkgs.faiss-clang-git];
          buildInputs = [
            pkgs.ccls_18
            #for llvm-symbolizer
            pkgs.llvmPackages_18.libllvm
            pkgs.gdb

            (pkgs.python3.withPackages (p: [p.torch]))
          ];

          shellHook = ''
          '';
        };
      };
    };

}
