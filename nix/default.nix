{
  src,
  stdenv,
  lib,
  cmake,
  gflags,
  mkl,
  llvmPackages,
  swig4,
  cudaSupport ? false,
  cudaPackages,
  cuvs-bin,
  python3Packages,
}:
stdenv.mkDerivation {
  pname = "faiss";
  version = "1.10.91";
  inherit src;

  buildInputs = [
    mkl
    gflags
  ] ++ lib.optionals cudaSupport [
    cudaPackages.cuda_cudart # cuda_runtime.h
    cudaPackages.libcublas
    cudaPackages.libcurand
    cudaPackages.cuda_cccl
    # cuda_profiler_api.h
    (cudaPackages.cuda_profiler_api or cudaPackages.cuda_nvprof)
  ] ++
  lib.optionals stdenv.cc.isClang [
    llvmPackages.openmp
  ];

  nativeBuildInputs = [
    cmake
    swig4

    python3Packages.python
    python3Packages.setuptools
    python3Packages.pip
    python3Packages.wheel
  ] ++ lib.optionals cudaSupport [
    cudaPackages.cuda_nvcc
  ];

  propagatedBuildInputs = [
    python3Packages.numpy
    python3Packages.packaging
  ] ++ lib.optionals cudaSupport [
    cudaPackages.cuda_nvcc
    cudaPackages.libcublas.dev
    cudaPackages.cuda_cudart.dev
    cudaPackages.cuda_cccl.dev
    cudaPackages.libcurand
    cudaPackages.nccl
    cuvs-bin
  ];

  enableParallelBuilding=true;
  # NIX_CFLAGS_COMPILE = "-fsanitize=address";
  cmakeFlags =[
    (lib.cmakeBool "FAISS_ENABLE_GPU" cudaSupport)
    (lib.cmakeBool "FAISS_ENABLE_CUVS" cudaSupport)
    "-DCMAKE_BUILD_TYPE=Release"
    "-DBLA_VENDOR=Intel10_64lp"
    "-DFAISS_OPT_LEVEL=avx512"
    # "-DFAISS_OPT_LEVEL=avx2"
    # "-DFAISS_OPT_LEVEL=generic"
    "-DFAISS_ENABLE_PYTHON=ON"
    "-DBUILD_SHARED_LIBS=ON"
    "-DBUILD_TESTING=OFF"
    "-DCMAKE_SKIP_BUILD_RPATH=ON"
  ] ++ lib.optionals cudaSupport [
    (lib.cmakeFeature "CMAKE_CUDA_ARCHITECTURES" "70;75;80")
  ];
  buildFlags = [ "faiss" "swigfaiss" "swigfaiss_avx2" "swigfaiss_avx512"];


  postBuild = ''
    (cd faiss/python &&
     python -m pip wheel --verbose --no-index --no-deps --no-clean --no-build-isolation --wheel-dir dist .)
  '';

  postInstall = ''
  mkdir -p $out/${python3Packages.python.sitePackages}
  (cd faiss/python && python -m pip install dist/*.whl --no-index --no-warn-script-location --prefix="$out" --no-cache)
  '';
  preFixup = ''
    d=$out/${python3Packages.python.sitePackages}
    for l in _swigfaiss.so _swigfaiss_avx2.so _swigfaiss_avx512.so ; do
        patchelf --add-rpath $d/faiss $d/faiss/$l
    done
  '';




  meta = with lib; {
    homepage = "https://github.com/facebookresearch/faiss";
    description = "A library for efficient similarity search and clustering of dense vectors.";
  };
}
