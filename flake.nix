{
  description = "faiss";

  inputs = {
    nixpkgs.url = "nixpkgs/78a847885e0163e17b1a620882d91bd2dfb05d54";
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
        #cuda supports upto clang-21 at the moment
        #https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html
        cuda_llvm_pkgs = pkgs.llvmPackages_21;
        cuda_gcc_stdenv = pkgs.cudaPackages.backendStdenv;
        cuda11_gcc_stdenv = pkgs.cudaPackages_11.backendStdenv;

        faiss-git = final.callPackage ./nix {src=self;
                                             cudaSupport=true;
                                             stdenv=final.cuda_gcc_stdenv;};
        faiss-clang-git = final.callPackage ./nix {
          src=self;
          cudaSupport=true;
          stdenv = final.cuda_llvm_pkgs.stdenv;
          llvmPackages = final.cuda_llvm_pkgs;
        };
        cuvs-build-env = final.callPackage ./nix/cuvs-build-env.nix{stdenv=final.cuda_gcc_stdenv;};
        cuvs-bin = final.callPackage ./nix/cuvs-bin.nix{};

        python3 = prev.python3.override {
          packageOverrides = pyfinal: pyprev: {
            faiss-python = pyfinal.toPythonModule (pkgs.faiss-git.override {
              python3Packages=pyfinal;
              stdenv=final.cuda_gcc_stdenv;
              cudaSupport=true;
            });
          };
        };

      };
      packages.x86_64-linux = {
        inherit (pkgs)
          faiss-git
          faiss-clang-git
          cuvs-bin
          python3;

        default = pkgs.faiss-git;
      };


      devShells.x86_64-linux = {
        default = pkgs.mkShell.override { stdenv = pkgs.cuda_gcc_stdenv; } {

          inputsFrom = [pkgs.faiss-git];
          buildInputs = [
            pkgs.ccls
            #for llvm-symbolizer
            # pkgs.cuda_llvm_pkgs.libllvm
            pkgs.gdb

            (pkgs.python3.withPackages (p: [p.torch]))
          ];

          shellHook = ''
          export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/nvidia/current/:$LD_LIBRARY_PATH
          echo "%compile_commands.json" > .ccls
          echo "--gcc-toolchain=${pkgs.stdenv.cc.cc.outPath}" >> .ccls
          '';
        };
        cuvs-build-dev = pkgs.mkShell.override { stdenv = pkgs.cuda_gcc_stdenv; } {
          inputsFrom = [pkgs.cuvs-build-env];
          shellHook = ''
          export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/nvidia/current/:$LD_LIBRARY_PATH
          '';
        };
      };
    };

}
