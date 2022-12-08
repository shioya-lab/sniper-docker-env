FROM ubuntu:20.04
# Necessary for tzdata

ENV DEBIAN_FRONTEND=noninteractive

ARG TZ_ARG=UTC
ENV TZ=${TZ_ARG}

ARG RISCV_ARG=/riscv/
ENV RISCV=${RISCV_ARG}

# Add i386 support for support for Pin
RUN apt-get autoclean
RUN dpkg --add-architecture i386

RUN apt-get update && apt-get install -y \
    python \
    screen \
    tmux \
    binutils \
    libc6:i386 \
    libncurses5:i386 \
    libstdc++6:i386 \
 && rm -rf /var/lib/apt/lists/*
# For building Sniper
RUN apt-get update && apt-get install -y \
    automake \
    build-essential \
    curl \
    wget \
    libboost-dev \
    libsqlite3-dev \
    zlib1g-dev \
    libbz2-dev \
 && rm -rf /var/lib/apt/lists/*
# For building RISC-V Tools
RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    autotools-dev \
    bc \
    bison \
    curl \
    device-tree-compiler \
    flex \
    gawk \
    gperf \
    libexpat-dev \
    libgmp-dev \
    libmpc-dev \
    libmpfr-dev \
    libtool \
    libusb-1.0-0-dev \
    patchutils \
    pkg-config \
    texinfo \
    zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*
# Helper utilities
RUN apt-get update && apt-get install -y \
    gdb \
    gfortran \
    git \
    g++-9 \
    vim \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    emacs \
    zsh \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y cmake
WORKDIR /tmp/
RUN git clone https://github.com/llvm/llvm-project.git -b release/15.x --depth 1 && \
	cd llvm-project && \
	mkdir build && cd build && \
	cmake -G Makefile \
	      -DDEFAULT_SYSROOT=${RISCV}/riscv64-unknown-elf \
	      -DCMAKE_BUILD_TYPE="Release" \
          -DCMAKE_INSTALL_PREFIX=${RISCV} \
	      -DLLVM_TARGETS_TO_BUILD="host;RISCV" \
	      -DLLVM_ENABLE_PROJECTS="clang" ../llvm && \
    make -j$(nproc) && \
    make install && \
    cd ../ & rm -rf  build

# # ---------------------------------
# # RISC-V tools (spike / pk) install
# # ---------------------------------
# RUN apt install libboost-dev libboost-tools-dev
#
# RUN echo $RISCV
# ENV PATH $PATH:$RISCV/bin
# ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$RISCV/lib
#
# RUN git clone https://github.com/riscv-software-src/riscv-isa-sim.git --recurse-submodules --depth 1 && \
#     cd riscv-isa-sim && \
#     ./configure --prefix=$RISCV --without-boost --without-boost-asio --without-boost-regex && \
#     make -j$(nproc) && \
#     make install
#
# RUN git clone https://github.com/riscv-collab/riscv-gnu-toolchain.git -b rvv-next --depth 1 && \
#     cd riscv-gnu-toolchain && \
#     mkdir build && cd build && \
#     ../configure --prefix=$RISCV && \
#     make -j$(nproc) && \
#     make install && \
#     cd ../ && rm -rf build
#
# RUN git clone https://github.com/riscv-software-src/riscv-pk.git --recurse-submodules --depth 1 && \
#     cd riscv-pk && \
#     mkdir -p build && \
#     cd build && \
#     ../configure --prefix=$RISCV --host riscv64-unknown-elf && \
#     make -j$(nproc) && \
#     make install && \
#     cd ../ && rm -rf build
#
# RUN git clone https://github.com/riscv-software-src/riscv-tests.git --recurse-submodules --depth 1 && \
#     cd riscv-tests && \
#     mkdir -p build && \
#     cd build && \
#     ../configure --prefix=$RISCV && \
#     make -j$(nproc) && \
#     make install && \
#     cd ../ && rm -rf build

RUN echo $RISCV
