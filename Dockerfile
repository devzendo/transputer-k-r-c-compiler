FROM i386/debian:bookworm-slim

RUN set -ex; apt-get update
#
# Make and other essentials
#
RUN set -ex; apt-get install -y build-essential make git sudo
