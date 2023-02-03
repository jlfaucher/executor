Debug dynamic library
    cargo build -p icu_capi_cdylib --all-features
    clang test.c -L../../../../../target/debug -licu_capi_cdylib -ldl -lpthread -lm -g
    clang++ -std=c++17 test.cpp -L../../../../../target/debug -licu_capi_cdylib -ldl -lpthread -lm -g

Release dynamic library
    cargo build -p icu_capi_cdylib --all-features --release
    clang test.c -L../../../../../target/release -licu_capi_cdylib -ldl -lpthread -lm
    clang++ -std=c++17 test.cpp -L../../../../../target/release -licu_capi_cdylib -ldl -lpthread -lm
