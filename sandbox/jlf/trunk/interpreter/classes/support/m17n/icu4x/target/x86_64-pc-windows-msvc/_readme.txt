Debug dynamic library
    cargo build -p icu_capi_cdylib --all-features
    cl /Zi test.c ..\..\..\..\..\target\debug\icu_capi_cdylib.dll.lib userenv.lib advapi32.lib ws2_32.lib bcrypt.lib
    cl /Zi /std:c++20 /EHsc test.cpp ..\..\..\..\..\target\debug\icu_capi_cdylib.dll.lib userenv.lib advapi32.lib ws2_32.lib bcrypt.lib

Release dynamic library
    cargo build -p icu_capi_cdylib --all-features --release
    cl test.c ..\..\..\..\..\target\debug\icu_capi_cdylib.dll.lib userenv.lib advapi32.lib ws2_32.lib bcrypt.lib
    cl /std:c++20 /EHsc test.cpp ..\..\..\..\..\target\debug\icu_capi_cdylib.dll.lib userenv.lib advapi32.lib ws2_32.lib bcrypt.lib
