{
  src,
  stdenv,
  lib,
  cmake,
  mkl,
  llvmPackages
}:
stdenv.mkDerivation {
  pname = "faiss";
  version = "1.9.90";
  inherit src;

  buildInputs = [
    mkl
  ] ++
  lib.optionals stdenv.cc.isClang [
    llvmPackages.openmp
  ];


  nativeBuildInputs = [
    cmake
  ];


  enableParallelBuilding=true;
  # NIX_CFLAGS_COMPILE = "-fsanitize=address";
  cmakeFlags =[
    "-DFAISS_ENABLE_GPU=OFF"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DBLA_VENDOR=Intel10_64lp"
    "-DFAISS_OPT_LEVEL=avx512"
    # "-DFAISS_OPT_LEVEL=avx2"
    # "-DFAISS_OPT_LEVEL=generic"
    "-DFAISS_ENABLE_PYTHON=OFF"
    "-DBUILD_SHARED_LIBS=ON"
    "-DBUILD_TESTING=OFF"
  ];


  meta = with lib; {
    homepage = "https://github.com/facebookresearch/faiss";
    description = "A library for efficient similarity search and clustering of dense vectors.";
  };
}
