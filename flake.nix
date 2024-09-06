{
  description = "faiss";

  inputs = {
    nixpkgs.url = "nixpkgs/c19d62ad2265b16e2199c5feb4650fe459ca1c46";
  };

  outputs = { self, nixpkgs }:
    let pkgs = import nixpkgs {
          system = "x86_64-linux";
          overlays = [ self.overlays.default ];
          config = {
            allowUnfree = true;
            cudaSupport=true;
          };
        };
    in {
      overlays.default = final: prev: {
        #cuda supports clang 16 at the moment
        cuda_llvm_pkgs = pkgs.llvmPackages_16;
        cuda_gcc_stedenv = pkgs.cudaPackages.backendStdenv;

        faiss-git = final.callPackage ./nix {src=self;
                                             cudaSupport=true;
                                             stdenv=final.cuda_gcc_stedenv;};
        faiss-clang-git = final.callPackage ./nix {
          src=self;
          cudaSupport=true;
          stdenv = final.cuda_llvm_pkgs.stdenv;
          llvmPackages = final.cuda_llvm_pkgs;
        };
        python3 = prev.python3.override {
          packageOverrides = pyfinal: pyprev: {
            faiss-python = pyfinal.toPythonModule (pkgs.faiss-git.override {
              python3Packages=pyfinal;
              stdenv=final.cuda_gcc_stedenv;
              cudaSupport=true;
            });
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
        default = pkgs.mkShell.override { stdenv = pkgs.cuda_llvm_pkgs.stdenv; } {

          inputsFrom = [pkgs.faiss-clang-git];
          buildInputs = [
            pkgs.ccls_18
            #for llvm-symbolizer
            pkgs.cuda_llvm_pkgs.libllvm
            pkgs.gdb

            (pkgs.python3.withPackages (p: [p.torch]))
          ];

          shellHook = ''
          export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/nvidia/current/:$LD_LIBRARY_PATH
          '';
        };
      };
    };

}
