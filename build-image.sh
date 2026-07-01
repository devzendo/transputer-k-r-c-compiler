#!/bin/bash
set -euo pipefail

#
# Builds the transputer-k-r-c-compiler build image.
#
docker build --tag transputer-k-r-c-compiler:latest .