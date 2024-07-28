{
  src,
  lib,
  buildPythonPackage,
  faiss-git,
  cmake,
  swig4,
  python3,
  setuptools,
  pip,
  wheel,
  numpy,
  packaging
}:
buildPythonPackage  {
  pname = "pyfaiss";
  version = "1.9.90";
  inherit src;

  nativeBuildInputs=[cmake swig4 python3];
  buildInputs=[faiss-git setuptools pip wheel];
  propagatedBuildInputs = [numpy packaging];

  configurePhase = ''
  cmake -B build -DFAISS_ENABLE_GPU=OFF -DFAISS_OPT_LEVEL=avx512 -DCMAKE_BUILD_TYPE=Release faiss/python
  '';

  buildPhase = ''
  make VERBOSE=1 -C build -j swigfaiss swigfaiss_avx2 swigfaiss_avx512
  (cd build &&
   python -m pip wheel --verbose --no-index --no-deps --no-clean --no-build-isolation --wheel-dir dist .)
  '';

  installPhase = ''
    unset SOURCE_DATE_EPOCH;
    cd build
    find . -mtime +13700 -exec touch {} \;
    python -m pip install dist/*.whl --no-index --no-warn-script-location --prefix="$out" --no-cache
  '';
  dontUseSetuptoolsCheck=true;

  meta = with lib; {
    homepage = "https://github.com/facebookresearch/faiss";
    description = "A library for efficient similarity search and clustering of dense vectors.";
  };
}
