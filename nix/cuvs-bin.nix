#see pack_bin_cuvs.sh
{
  src,
  stdenv,
  lib,
  fetchurl,
  cudaPackages,
}:
stdenv.mkDerivation rec {
  pname = "cuvs-bin";
  version = "25.04.02";
  src = fetchurl {
    url = "http://dn11.isa.ru:8080/thirdparty/cuvs-v${version}-cuda${cudaPackages.cudaVersion}.tar.gz";
    sha256= if cudaPackages.cudaVersion == "12.8" then
      "d53546f9cf76a6351fda6f95e8abdf0bd4c25df62a7ed9c061ada24bcaf1e618" else "bd347a6a6aca252fe5cd85da2ea7dcc9e8e693858c9aa88d8e55a5ba912d37c2";
  };

  buildPhase = ''
  mkdir -p $out
  cp -r * $out/
  '';
  propagatedBuildInputs = [
    cudaPackages.libcusolver
    cudaPackages.libcusparse
    cudaPackages.nccl
  ];


  meta = with lib; {
    homepage = "https://github.com/rapidsai/cuvs";
    description = "cuVS - a library for vector search and clustering on the GPU ";
  };
  }
