# sniper-docker-env

Sniperのビルドとシミュレーション実行用の環境群

## Related repositories

```
sniper-docker-env
  |- sniper         : Cycle-accurate simulator
  |- rv8            : RV8: RISC-V instruction decoder, used in Sniper
  |- riscv-isa-sim  : RISC-V Functional simulator with SIFT generation
  |- sniper2mcpat   : Scripts to measure energy
  |- vector_benches : Vector benchmarks
     |- microbenchmarks : Small vector testcases, using RVV intrinsics
     |- rivec1.0        : RiVec benchmarks (also includes SPMV)
```

## sniper-docker-env files and scripts

```
download_env.sh : Download all related repositories. It is eligible to execute it the first time.
build_env.sh    : Build all of related repositories
```

## Steps to build enivironment

### Make Docker image

```sh
$ make all # Road Dockerfile and make environment
$ make run # Go into docker container
```

### Build simulation environment

Following commands are expected to be executed in Docker container.

```sh
# Following commands are expected to be executed in Docker container.

$ ./download_env.sh
$ cp /home/kimura/work/sniper/sniper/pin-3.18-98332-gaebd7b1e6-gcc-linux.tar.gz sniper/
$ tar xvfz sniper/pin-3.18-98332-gaebd7b1e6-gcc-linux.tar.gz     # Extract pin files into head directory of sniper
$ ./build_env.sh   # Build rv8, sniper, riscv-isa-sim
```

### Execute simulation

- Microbenchmarks

```sh
# Following commands are expected to be executed in Docker container.

$ cd vector_benches/microbenchmarks
$ make -j$(nproc) VLEN={128,512}
```

- RiVec

```sh
# Following commands are expected to be executed in Docker container.

$ cd vector_benches/rivec1.0
$ make -j $(nproc) VLEN={128,512}
```

