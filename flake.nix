{
  description = "faiss";

  inputs = {
    nixpkgs.url = "nixpkgs/bd3bac8bfb542dbde7ffffb6987a1a1f9d41699f";
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
        #cuda supports clang 19 at the moment
        #https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html
        cuda_llvm_pkgs = pkgs.llvmPackages;
        cuda_gcc_stedenv = pkgs.cudaPackages.backendStdenv;

        faiss-git = final.callPackage ./nix {src=self;
                                             cudaSupport=true;
                                             stdenv=final.cuda_gcc_stedenv;};
        faiss-cu11-git = final.callPackage ./nix {src=self;
                                                  cudaSupport=true;
                                                  stdenv=pkgs.cudaPackages_11.backendStdenv;
                                                  cudaPackages=final.cudaPackages_11;
                                                  cuvs-bin=final.cuvs-cu11-bin;};
        faiss-clang-git = final.callPackage ./nix {
          src=self;
          cudaSupport=true;
          stdenv = final.cuda_llvm_pkgs.stdenv;
          llvmPackages = final.cuda_llvm_pkgs;
        };
        cuvs-build-env = final.callPackage ./nix/cuvs-build-env.nix{stdenv=final.cuda_gcc_stedenv;};
        cuvs-bin = final.callPackage ./nix/cuvs-bin.nix{};
        cuvs-cu11-bin = final.callPackage ./nix/cuvs-bin.nix{cudaPackages=final.cudaPackages_11;};

        python3 = prev.python3.override {
          packageOverrides = pyfinal: pyprev: {
            faiss-python = pyfinal.toPythonModule (pkgs.faiss-git.override {
              python3Packages=pyfinal;
              stdenv=final.cuda_gcc_stedenv;
              cudaSupport=true;
            });
          };
        };

      };
      packages.x86_64-linux = {
        inherit (pkgs)
          faiss-git
          faiss-cu11-git
          faiss-clang-git
          cuvs-bin
          python3;

        default = pkgs.faiss-git;
      };


      devShells.x86_64-linux = {
        #dev env with clang compiler
        default = pkgs.mkShell.override { stdenv = pkgs.cuda_llvm_pkgs.stdenv; } {

          inputsFrom = [pkgs.faiss-clang-git];
          buildInputs = [
            pkgs.ccls
            #for llvm-symbolizer
            pkgs.cuda_llvm_pkgs.libllvm
            pkgs.gdb

            (pkgs.python3.withPackages (p: [p.torch]))
          ];

          shellHook = ''
          export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/nvidia/current/:$LD_LIBRARY_PATH
          '';
        };
        cuvs-build-dev = pkgs.mkShell.override { stdenv = pkgs.cuda_gcc_stedenv; } {
          inputsFrom = [pkgs.cuvs-build-env];
          shellHook = ''
          export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/nvidia/current/:$LD_LIBRARY_PATH
          '';
        };
      };
    };

}
