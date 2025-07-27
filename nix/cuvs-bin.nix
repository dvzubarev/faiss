#see pack_bin_cuvs.sh
{
  src,
  stdenv,
  lib,
  fetchurl,
  cudaPackages,
}:
let
  hash_per_cu_version = {
    "12.8" = "d53546f9cf76a6351fda6f95e8abdf0bd4c25df62a7ed9c061ada24bcaf1e618";
    "11.8" = "bd347a6a6aca252fe5cd85da2ea7dcc9e8e693858c9aa88d8e55a5ba912d37c2";
  };
in
stdenv.mkDerivation rec {
  pname = "cuvs-bin";
  version = "25.04.02";
  src = fetchurl {
    url = "http://dn11.isa.ru:8080/thirdparty/cuvs-v${version}-cuda${cudaPackages.cudaVersion}.tar.gz";
    sha256= hash_per_cu_version.${cudaPackages.cudaVersion} or (throw "No pre-built cuvs binaries for cuda ${cudaPackages.cudaVersion}");
  };

  buildPhase = ''
  mkdir -p $out
  cp -r * $out/
  '';

  postFixup =
    let
      rpath = lib.makeLibraryPath [
        stdenv.cc.cc
        stdenv.cc.libc
        cudaPackages.cuda_cudart
        cudaPackages.libcublas
        cudaPackages.libcusolver
        cudaPackages.libcusparse
        cudaPackages.libcurand
        cudaPackages.nccl
      ];
    in
      ''
      for l in libcuvs.so libcuvs_c.so ; do
            patchelf $out/lib/$l --set-rpath "${rpath}:$out/lib"
      done
      '';

  propagatedBuildInputs = [
    cudaPackages.libcusolver
    cudaPackages.libcusparse
    cudaPackages.libcurand
  ];


  meta = with lib; {
    homepage = "https://github.com/rapidsai/cuvs";
    description = "cuVS - a library for vector search and clustering on the GPU ";
  };
}
