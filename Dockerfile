FROM ubuntu:focal

ARG BUILD_TYPE "release"
ARG VERSION "10.4.132.20"
ARG ARCH "x64"

WORKDIR /build

RUN apt-get update -qq
RUN apt-get install -yqq git openssl wget python3 xz-utils lsb-release sudo dialog apt-utils

RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

ENV PATH="${PATH}:/build/depot_tools/"

RUN gclient
RUN mkdir v8; cd v8; fetch v8

# for tz config, see https://serverfault.com/questions/683605/docker-container-time-timezone-will-not-reflect-changes
ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR v8/v8/ 
RUN git checkout ${VERSION}
RUN sed -i 's/${dev_list} snapcraft/${dev_list}/g' ./build/install-build-deps.sh
RUN ./build/install-build-deps.sh --no-prompt
RUN ./tools/dev/gm.py x64.release
RUN ./tools/dev/gm.py arm64.release
RUN ./tools/dev/v8gen.py x64.release.sample; ninja -C out.gn/x64.release.sample v8_monolith
RUN ./build/linux/sysroot_scripts/install-sysroot.py --arch=arm64
RUN ./tools/dev/v8gen.py arm64.release.sample; ninja -C out.gn/arm64.release.sample v8_monolith

# v8 monolith is located under: /build/v8/v8/out.gn/x64.release.sample/obj/libv8_monolith.a