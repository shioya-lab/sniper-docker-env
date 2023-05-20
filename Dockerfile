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

# ---------------------------------
# RISC-V tools (spike / pk) install
# ---------------------------------
RUN echo $RISCV
ENV PATH $PATH:$RISCV/bin
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$RISCV/lib

RUN git clone https://github.com/riscv-software-src/riscv-isa-sim.git --recurse-submodules --depth 1 && \
    cd riscv-isa-sim && \
    ./configure --prefix=$RISCV --without-boost --without-boost-asio --without-boost-regex && \
    make -j$(nproc) && \
    make install

# RUN git clone https://github.com/riscv-collab/riscv-gnu-toolchain.git -b rvv-next --depth 1 && \
#     cd riscv-gnu-toolchain && \
#     mkdir build && cd build && \
#     ../configure --prefix=$RISCV && \
#     make -j$(nproc) && \
#     make install && \
#     cd ../ && rm -rf build


# ========================
# Build Official GCC-13.0
# ========================
WORKDIR /tmp/
# Binutils
RUN curl -L ftp://ftp.gnu.org/gnu/binutils/binutils-2.40.tar.gz | tar xz && \
    cd binutils-2.40 && \
    mkdir build && \
    cd build && \
    ../configure --prefix=${RISCV} \
            --target=riscv64-unknown-elf \
            --enable-languages=c,c++ \
            --disable-multilib && \
    make -j$(nproc) && \
    make install

# GCC-13
RUN curl -L http://ftp.tsukuba.wide.ad.jp/software/gcc/releases/gcc-13.1.0/gcc-13.1.0.tar.gz | tar xz && \
    mkdir -p gcc-13.1.0/build_rvv && \
	cd gcc-13.1.0/build_rvv && \
	../configure --prefix=${RISCV} \
	        --target=riscv64-unknown-elf \
	        --enable-languages=c,c++ \
	        --without-headers \
	        --with-newlib \
	        --disable-threads && \
    make -j$(nproc) all-gcc && \
	make install-gcc

# Newlib
RUN curl -L ftp://sourceware.org/pub/newlib/newlib-4.3.0.20230120.tar.gz | tar xz && \
    cd newlib-4.3.0.20230120 && \
    mkdir build && cd build && \
    ../configure --prefix=${RISCV} --target=riscv64-unknown-elf && \
    make -j$(nproc) && \
    make install

# GCC (2nd)
RUN mkdir gcc-13.1.0/build_rvv_2nd && \
    cd gcc-13.1.0/build_rvv_2nd && \
    ../configure --prefix=${RISCV} --target=riscv64-unknown-elf --enable-languages=c,c++ --with-newlib && \
    make -j$(nproc) && \
    make install




RUN git clone https://github.com/riscv-software-src/riscv-pk.git --recurse-submodules --depth 1 && \
    cd riscv-pk && \
    mkdir -p build && \
    cd build && \
    ../configure --prefix=$RISCV --host riscv64-unknown-elf && \
    make -j$(nproc) && \
    make install && \
    cd ../ && rm -rf build

RUN git clone https://github.com/riscv-software-src/riscv-tests.git --recurse-submodules --depth 1 && \
    cd riscv-tests && \
    mkdir -p build && \
    cd build && \
    ../configure --prefix=$RISCV && \
    make -j$(nproc) && \
    make install && \
    cd ../ && rm -rf build

RUN apt-get update && apt-get install -y cmake
WORKDIR /tmp/
RUN git clone https://github.com/llvm/llvm-project.git -b release/16.x --depth 1 && \
	cd llvm-project && \
	mkdir -p build && cd build && \
	cmake -G "Unix Makefiles" \
	      -DDEFAULT_SYSROOT=${RISCV}/riscv64-unknown-elf \
	      -DCMAKE_BUILD_TYPE="Release" \
          -DCMAKE_INSTALL_PREFIX=${RISCV} \
	      -DLLVM_TARGETS_TO_BUILD="host;RISCV" \
	      -DLLVM_ENABLE_PROJECTS="clang" ../llvm && \
    make -j$(nproc) && \
    make install && \
    cd ../ && rm -rf  build

RUN echo $RISCV
RUN apt-get update && apt-get install -y sqlite3
RUN apt-get update && apt-get install -y gnuplot
RUN apt-get update && apt-get install -y libdb-dev
RUN apt-get update && apt-get install -y libboost1.71-dev
RUN apt-get update && apt-get install -y build-essential cmake libboost-dev libboost-serialization-dev libboost-filesystem-dev libboost-iostreams-dev libboost-program-options-dev zlib1g-dev libquadmath0
