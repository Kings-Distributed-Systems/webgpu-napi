#!/bin/sh
#
# @file         build.sh
#               Builds the dawn library.
# @author       Jason Erb, jason@kingsds.network
# @author       Dominic Cerisano, dcerisano@kingsds.network
# @date         April 2020

set -e

OS="$(uname -s)"
echo "Building Dawn on OS \"${OS}\"..."

if [ ! -d depot_tools ]; then
  echo "Cloning depot tools..."
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
fi
export PATH=${PWD}/depot_tools:$PATH
if [ ! -d dawn ]; then
  echo "Fetching Dawn..."
  git clone https://dawn.googlesource.com/dawn dawn

fi

cd dawn
echo "Checking out ..."
git checkout 0b43a803bfb9fe4c426c7dbd7b618f61841dc47c

if [ "${OS}" = "Linux" ]; then
  echo "Installing Linux build dependencies..."
  cp scripts/standalone.gclient .gclient
fi
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

LD_LIBRARY_PATH=$PWD/generated/0.0.1/linux/build/Release $SHELL

