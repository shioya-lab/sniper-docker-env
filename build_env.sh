#!/bin/sh

export RV8_HOME=${PWD}/rv8
export SNIPER_ROOT=${PWD}/sniper

echo $RV8_HOME

cd sniper
make clean
tools_dir=`readlink -f ./pin_kit/source/tools`
echo ${tools_dir}
make TOOLS_ROOT=${tools_dir} BUILD_RISCV=1 -j$(nproc) RV8_HOME=$RV8_HOME 2>&1 | tee sniper_build.log

cd ../rv8
make clean
make -j$(nproc) SNIPER_ROOT=$SNIPER_ROOT 2>&1 | tee rv8_build.log

cd ../sniper
make BUILD_RISCV=1 -j$(nproc) RV8_HOME=$RV8_HOME 2>&1 | tee sniper_build.log

cd ../riscv-isa-sim
make clean
./configure --prefix=${RISCV}  --without-boost --without-boost-asio --without-boost-regex --with-sift=${SNIPER_ROOT} --enable-commitlog
make -j$(nproc) 2>&1 | tee spike_build.log
