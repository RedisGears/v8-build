cd v8/v8/
./tools/dev/v8gen.py arm64.debug -- 'target_cpu="arm64" v8_monolithic=true v8_use_external_startup_data=false use_custom_libcxx=false treat_warnings_as_errors=false is_component_build=false'
ninja -C out.gn/arm64.debug v8_monolith
