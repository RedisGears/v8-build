./build/linux/sysroot_scripts/install-sysroot.py --arch=arm64
gn gen out.gn/arm64.release --args='target_cpu="arm64" v8_monolithic=true v8_static_library=true is_debug=false is_official_build=false treat_warnings_as_errors=false v8_use_external_startup_data=false use_custom_libcxx=false'
ninja -C out.gn/arm64.release v8_monolith
