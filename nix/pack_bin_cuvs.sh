#!/usr/bin/env bash

#It is hard to compile cuvs within nix sandbox since it fetches many deps using cmake machinery (and patches them).
#It is not possible to fetch anything in nix sandbox and I don't want to pack every dependency in nix.
#So build library manually within nix environment and use this binary package in faiss.
#See nix-buildproxy for tool that captures cmake fetches (but it is useless when thirdparties are patched).

#Rough list of command to compile and pack cuvs:
#
#checkout latest release of cuvs, for example in ../cuvs directory.
#Call `nix develop .#cuvs-build-dev` and go to cuvs source directory `../cuvs/cpp/build`
#Configure cuvs with cmake command
#cmake -DCMAKE_CUDA_ARCHITECTURES:STRING=70\;75\;80 -DCMAKE_INSTALL_PREFIX=$(pwd)/../cuvs-bin \
#-DBUILD_TESTS=OFF -DDETECT_CONDA_ENV=OFF -DCUVS_COMPILE_DYNAMIC_ONLY=ON -DCUVS_USE_RAFT_STATIC=ON  ..
#and built with make install.
#Also build raft:
#cd _deps/raft-src/cpp && mkdir build && cd build && cmake -DCMAKE_CUDA_ARCHITECTURES='70;75;80' -DCMAKE_INSTALL_PREFIX=../../../../../cuvs-bin/ -DBUILD_TESTS=OFF -DDETECT_CONDA_ENV=OFF -DRAFT_COMPILE_DYNAMIC_ONLY=ON  ..
#make install
#return to cuvs/cpp/build directory.


#call this script from build directory.

cd ../

#Change archive name!
archive=cuvs-v26.06.00-cuda12.9.tar.gz
tar cfz $archive cuvs-bin
aw s3 cp $archive  s3://thirdparty/
aw s3api put-object-tagging --bucket thirdparty --key $archive --tagging 'TagSet={Key=public,Value=yes}'

#change cuvs-bin.nix after uploading new version.
#Do not forget to change sha256.
