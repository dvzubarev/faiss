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
  version = "26.06.00";
  src = fetchFromGitHub {
    owner = "rapidsai";
    repo = "cuvs";
    rev = "2bd7cd71d31e39eb9ee00c2a250085a1afb84977";
    sha256 = "0000000000000000000000000000000000000000000000000000";
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
    cudaPackages.libnvjitlink
    cudaPackages.cuda_nvrtc
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
