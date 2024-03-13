# A Makefile to build the octopus container in debian.

# EXAMPLE: make stable
# EXAMPLE: make develop
# EXAMPLE: make stable VERSION_OCTOPUS=12.0
VERSION_OCTOPUS?=14.0


# One can run the tests in the container after compiling the code
# by setting the CHECK_LEVEL variable
# 0: no checks
# 1: check-short
# 2: check-long
# 3: check-short and check-long

# Example:
# make stable CHECK_LEVEL=3
# make develop CHECK_LEVEL=0

CHECK_LEVEL ?= 0

stable:
	docker build -f Dockerfile --build-arg VERSION_OCTOPUS=${VERSION_OCTOPUS} --build-arg CHECK_LEVEL=${CHECK_LEVEL} -t octopus .

develop:
	docker build -f Dockerfile --build-arg VERSION_OCTOPUS=develop --build-arg CHECK_LEVEL=${CHECK_LEVEL} -t octopus-develop .

.PHONY: stable develop dockerhub-update-multiarch

# multiarch image for DockerHub. Docker buildkit allows cross-compilation of Docker images.
# Tested by running the following on an M2 machine.
dockerhub-update-multiarch:
	@echo "If the container builds successfully, do this to push to dockerhub:"
	@echo "Run 'docker login'"
	@#if no builder exists yet:
	docker buildx create --name container --driver=docker-container
	@# do the actual multi-platform build, and push to DockerHub
	docker buildx build -f Dockerfile --build-arg VERSION_OCTOPUS=${VERSION_OCTOPUS} \
				--tag fangohr/octopus:${VERSION_OCTOPUS} \
			 	--tag fangohr/octopus:latest \
				--platform linux/arm64,linux/amd64 \
				--builder container \
				--push .


