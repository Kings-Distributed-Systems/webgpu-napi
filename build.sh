#!/bin/sh
#
# @file         build.sh
#               Builds the dawn library.
# @author       Dominic Cerisano, dcerisano@kingsds.network
# @date         April 2020

set -e

OS="$(uname -s)"
echo "Building Dawn on OS \"${OS}\"..."

export PATH=${PWD}/depot_tools:$PATH

cd dawn

if [ "${OS}" = "Linux" ]; then
  echo "Installing Linux build dependencies..."
  cp scripts/standalone.gclient .gclient
fi

echo
echo "Syncing gclient..."
gclient sync -D

build() {
  configuration=$1
  isDebug=false
  
  args=""
  if [ "${configuration}" = "debug" ]; then
    isDebug=true
  fi
 
  args="${args} is_component_build=true"
  args="${args} is_debug=${isDebug}"
  args="${args} target_cpu=\"x64\""
  args="${args} is_clang=true"
  

  echo "Generating build \"${configuration}\"..."
  gn gen "out/${configuration}" --args="${args}"
  echo "Building \"${configuration}\"..."
  ninja -C "out/${configuration}"
}

echo "Building..."
build Shared

cd ..

echo -n "$PWD/dawn" > PATH_TO_DAWN

npm install
npm run all --dawnversion=0.0.1

cd examples
npm install
echo $PWD

rm -r ./node_modules/webgpu/generated/0.0.1/linux/build/Release
mkdir ./node_modules/webgpu/generated/0.0.1/linux/build/Release

cd ..
cp  ./generated/0.0.1/linux/build/Release/addon-linux.node ./examples/node_modules/webgpu/generated/0.0.1/linux/build/Release/addon-linux.node
echo "Examples now using this WebGPU-NAPI addon instead of the npm version."

echo
echo "Initializing CTS"
cp generated/0.0.1/linux/build/Release/addon-linux.node cts/third_party/dawn/linux/index.node
cd cts
npm install
npx grunt pre

echo
echo "Done! Setting LD_LIBRARY_PATH for Dawn and returning to shell"
cd ..
LD_LIBRARY_PATH=$PWD/generated/0.0.1/linux/build/Release $SHELL
