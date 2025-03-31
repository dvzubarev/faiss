#see pack_bin_cuvs.sh
{
  src,
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  git,
  mkl,
  cudaPackages,
  llvmPackages,
}:
stdenv.mkDerivation rec {
  pname = "cuvs";
  version = "25.04.90";
  src = fetchFromGitHub {
    owner = "rapidsai";
    repo = "cuvs";
    rev = "ff8682798536b5975f47ac86b3f3d2e2c801904b";
    sha256 = "0h03qflibvwsgbqi49pikhfxz8snkf26pdn3w6w6ndj6h4zr6i05";
  };

  nativeBuildInputs = [ cmake cudaPackages.cuda_nvcc git ];
  buildInputs = [
    mkl
    cudaPackages.cuda_cudart # cuda_runtime.h
    cudaPackages.libcublas
    cudaPackages.libcurand
    cudaPackages.libcusolver
    cudaPackages.libcusparse
    cudaPackages.nccl
    #It is vendored
    # cudaPackages.cuda_cccl
  ] ++ lib.optionals stdenv.cc.isClang [
    llvmPackages.openmp
  ];
  cmakeBuildDir="cpp/build";
  cmakeFlags=[
    "-DBUILD_TESTS=OFF"
    "-DDETECT_CONDA_ENV=OFF"
    "-DBUILD_TESTS=OFF"
    "-DCUVS_COMPILE_DYNAMIC_ONLY=ON"
    "-DCMAKE_MESSAGE_LOG_LEVEL=VERBOSE"
    (lib.cmakeFeature "CMAKE_CUDA_ARCHITECTURES" "70;75;80")
  ];


  meta = with lib; {
    homepage = "https://github.com/rapidsai/cuvs";
    description = "cuVS - a library for vector search and clustering on the GPU ";
  };
}
