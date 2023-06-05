FROM ubuntu:jammy

ARG VERSION

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
RUN ./tools/dev/v8gen.py x64.release -- v8_monolithic=true \
   v8_use_external_startup_data=false \
   use_custom_libcxx=false \
   treat_warnings_as_errors=false
RUN ninja -C out.gn/x64.release v8_monolith
RUN ./tools/dev/v8gen.py x64.debug -- v8_monolithic=true \
   v8_use_external_startup_data=false \
   use_custom_libcxx=false \
   treat_warnings_as_errors=false \
   is_component_build=false
RUN ninja -C out.gn/x64.debug v8_monolith
RUN ./build/linux/sysroot_scripts/install-sysroot.py --arch=arm64
RUN gn gen out.gn/arm64.release --args='target_cpu="arm64" v8_monolithic=true v8_static_library=true is_debug=false is_official_build=false treat_warnings_as_errors=false v8_use_external_startup_data=false use_custom_libcxx=false'
RUN ninja -C out.gn/arm64.release v8_monolith
RUN gn gen out.gn/arm64.debug --args='target_cpu="arm64" v8_monolithic=true v8_static_library=true is_debug=false is_official_build=false treat_warnings_as_errors=false v8_use_external_startup_data=false use_custom_libcxx=false is_component_build=false'
RUN ninja -C out.gn/arm64.debug v8_monolith

# v8 monolith x64 release is located under: /build/v8/v8/out.gn/x64.release/obj/libv8_monolith.a
# v8 monolith x64 debug is located under: /build/v8/v8/out.gn/x64.debug/obj/libv8_monolith.a
# v8 monolith arm64 release is located under: /build/v8/v8/out.gn/arm64.release/obj/libv8_monolith.a
# v8 monolith arm64 debug is located under: /build/v8/v8/out.gn/arm64.debug/obj/libv8_monolith.a
