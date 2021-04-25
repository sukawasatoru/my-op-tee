SHELL=/bin/bash
.SUFFIXES:

.PHONY: all
all:
	: do nothing.

BUILD_DOCKER_LABEL=latest
.PHONY: build-docker
build-docker:
	docker build -t ghcr.io/sukawasatoru/op-tee:$(BUILD_DOCKER_LABEL) .
