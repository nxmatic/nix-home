#!/usr/bin/env bash

set -exu

#nerdctl build --platform linux/amd64 --build-arg frombuild=ubuntu --target ubuntu-nix -t pwn-amd64 -f ./Dockerfile .
#nerdctl build --platform linux/amd64 --build-arg frombuild=ubuntu --target ubuntu-nix-dev -t pwn-amd64-dev -f ./Dockerfile .

nerdctl rm -fv nixos-bootstrap && \
    nerdctl run --detach --privileged --name=nixos-bootstrap \
	    --device /dev/nbd0 \
	    --publish 2022:22 \
	    --workdir $(pwd) \
	    --mount type=bind,source="/dev",target="/dev~host" \
	    --mount type=bind,source="/Users/nxmatic",target=/Users/nxmatic \
	    --mount type=bind,source=/Volumes/GitHub,target=/Volumes/GitHub \
	    pwn-amd64-dev tail -f /dev/null

#nerdctl build --platform linux/arm/v7 --build-arg frombuild=ubuntu -t pwn-arm32v7 -f ./Dockerfile.multi .
#nerdctl build --platform linux/arm64 --build-arg frombuild=ubuntu -t pwn-arm64v8 -f ./Dockerfile.multi .

#docker run -v $(pwd):/work -w /work --rm --cap-add SYS_PTRACE -it pwn-amd64 bash
#docker run -v $(pwd):/work -w /work --rm --privileged -it pwn-amd64 bash
