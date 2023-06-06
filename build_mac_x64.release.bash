cd v8/v8/
./tools/dev/v8gen.py x64.release -- v8_monolithic=true v8_use_external_startup_data=false use_custom_libcxx=false treat_warnings_as_errors=false
ninja -C out.gn/x64.release v8_monolith
