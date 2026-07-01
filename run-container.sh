#!/bin/bash
set -euf -o pipefail

# Starts the 32-bit container to be used for building the compiler, and starts the build.
UPONE="${PWD%/*}"
echo Container will have access to $UPONE
docker run --rm -v /run/host-services/ssh-auth.sock:/ssh-agent -e SSH_AUTH_SOCK="/ssh-agent" -v $UPONE:$UPONE -w $PWD --name transputer-k-r-c-compiler transputer-k-r-c-compiler:latest bash ./build-in-container.sh
