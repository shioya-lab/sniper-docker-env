#!/bin/sh

export RV8_HOME=${PWD}/rv8
export SNIPER_ROOT=${PWD}/sniper
export RISCV=/riscv/

echo $RV8_HOME

cd sniper
make clean
make BUILD_RISCV=1 DEBUG_SHOW_COMPILE=1 -j$(nproc) RV8_HOME=$RV8_HOME 2>&1 | tee sniper_build.log
