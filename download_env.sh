#!/bin/sh

if [ ! -d sniper ]; then
    git clone git@github-msyksphinz:msyksphinz-self/sniper.git
	cd sniper
	cp -r /home/kimura/work/sniper/pin-3.18-98332-gaebd7b1e6-gcc-linux .
	ln -s pin-3.18-98332-gaebd7b1e6-gcc-linux pin_kit
    cd -
fi

if [ ! -d rv8 ]; then
    git clone https://github.com/msyksphinz-self/rv8.git --recurse-submodules -b sift
fi

if [ ! -d riscv-isa-sim ]; then
    git clone https://github.com/msyksphinz-self/riscv-isa-sim.git -b sift
fi
