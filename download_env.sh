#!/bin/sh

if [ ! -d sniper ]; then
    git clone git@github.com:shioya-lab/sniper.git
	cd sniper
	cp -r /home/kimura/work/sniper/pin-3.18-98332-gaebd7b1e6-gcc-linux .
	ln -s pin-3.18-98332-gaebd7b1e6-gcc-linux pin_kit
    cd -
fi

if [ ! -d rv8 ]; then
    git clone git@github.com:shioya-lab/rv8.git --recurse-submodules -b sift
fi

if [ ! -d riscv-isa-sim ]; then
    git clone git@github.com:shioya-lab/sniper-riscv-isa-sim.git -b sift riscv-isa-sim
fi

if [ ! -d vector_benches ]; then
    git clone git@github.com:shioya-lab/vector_benches.git
fi


if [ ! -d sniper2mcpat ]; then
    git clone git@github.com:i4kimura/sniper2mcpat.git --recurse-submodules
fi
