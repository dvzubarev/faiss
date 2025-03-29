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
  version = "25.04.01";
  src = fetchurl {
    url = "http://dn11.isa.ru:8080/thirdparty/cuvs-v${version}-cuda${cudaPackages.cudaVersion}.tar.gz";
    sha256= if cudaPackages.cudaVersion == "12.8" then
      "aa6d27f3df38b28be0088b2df18cab927763a1b19eac3a1f96c7f87e1aa935fc" else "aa946c5a5a65d5b090112612ae697fe806c3610049dfdab45a1cad6ea147887c";
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
