FROM ubuntu:focal

ARG VERSION

WORKDIR /build

RUN apt-get update -qq
RUN apt-get install -yqq git openssl wget python3 python xz-utils lsb-release sudo dialog apt-utils g++-aarch64-linux-gnu

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
RUN ./tools/dev/v8gen.py x64.release.sample
RUN ninja -C out.gn/x64.release.sample v8_monolith
RUN ./build/linux/sysroot_scripts/install-sysroot.py --arch=arm64
RUN ./tools/dev/v8gen.py arm64.release -- is_clang=false treat_warnings_as_errors=false
RUN ninja -C out.gn/arm64.release v8_monolith

# v8 monolith is located under: /build/v8/v8/out.gn/x64.release.sample/obj/libv8_monolith.a
# v8 monolith is located under: /build/v8/v8/out.gn/arm64.release.sample/obj/libv8_monolith.a