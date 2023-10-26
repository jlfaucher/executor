Prerequisite: install the clang component in Visual Studio (needed to build ring)
Use ARM64 Native Tools Command Prompt for VS 2022 (because must have clang in the PATH for ring)
E:
cd \local\Unicode\ICU4X\git
debug version:
    cargo build -p icu_capi_cdylib --all-features
    copy target\debug\icu_capi_cdylib.dll (and .exp, .lib, .pdb)
release version:
    cargo build -p icu_capi_cdylib --all-features --release
    copy target\release\icu_capi_cdylib.dll (and .exp, .lib, .pdb)
