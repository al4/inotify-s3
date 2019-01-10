# Makefile
SHELL := /bin/bash
BUILD_NUMBER ?= SNAPSHOT
PWD = $(shell pwd)

.DEFAULT_GOAL := docker
.PHONY: clean install test build docker publish

build: docker

docker:
	docker build \
		-t inotify-s3:$(BUILD_NUMBER) \
		.
