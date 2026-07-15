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
    "12.9" = "3d7532ae72d391e50d50bc977b12b9720cd885bd171fc2af62752e3e0649cff0";
    "12.8" = "d53546f9cf76a6351fda6f95e8abdf0bd4c25df62a7ed9c061ada24bcaf1e618";
  };
in
stdenv.mkDerivation rec {
  pname = "cuvs-bin";
  version = "26.06.00";
  src = fetchurl {
    url = "http://dn11.isa.ru:8080/thirdparty/cuvs-v${version}-cuda${cudaPackages.cudaMajorMinorVersion}.tar.gz";
    sha256= hash_per_cu_version.${cudaPackages.cudaMajorMinorVersion} or (throw "No pre-built cuvs binaries for cuda ${cudaPackages.cudaMajorMinorVersion}");
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
        cudaPackages.libnvjitlink
        cudaPackages.cuda_nvrtc
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
