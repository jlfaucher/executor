Xcode won't pause at this breakpoint
====================================

(Dialog with ChatGPT)

The breakpoint is not triggering when set from the source in xcode.  
The breakpoint appears with a dashed line, instead of a blue background, with this tooltip:  
"Xcode won't pause at this breakpoint because it has not been resolved". 

Workaround:  
I declare this breakpoint in `~/.lldbinit-Xcode`:  

```
br set -M raiseException 
```

To be complete, here is an extract of the build log: 

```
[ 70%] Building CXX object CMakeFiles/rexx.dir/interpreter/platform/unix/RexxMain.cpp.o
/usr/bin/clang++ -DDARWIN -DHAVE_CONFIG_H -DOPSYS_DARWIN -I/local/rexx/oorexx/executor/sandbox/jlf/trunk/api/platform/unix -arch arm64 -DCONCURRENCY_DEBUG -g -O0 -fno-inline -D_DEBUG -DDEBUG -g -std=gnu++11 -arch arm64 -fPIC -MD -MT CMakeFiles/rexx.dir/interpreter/platform/unix/RexxMain.cpp.o -MF CMakeFiles/rexx.dir/interpreter/platform/unix/RexxMain.cpp.o.d -o CMakeFiles/rexx.dir/interpreter/platform/unix/RexxMain.cpp.o -c /local/rexx/oorexx/executor/sandbox/jlf/trunk/interpreter/platform/unix/RexxMain.cpp
[ 70%] Linking CXX shared library lib/librexx.dylib
/Applications/CMake.app/Contents/bin/cmake -E cmake_link_script CMakeFiles/rexx.dir/link.txt --verbose=1
/usr/bin/clang++ -arch arm64 -DCONCURRENCY_DEBUG -g -O0 -fno-inline -D_DEBUG -DDEBUG -g -arch arm64 -dynamiclib -Wl,-headerpad_max_install_names -arch arm64 -compatibility_version 4.0.0 -o lib/librexx.4.dylib -install_name @rpath/librexx.4.dylib CMakeFiles/rexx.dir/interpreter/classes/ArrayClass.cpp.o CMakeFiles/rexx.dir/interpreter/platform/unix/RexxMain.cpp.o  -Wl,-rpath,/Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug/build/lib lib/librexxapi.4.dylib -lpthread -lresolv
/Applications/CMake.app/Contents/bin/cmake -E cmake_symlink_library lib/librexx.4.dylib lib/librexx.4.dylib lib/librexx.dylib
/Applications/CMake.app/Contents/bin/cmake -E chdir /Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug/build/lib ln -sf librexx.dylib librexx.3.dylib

Install the project...
/Applications/CMake.app/Contents/bin/cmake -P cmake_install.cmake
-- Install configuration: "Debug"
-- Installing: /Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug/delivery/lib/librexxapi.4.dylib
'/usr/bin/install_name_tool' '-add_rpath' '@executable_path/../lib' '/Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug/delivery/lib/librexxapi.4.dylib'
-- Installing: /Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug/delivery/lib/librexxapi.dylib
-- Installing: /Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug/delivery/lib/librexxapi.3.dylib
-- Installing: /Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug/delivery/lib/librexx.4.dylib
'/usr/bin/install_name_tool' '-delete_rpath' '/Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug/build/lib' '-add_rpath' '@executable_path/../lib' '/Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug/delivery/lib/librexx.4.dylib'
-- Installing: /Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug/delivery/lib/librexx.dylib
-- Installing: /Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug/delivery/lib/librexx.3.dylib
```

---

The key clues are:

* The breakpoint is *unresolved* (`dashed line`).
* The `.dylib` builds fine with `-g -O0`.
* You’re using **CMake** and **install_name_tool** moves the `.dylib` to a **delivery** directory.

Let’s unpack what’s going on — because this is a very classic CMake/Xcode debug mismatch.

---

## Root cause

Your source breakpoint doesn’t resolve because **the dylib that Xcode is loading at runtime is *not* the one you built with debug symbols.**

You can see from your log:

```
-- Installing: .../build/.../delivery/lib/librexx.4.dylib
```

The file being installed (copied) to `delivery/lib/` is the one your program **actually loads at runtime** (via `@rpath/librexx.4.dylib`).

However, during the “install” step, CMake and `install_name_tool` **don’t copy the `.dSYM`** or keep the original path to debug info, so the `.dylib` in `delivery/` no longer has DWARF symbols (it’s either stripped or copied without them).

That’s why Xcode shows:

> “Xcode won’t pause at this breakpoint because it has not been resolved.”

It can’t match the symbol address in the loaded dylib to your source line — the debug info it needs lives in the *build/lib/* version, not the *delivery/lib/* one.

---

## Verification

You can confirm this instantly with:

```bash
dwarfdump --uuid build/lib/librexx.4.dylib
dwarfdump --uuid delivery/lib/librexx.4.dylib
```

If they show **different UUIDs**, they are *not* the same binary — and Xcode’s LLDB doesn’t know where to find the symbols for the one that’s actually loaded.

---

### Bonus Tip

You can verify exactly which dylib LLDB loaded with:

```lldb
image list librexx.4.dylib
```

It’ll show the full path (likely the `delivery` one).  
Then you’ll know which copy needs symbols.

---

If you paste the output of:

```bash
image list librexx.4.dylib
```

from within your Xcode LLDB console, I can give you the exact `settings set target.debug-file-search-paths` line that will fix it.

### LLDB console

I have 2 .dSYM directories in the build directories:
```
/Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug$ find build -iname "*.dSYM"
build/CMakeFiles/4.1.2/CompilerIdC/a.out.dSYM
build/CMakeFiles/4.1.2/CompilerIdCXX/a.out.dSYM
```

The UUIDs displayed by dwarfdump are identical:
```
/Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug$ dwarfdump --uuid build/lib/librexx.4.dylib
UUID: 6581BD17-920C-477C-AF63-94D493BDA9FE (arm64) build/lib/librexx.4.dylib
/Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug$ dwarfdump --uuid delivery/lib/librexx.4.dylib
UUID: 6581BD17-920C-477C-AF63-94D493BDA9FE (arm64) delivery/lib/librexx.4.dylib
```
See below, the lldb command 'image list' display this UUID.


Additional info:  
When I use the workaround  
`br set -M raiseException`  
in `~/.lldbinit-Xcode`  
the breakpoint is triggered.  
I have access to lldb console inside xcode.  
The breakpoint is still considered unresolved by xcode! (displayed with dash lines).  
In the lldb console, I see
```
    Breakpoint 1: no locations (pending).
    Breakpoint set in dummy target, will get copied into future targets.
```
It's probably displayed at the begining, before the dylib is loaded.

Now some lldb commands...

```
(lldb) target list
Current targets:
* target #0: /Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug/build/bin/rexx ( arch=arm64-apple-macosx15.0.0, platform=host, pid=6239, state=stopped )
```
I'm not sure why the target is build/bin/rexx instead of delivery/bin/rexx.  
I double checked the xcode scheme, the select binary is delivery/bin/rexx

```
(lldb) image list
[  0] 3FEAA2A2-314F-4BF7-8CB0-98F6F61417A7 0x0000000100000000 /Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug/build/bin/rexx
[  1] 3247E185-CED2-36FF-9E29-47A77C23E004 0x000000019d730000 /usr/lib/dyld
[  2] 55755607-4E58-3649-8535-34880D1FDDA8 0x0000000100048000 /Applications/Xcode-26.1.0.app/Contents/Developer/usr/lib/libLogRedirect.dylib
[  3] 8072BD2E-E14D-32B0-B317-5D412B973C44 0x0000000100010000 /Applications/Xcode-26.1.0.app/Contents/Developer/usr/lib/libBacktraceRecording.dylib
[  4] 24F21DE0-08F2-3111-B8E2-09D2A7C576E2 0x0000000100220000 /Applications/Xcode-26.1.0.app/Contents/Developer/usr/lib/libMainThreadChecker.dylib
[  5] EB019F74-7D1B-37FF-B3E1-EB1AC6348BDB 0x000000010013c000 /Applications/Xcode-26.1.0.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Debugger/libViewDebuggerSupport.dylib
[  6] 072C7C60-2B6C-3E07-AA56-FD1750EADC2F 0x00000001abd33000 /usr/lib/libSystem.B.dylib
[  7] F0F65700-8E9D-35F3-AC32-952D363190BC 0x00000001abd13000 /usr/lib/system/libcompiler_rt.dylib
[  8] 213FA18D-6145-3615-8DB5-906B6863EAB9 0x00000001abd08000 /usr/lib/system/libcopyfile.dylib
[  9] 643ED232-CE19-3F63-8015-0AEE768C002F 0x000000019d9ea000 /usr/lib/libc++.1.dylib
[ 10] 2B900F8F-9EDE-3208-AB17-BD1385B5546A 0x00000001abd2d000 /usr/lib/system/libcache.dylib
[ 11] 01BCB3F7-AB89-30BD-87EE-91B291EADAE8 0x000000019dade000 /usr/lib/system/libdyld.dylib
[ 12] F3AB1D46-2417-49BF-B05E-50D8BAA2A682 0x0000000100094000 /Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug/build/lib/librexxapi.4.dylib
...
[ 41] 6581BD17-920C-477C-AF63-94D493BDA9FE 0x0000000100700000 /Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug/build/lib/librexx.4.dylib
      /System/Volumes/Data/Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug/delivery/lib/librexx.4.dylib.dSYM/Contents/Resources/DWARF/librexx.4.dylib
```
As said above, it's the UUID displayed by dwarfdump.  
Not sure why this path is listed: delivery/lib/librexx.4.dylib.dSYM  
I rechecked the delivery/lib/ directory, it does not contain any .dSYM files.

```
(lldb) image lookup -vn raiseException
7 matches found in /Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug/build/lib/librexx.4.dylib:
        Address: librexx.4.dylib[0x0000000000115534] (librexx.4.dylib.__TEXT.__text + 1128876)
        Summary: librexx.4.dylib`StreamInfo::raiseException(int) at StreamNative.cpp:350
         Module: file = "/Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug/build/lib/librexx.4.dylib", arch = "arm64"
    CompileUnit: id = {0x000000b3}, file = "/local/rexx/oorexx/executor/sandbox/jlf/trunk/interpreter/streamLibrary/StreamNative.cpp", language = "c++11"
       Function: id = {0x0091dcf3}, name = "StreamInfo::raiseException(int)", mangled = "_ZN10StreamInfo14raiseExceptionEi", range = [0x0000000100815534-0x0000000100815578)
       FuncType: id = {0x0091dcf3}, byte-size = 0, decl = StreamNative.hpp:97, compiler_type = "void (int)"
         Blocks: id = {0x0091dcf3}, range = [0x100815534-0x100815578)
      LineEntry: [0x0000000100815534-0x000000010081554c): /local/rexx/oorexx/executor/sandbox/jlf/trunk/interpreter/streamLibrary/StreamNative.cpp:350
         Symbol: id = {0x0000774d}, range = [0x0000000100815534-0x0000000100815578), name="StreamInfo::raiseException(int)", mangled="_ZN10StreamInfo14raiseExceptionEi"
       Variable: id = {0x0091dd06}, name = "this", type = "StreamInfo *", valid ranges = <block>, location = DW_OP_breg31 WSP+8, decl =
       Variable: id = {0x0091dd10}, name = "err", type = "int", valid ranges = <block>, location = DW_OP_breg31 WSP+4, decl = StreamNative.cpp:349
        Address: librexx.4.dylib[0x000000000011585c] (librexx.4.dylib.__TEXT.__text + 1129684)
        Summary: librexx.4.dylib`StreamInfo::raiseException(int, _RexxObjectPtr*) at StreamNative.cpp:363
         Module: file = "/Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug/build/lib/librexx.4.dylib", arch = "arm64"
    CompileUnit: id = {0x000000b3}, file = "/local/rexx/oorexx/executor/sandbox/jlf/trunk/interpreter/streamLibrary/StreamNative.cpp", language = "c++11"
       Function: id = {0x0091df0a}, name = "StreamInfo::raiseException(int, _RexxObjectPtr*)", mangled = "_ZN10StreamInfo14raiseExceptionEiP14_RexxObjectPtr", range = [0x000000010081585c-0x00000001008158a8)
       FuncType: id = {0x0091df0a}, byte-size = 0, decl = StreamNative.hpp:98, compiler_type = "void (int, RexxObjectPtr)"
         Blocks: id = {0x0091df0a}, range = [0x10081585c-0x1008158a8)
      LineEntry: [0x000000010081585c-0x0000000100815878): /local/rexx/oorexx/executor/sandbox/jlf/trunk/interpreter/streamLibrary/StreamNative.cpp:363
         Symbol: id = {0x0000777d}, range = [0x000000010081585c-0x00000001008158a8), name="StreamInfo::raiseException(int, _RexxObjectPtr*)", mangled="_ZN10StreamInfo14raiseExceptionEiP14_RexxObjectPtr"
       Variable: id = {0x0091df1d}, name = "this", type = "StreamInfo *", valid ranges = <block>, location = DW_OP_fbreg -8, decl =
       Variable: id = {0x0091df27}, name = "err", type = "int", valid ranges = <block>, location = DW_OP_fbreg -12, decl = StreamNative.cpp:362
       Variable: id = {0x0091df35}, name = "sub1", type = "RexxObjectPtr", valid ranges = <block>, location = DW_OP_breg31 WSP+8, decl = StreamNative.cpp:362
        Address: librexx.4.dylib[0x00000000001158a8] (librexx.4.dylib.__TEXT.__text + 1129760)
        Summary: librexx.4.dylib`StreamInfo::raiseException(int, _RexxObjectPtr*, _RexxObjectPtr*) at StreamNative.cpp:377
         Module: file = "/Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug/build/lib/librexx.4.dylib", arch = "arm64"
    CompileUnit: id = {0x000000b3}, file = "/local/rexx/oorexx/executor/sandbox/jlf/trunk/interpreter/streamLibrary/StreamNative.cpp", language = "c++11"
       Function: id = {0x0091df43}, name = "StreamInfo::raiseException(int, _RexxObjectPtr*, _RexxObjectPtr*)", mangled = "_ZN10StreamInfo14raiseExceptionEiP14_RexxObjectPtrS1_", range = [0x00000001008158a8-0x00000001008158fc)
       FuncType: id = {0x0091df43}, byte-size = 0, decl = StreamNative.hpp:99, compiler_type = "void (int, RexxObjectPtr, RexxObjectPtr)"
         Blocks: id = {0x0091df43}, range = [0x1008158a8-0x1008158fc)
      LineEntry: [0x00000001008158a8-0x00000001008158c8): /local/rexx/oorexx/executor/sandbox/jlf/trunk/interpreter/streamLibrary/StreamNative.cpp:377
         Symbol: id = {0x00007781}, range = [0x00000001008158a8-0x00000001008158fc), name="StreamInfo::raiseException(int, _RexxObjectPtr*, _RexxObjectPtr*)", mangled="_ZN10StreamInfo14raiseExceptionEiP14_RexxObjectPtrS1_"
       Variable: id = {0x0091df56}, name = "this", type = "StreamInfo *", valid ranges = <block>, location = DW_OP_fbreg -8, decl =
       Variable: id = {0x0091df60}, name = "err", type = "int", valid ranges = <block>, location = DW_OP_fbreg -12, decl = StreamNative.cpp:376
       Variable: id = {0x0091df6e}, name = "sub1", type = "RexxObjectPtr", valid ranges = <block>, location = DW_OP_breg31 WSP+8, decl = StreamNative.cpp:376
       Variable: id = {0x0091df7b}, name = "sub2", type = "RexxObjectPtr", valid ranges = <block>, location = DW_OP_breg31 WSP+0, decl = StreamNative.cpp:376
        Address: librexx.4.dylib[0x000000000011593c] (librexx.4.dylib.__TEXT.__text + 1129908)
        Summary: librexx.4.dylib`StreamInfo::raiseException(int, _RexxObjectPtr*, _RexxObjectPtr*, _RexxObjectPtr*) at StreamNative.cpp:393
         Module: file = "/Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug/build/lib/librexx.4.dylib", arch = "arm64"
    CompileUnit: id = {0x000000b3}, file = "/local/rexx/oorexx/executor/sandbox/jlf/trunk/interpreter/streamLibrary/StreamNative.cpp", language = "c++11"
       Function: id = {0x0091dfcb}, name = "StreamInfo::raiseException(int, _RexxObjectPtr*, _RexxObjectPtr*, _RexxObjectPtr*)", mangled = "_ZN10StreamInfo14raiseExceptionEiP14_RexxObjectPtrS1_S1_", range = [0x000000010081593c-0x0000000100815998)
       FuncType: id = {0x0091dfcb}, byte-size = 0, decl = StreamNative.hpp:100, compiler_type = "void (int, RexxObjectPtr, RexxObjectPtr, RexxObjectPtr)"
         Blocks: id = {0x0091dfcb}, range = [0x10081593c-0x100815998)
      LineEntry: [0x000000010081593c-0x0000000100815960): /local/rexx/oorexx/executor/sandbox/jlf/trunk/interpreter/streamLibrary/StreamNative.cpp:393
         Symbol: id = {0x00007789}, range = [0x000000010081593c-0x0000000100815998), name="StreamInfo::raiseException(int, _RexxObjectPtr*, _RexxObjectPtr*, _RexxObjectPtr*)", mangled="_ZN10StreamInfo14raiseExceptionEiP14_RexxObjectPtrS1_S1_"
       Variable: id = {0x0091dfde}, name = "this", type = "StreamInfo *", valid ranges = <block>, location = DW_OP_fbreg -8, decl =
       Variable: id = {0x0091dfe8}, name = "err", type = "int", valid ranges = <block>, location = DW_OP_fbreg -12, decl = StreamNative.cpp:392
       Variable: id = {0x0091dff6}, name = "sub1", type = "RexxObjectPtr", valid ranges = <block>, location = DW_OP_breg31 WSP+24, decl = StreamNative.cpp:392
       Variable: id = {0x0091e003}, name = "sub2", type = "RexxObjectPtr", valid ranges = <block>, location = DW_OP_breg31 WSP+16, decl = StreamNative.cpp:392
       Variable: id = {0x0091e010}, name = "sub3", type = "RexxObjectPtr", valid ranges = <block>, location = DW_OP_breg31 WSP+8, decl = StreamNative.cpp:392
        Address: librexx.4.dylib[0x00000000001159e0] (librexx.4.dylib.__TEXT.__text + 1130072)
        Summary: librexx.4.dylib`StreamInfo::raiseException(int, _RexxObjectPtr*, _RexxObjectPtr*, _RexxObjectPtr*, _RexxObjectPtr*) at StreamNative.cpp:410
         Module: file = "/Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug/build/lib/librexx.4.dylib", arch = "arm64"
    CompileUnit: id = {0x000000b3}, file = "/local/rexx/oorexx/executor/sandbox/jlf/trunk/interpreter/streamLibrary/StreamNative.cpp", language = "c++11"
       Function: id = {0x0091e06e}, name = "StreamInfo::raiseException(int, _RexxObjectPtr*, _RexxObjectPtr*, _RexxObjectPtr*, _RexxObjectPtr*)", mangled = "_ZN10StreamInfo14raiseExceptionEiP14_RexxObjectPtrS1_S1_S1_", range = [0x00000001008159e0-0x0000000100815a44)
       FuncType: id = {0x0091e06e}, byte-size = 0, decl = StreamNative.hpp:101, compiler_type = "void (int, RexxObjectPtr, RexxObjectPtr, RexxObjectPtr, RexxObjectPtr)"
         Blocks: id = {0x0091e06e}, range = [0x1008159e0-0x100815a44)
      LineEntry: [0x00000001008159e0-0x0000000100815a08): /local/rexx/oorexx/executor/sandbox/jlf/trunk/interpreter/streamLibrary/StreamNative.cpp:410
         Symbol: id = {0x00007791}, range = [0x00000001008159e0-0x0000000100815a44), name="StreamInfo::raiseException(int, _RexxObjectPtr*, _RexxObjectPtr*, _RexxObjectPtr*, _RexxObjectPtr*)", mangled="_ZN10StreamInfo14raiseExceptionEiP14_RexxObjectPtrS1_S1_S1_"
       Variable: id = {0x0091e081}, name = "this", type = "StreamInfo *", valid ranges = <block>, location = DW_OP_fbreg -8, decl =
       Variable: id = {0x0091e08b}, name = "err", type = "int", valid ranges = <block>, location = DW_OP_fbreg -12, decl = StreamNative.cpp:409
       Variable: id = {0x0091e099}, name = "sub1", type = "RexxObjectPtr", valid ranges = <block>, location = DW_OP_breg31 WSP+24, decl = StreamNative.cpp:409
       Variable: id = {0x0091e0a6}, name = "sub2", type = "RexxObjectPtr", valid ranges = <block>, location = DW_OP_breg31 WSP+16, decl = StreamNative.cpp:409
       Variable: id = {0x0091e0b3}, name = "sub3", type = "RexxObjectPtr", valid ranges = <block>, location = DW_OP_breg31 WSP+8, decl = StreamNative.cpp:409
       Variable: id = {0x0091e0c1}, name = "sub4", type = "RexxObjectPtr", valid ranges = <block>, location = DW_OP_breg31 WSP+0, decl = StreamNative.cpp:409
        Address: librexx.4.dylib[0x0000000000115a94] (librexx.4.dylib.__TEXT.__text + 1130252)
        Summary: librexx.4.dylib`StreamInfo::raiseException(int, _RexxObjectPtr*, _RexxObjectPtr*, _RexxObjectPtr*, _RexxObjectPtr*, _RexxObjectPtr*) at StreamNative.cpp:428
         Module: file = "/Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug/build/lib/librexx.4.dylib", arch = "arm64"
    CompileUnit: id = {0x000000b3}, file = "/local/rexx/oorexx/executor/sandbox/jlf/trunk/interpreter/streamLibrary/StreamNative.cpp", language = "c++11"
       Function: id = {0x0091e12c}, name = "StreamInfo::raiseException(int, _RexxObjectPtr*, _RexxObjectPtr*, _RexxObjectPtr*, _RexxObjectPtr*, _RexxObjectPtr*)", mangled = "_ZN10StreamInfo14raiseExceptionEiP14_RexxObjectPtrS1_S1_S1_S1_", range = [0x0000000100815a94-0x0000000100815b00)
       FuncType: id = {0x0091e12c}, byte-size = 0, decl = StreamNative.hpp:102, compiler_type = "void (int, RexxObjectPtr, RexxObjectPtr, RexxObjectPtr, RexxObjectPtr, RexxObjectPtr)"
         Blocks: id = {0x0091e12c}, range = [0x100815a94-0x100815b00)
      LineEntry: [0x0000000100815a94-0x0000000100815ac0): /local/rexx/oorexx/executor/sandbox/jlf/trunk/interpreter/streamLibrary/StreamNative.cpp:428
         Symbol: id = {0x00007799}, range = [0x0000000100815a94-0x0000000100815b00), name="StreamInfo::raiseException(int, _RexxObjectPtr*, _RexxObjectPtr*, _RexxObjectPtr*, _RexxObjectPtr*, _RexxObjectPtr*)", mangled="_ZN10StreamInfo14raiseExceptionEiP14_RexxObjectPtrS1_S1_S1_S1_"
       Variable: id = {0x0091e13f}, name = "this", type = "StreamInfo *", valid ranges = <block>, location = DW_OP_fbreg -8, decl =
       Variable: id = {0x0091e149}, name = "err", type = "int", valid ranges = <block>, location = DW_OP_fbreg -12, decl = StreamNative.cpp:427
       Variable: id = {0x0091e157}, name = "sub1", type = "RexxObjectPtr", valid ranges = <block>, location = DW_OP_fbreg -24, decl = StreamNative.cpp:427
       Variable: id = {0x0091e164}, name = "sub2", type = "RexxObjectPtr", valid ranges = <block>, location = DW_OP_breg31 WSP+32, decl = StreamNative.cpp:427
       Variable: id = {0x0091e171}, name = "sub3", type = "RexxObjectPtr", valid ranges = <block>, location = DW_OP_breg31 WSP+24, decl = StreamNative.cpp:427
       Variable: id = {0x0091e17f}, name = "sub4", type = "RexxObjectPtr", valid ranges = <block>, location = DW_OP_breg31 WSP+16, decl = StreamNative.cpp:427
       Variable: id = {0x0091e18d}, name = "sub5", type = "RexxObjectPtr", valid ranges = <block>, location = DW_OP_breg31 WSP+8, decl = StreamNative.cpp:427
        Address: librexx.4.dylib[0x00000000000b9d3c] (librexx.4.dylib.__TEXT.__text + 754100)
        Summary: librexx.4.dylib`RexxActivity::raiseException(long, RexxString*, RexxArray*, RexxObject*) at RexxActivity.cpp:1043
         Module: file = "/Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug/build/lib/librexx.4.dylib", arch = "arm64"
    CompileUnit: id = {0x00000055}, file = "/local/rexx/oorexx/executor/sandbox/jlf/trunk/interpreter/concurrency/RexxActivity.cpp", language = "c++11"
       Function: id = {0x0047ef16}, name = "RexxActivity::raiseException(long, RexxString*, RexxArray*, RexxObject*)", mangled = "_ZN12RexxActivity14raiseExceptionElP10RexxStringP9RexxArrayP10RexxObject", range = [0x00000001007b9d3c-0x00000001007b9ebc)
       FuncType: id = {0x0047ef16}, byte-size = 0, decl = RexxActivity.hpp:150, compiler_type = "void (wholenumber_t, class RexxString *, class RexxArray *, class RexxObject *)"
         Blocks: id = {0x0047ef16}, range = [0x1007b9d3c-0x1007b9ebc)
      LineEntry: [0x00000001007b9d3c-0x00000001007b9d64): /local/rexx/oorexx/executor/sandbox/jlf/trunk/interpreter/concurrency/RexxActivity.cpp:1043
         Symbol: id = {0x0000572a}, range = [0x00000001007b9d3c-0x00000001007b9ebc), name="RexxActivity::raiseException(long, RexxString*, RexxArray*, RexxObject*)", mangled="_ZN12RexxActivity14raiseExceptionElP10RexxStringP9RexxArrayP10RexxObject"
       Variable: id = {0x0047ef29}, name = "this", type = "RexxActivity *", valid ranges = <block>, location = DW_OP_fbreg -8, decl =
       Variable: id = {0x0047ef33}, name = "errcode", type = "wholenumber_t", valid ranges = <block>, location = DW_OP_fbreg -16, decl = RexxActivity.cpp:1030
       Variable: id = {0x0047ef40}, name = "description", type = "RexxString *", valid ranges = <block>, location = DW_OP_fbreg -24, decl = RexxActivity.cpp:1030
       Variable: id = {0x0047ef4d}, name = "additional", type = "RexxArray *", valid ranges = <block>, location = DW_OP_fbreg -32, decl = RexxActivity.cpp:1030
       Variable: id = {0x0047ef5a}, name = "result", type = "RexxObject *", valid ranges = <block>, location = DW_OP_breg31 WSP+40, decl = RexxActivity.cpp:1030
       Variable: id = {0x0047ef67}, name = "topFrame", type = "RexxActivationBase *", valid ranges = <block>, location = DW_OP_breg31 WSP+32, decl = RexxActivity.cpp:1053
       Variable: id = {0x0047ef74}, name = "activation", type = "RexxActivation *", valid ranges = <block>, location = DW_OP_breg31 WSP+24, decl = RexxActivity.cpp:1055
1 match found in /System/Library/PrivateFrameworks/MobileInstallation.framework/Versions/A/MobileInstallation:
        Address: MobileInstallation[0x00000001acd1c000] (MobileInstallation.__TEXT.__text + 48520)
        Summary: MobileInstallation`-[MIInstallerClient raiseException]
         Module: file = "/System/Library/PrivateFrameworks/MobileInstallation.framework/Versions/A/MobileInstallation", arch = "arm64e"
         Symbol: id = {0x00000108}, range = [0x00000001ca380000-0x00000001ca380180), name="-[MIInstallerClient raiseException]"
```

So looks good...  
lldb inside xcode works correctly.  
But xcode does not.

---

Your debug info is there and valid (`image lookup` shows perfect DWARF linkage, file paths, line numbers, etc.).  
The issue now is specifically that **Xcode’s UI layer** is not resolving breakpoints set in the source editor to the *dynamic library’s* symbols — even though `lldb` itself *does* (once the image is loaded).

That’s a subtle but well-known behavior of Xcode on macOS when debugging shared libraries (.dylib) built outside of the Xcode build system.

Let’s unpack why — and how to fix it properly.

---

### What’s actually happening

1. When you start your executable (`rexx`), Xcode launches `lldb` with a dummy target.
2. Your breakpoints in `RexxActivity.cpp` belong to `librexx.4.dylib`, but that dylib is **not yet loaded** at launch.
3. Xcode tries to *resolve* breakpoints *immediately* by querying `lldb` — it fails (since the image isn’t loaded yet), and marks them as *unresolved* (dashed).
4. Later, when `librexx.4.dylib` loads, `lldb` *does* map your function and can hit the breakpoint (that’s why your manual `.lldbinit-Xcode` breakpoint works), but Xcode’s UI doesn’t rebind it because it thinks the module path doesn’t match (build vs. delivery).

So this is **not** a DWARF corruption, nor missing symbols — it’s a *symbol resolution timing/path mismatch issue*.

---

### The two main underlying causes

#### 1. **Path mismatch between DWARF source and your filesystem**

DWARF encodes absolute source paths like:

```
/local/rexx/oorexx/executor/sandbox/jlf/trunk/interpreter/concurrency/RexxActivity.cpp
```

But on your system that file is actually:

```
/Users/Shared/local/rexx/oorexx/executor/sandbox/jlf/trunk/interpreter/concurrency/RexxActivity.cpp
```

So even if symbols are loaded, **Xcode can’t map them to the editor buffer** because the paths differ.

✅ **Fix:** Add a source path remapping entry to your scheme or lldbinit:

```
settings set target.source-map /local/rexx /Users/Shared/local/rexx
```

You can test this in Xcode’s *Debug → Debug Workflow → Sources* settings or directly in `~/.lldbinit-Xcode`.  
After adding that, relaunch Xcode and run again — your breakpoints should now resolve and appear solid blue.

---

#### 2. **Image load timing (pending breakpoints)**

Because `librexx.4.dylib` is dynamically loaded later, Xcode doesn’t auto-resolve breakpoints against it until you set the breakpoint *after the image is loaded*.

✅ **Fix:** Add this to `~/.lldbinit-Xcode`:

```lldb
settings set target.load-script-from-symbol-file true
settings set target.source-map /local/rexx /Users/Shared/local/rexx
breakpoint set -n RexxActivity::raiseException
```

or (if you want breakpoints to auto-bind when the image loads):

```lldb
settings set target.resolve-lazy-breakpoints true
```

---

### Recommended minimal fix steps

1. Edit `~/.lldbinit-Xcode` and add:

   ```lldb
   settings set target.source-map /local/rexx /Users/Shared/local/rexx
   settings set target.resolve-lazy-breakpoints true
   ```
2. Relaunch Xcode.
3. Clean + rebuild.
4. Set your breakpoints normally in source.

They should turn **solid blue** now (no longer dashed), and Xcode will show source rather than disassembly when you hit them.

---

### Optional sanity checks

To confirm your mapping works:

```lldb
(lldb) settings show target.source-map
```

→ should list your remap.

To check module load events:

```lldb
(lldb) breakpoint list
(lldb) image list librexx.4.dylib
```

If Xcode’s debugger console prints something like:

```
Breakpoint 1: where = librexx.4.dylib`RexxActivity::raiseException, address = 0x...
```

then you’re good — the breakpoint is resolved.

---

Here’s a clean `.lldbinit-Xcode` template you can keep for future reference:

```lldb
# ~/.lldbinit-Xcode
# -----------------------------------------------------------
# Enable lazy breakpoint resolution (important for dylibs)
settings set target.resolve-lazy-breakpoints true

# Allow loading helper scripts embedded in symbol files
settings set target.load-script-from-symbol-file true

# Map source paths between build system and local filesystem
settings set target.source-map /local/rexx /Users/Shared/local/rexx

# Optional: point LLDB to debug builds if stripped libs are installed elsewhere
settings set target.debug-file-search-paths /Users/Shared/local/rexx/oorexx/build/executor.master/sandbox/jlf/trunk/macos-arm64/clang/debug/build/lib

# Example: always break on your exception handler for safety
breakpoint set -M raiseException
# -----------------------------------------------------------
```

This makes your Xcode debugger behave *exactly* like a full native build — with breakpoints resolving even for late-loaded libraries and relocated source trees.
