ifeq ($(LLVM),15)
	LLVM_DOCKER_OPT =
else
	LLVM_DOCKER_OPT = -llvm16
endif

UBUNTU_VERSION?=20.04
DOCKER_IMAGE ?= msyksphinz/ubuntu:$(UBUNTU_VERSION)-work-sniper-$(USER)$(LLVM_DOCKER_OPT)
DOCKER_FILE?=Dockerfile-ubuntu-$(UBUNTU_VERSION)
DOCKER_FILES=$(wildcard Dockerfile*)
# For use with --no-cache, etc.
DOCKER_BUILD_OPT ?=
# Reconstruct the timezone for tzdata
TZFULL=$(subst /, ,$(shell readlink /etc/localtime))
TZ=$(word $(shell expr $(words $(TZFULL)) - 1 ),$(TZFULL))/$(word $(words $(TZFULL)),$(TZFULL))


all: $(DOCKER_FILE).build

# Use a .PHONY target to build all of the docker images if requested
Dockerfile%.build: Dockerfile
	docker build --build-arg TZ_ARG=$(TZ) $(DOCKER_BUILD_OPT) -f $(<) -t $(DOCKER_IMAGE) .

BUILD_ALL_TARGETS=$(foreach f,$(DOCKER_FILES),$(f).build)
build-all: $(BUILD_ALL_TARGETS)

docker-push:
	docker push $(DOCKER_IMAGE)

run-root:
	docker run --cap-add=SYS_PTRACE --security-opt="seccomp=unconfined" \
		--rm -it -v "${HOME}:${HOME}" $(DOCKER_IMAGE)

run:
	docker run --cap-add=SYS_PTRACE --security-opt="seccomp=unconfined" \
		--rm -it -v "${HOME}:${HOME}" --user $(shell id -u):$(shell id -g) -w "${PWD}" $(DOCKER_IMAGE)

.PHONY: all build-all run-root run
