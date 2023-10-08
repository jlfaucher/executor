Debug dynamic library
    cargo build -p icu_capi_cdylib --all-features
    clang test.c -L../../../../../target/debug -licu_capi_cdylib -ldl -lpthread -lm -g
    clang++ -std=c++17 test.cpp -L../../../../../target/debug -licu_capi_cdylib -ldl -lpthread -lm -g

Release dynamic library
    cargo build -p icu_capi_cdylib --all-features --release
    clang test.c -L../../../../../target/release -licu_capi_cdylib -ldl -lpthread -lm
    clang++ -std=c++17 test.cpp -L../../../../../target/release -licu_capi_cdylib -ldl -lpthread -lm

jlf 2023, Oct 06
HUGE INCREASE IN SIZE:
libicu_capi_cdylib.dylib
    v1.2         7.6 MB
    v1.3.2      25.1 MB
