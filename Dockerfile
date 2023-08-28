FROM ubuntu:jammy

ARG VERSION
ARG BUILD_TYPE
ARG ARCH

WORKDIR /build

RUN apt-get update -qq
RUN apt-get install -yqq git openssl wget python3 xz-utils lsb-release sudo dialog apt-utils g++-aarch64-linux-gnu file locales pkg-config

RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

ENV PATH="${PATH}:/build/depot_tools/"

RUN gclient
RUN mkdir v8; cd v8; fetch v8

# for tz config, see https://serverfault.com/questions/683605/docker-container-time-timezone-will-not-reflect-changes
ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR v8/v8/ 
RUN git checkout ${VERSION}
RUN sed -i 's/"--short"].decode().strip())/"--short"]).decode().strip()/g' ./build/install-build-deps.py
RUN sed -i 's/"\/sbin\/init"].decode()):/"\/sbin\/init"]).decode():/g' ./build/install-build-deps.py
# not need to install snap.
RUN sed -i 's/packages.append("snapcraft")/pass/g' ./build/install-build-deps.py
RUN ./build/install-build-deps.sh --no-prompt
COPY build_linux_${ARCH}.${BUILD_TYPE}.bash .
RUN /bin/bash ./build_linux_${ARCH}.${BUILD_TYPE}.bash

# v8 monolith x64 release is located under: /build/v8/v8/out.gn/x64.release/obj/libv8_monolith.a
# v8 monolith x64 debug is located under: /build/v8/v8/out.gn/x64.debug/obj/libv8_monolith.a
# v8 monolith arm64 release is located under: /build/v8/v8/out.gn/arm64.release/obj/libv8_monolith.a
# v8 monolith arm64 debug is located under: /build/v8/v8/out.gn/arm64.debug/obj/libv8_monolith.a
