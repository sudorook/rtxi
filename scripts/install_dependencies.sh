#! /bin/bash
set -eu

#
# The Real-Time eXperiment Interface (RTXI)
#
# Copyright (C) 2011 Georgia Institute of Technology, University of Utah, Weill
# Cornell Medical College
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.
#
# Created by Yogi Patel <yapatel@gatech.edu> 2014.1.31
#

if ! id | grep -q root; then
  echo "Must run script as root; try again with ./install_dependencies.sh."
  exit 1
fi

# Set directory variable for compilation
DIR=$PWD
ROOT=${DIR}/../
DEPS=${ROOT}/deps

# Install RTXI dependencies
echo "-----> Installing dependencies..."
apt update
apt -y upgrade
sed -i '/deb-src/s/^# //' /etc/apt/sources.list
apt update
apt -y install \
  autotools-dev automake libtool kernel-package gcc g++ gdb fakeroot crash \
  kexec-tools makedumpfile kernel-wedge libncurses5-dev libelf-dev \
  binutils-dev libgsl0-dev libboost-dev git lshw stress libqt5svg5-dev \
  libqt5opengl5 libqt5gui5 libqt5core5a libqt5xml5 qt5-default \
  qttools5-dev-tools qttools5-dev libhdf5-dev libmarkdown2-dev cmake
apt -y build-dep linux
echo "-----> Package dependencies installed."

# Install libgit2 from source
echo "-----> Installing libgit2..."
cd $DEPS
if [[ $(lsb_release -sc) == "bionic" ]] || \
   [[ $(lsb_release -sc) == "trusty" ]] || \
   [[ $(lsb_release -sc) == "focal" ]]; then
  sudo apt-get install -y libgit2-dev
else
  rm -rf libgit2 # in case libgit2 repo is there from previous install attempt
  git clone --depth 1 https://github.com/libgit2/libgit2.git
  mkdir -p libgit2/build && cd libgit2/build
  cmake .. -DCURL=OFF
  cmake --build . --target install
  ldconfig
fi
echo "-----> libgit2 installed."

# Install Qwt package if available in repos, compile if not.
echo "-----> Installing qwt..."
if [[ $(apt-cache show libqwt-qt5-dev) > /dev/null ]]; then
  apt-get -y install libqwt-qt5-dev
else
  cd ${DEPS}/qwt
  git submodule update --init .
  qmake qwt.pro
  make -sj`nproc` && make install
  ldconfig
fi
echo "-----> Qwt installed."

echo "-----> Done."
