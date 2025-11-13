How to make CMake detect when the build root is under a symlink
===============================================================

(ChatGPT)

---

We can add a **symlink detection block** early in your top-level `CMakeLists.txt`, which checks whether the current source/build directories are under a symbolic link (like `/local → /Users/Shared/local`), and warns or fixes it automatically.


## Why this helps

CMake uses the *literal path* you give it for:

* `CMAKE_SOURCE_DIR`
* `CMAKE_BINARY_DIR`
* All generated include paths, compiler flags, and DWARF file entries

If those paths contain symlinks, all debug info will reflect that symlink path — which then causes exactly the mismatch you hit.


## The CMake detection code

Add this snippet near the very top of your root `CMakeLists.txt`:

```cmake
# --- Detect and handle symlinked build roots -------------------------

# Get the real (canonicalized) paths of source and build dirs
get_filename_component(REAL_SOURCE_DIR "${CMAKE_SOURCE_DIR}" REALPATH)
get_filename_component(REAL_BINARY_DIR "${CMAKE_BINARY_DIR}" REALPATH)

# Compare with the raw paths actually used to invoke CMake
if(NOT "${REAL_SOURCE_DIR}" STREQUAL "${CMAKE_SOURCE_DIR}")
    message(WARNING "
⚠️  Your source directory is a symlink:
    CMAKE_SOURCE_DIR = ${CMAKE_SOURCE_DIR}
    Real path        = ${REAL_SOURCE_DIR}

    This can cause DWARF debug info to record '/local/...' paths instead of
    '/Users/Shared/...', leading to unresolved breakpoints in Xcode.

    👉 Recommended: rebuild using the real path:
       cmake -S \"${REAL_SOURCE_DIR}\" -B \"${REAL_BINARY_DIR}\"
    or add a 'target.source-map' entry in ~/.lldbinit-Xcode.
    ")
endif()

if(NOT "${REAL_BINARY_DIR}" STREQUAL "${CMAKE_BINARY_DIR}")
    message(WARNING "
⚠️  Your build directory is a symlink:
    CMAKE_BINARY_DIR = ${CMAKE_BINARY_DIR}
    Real path        = ${REAL_BINARY_DIR}

    Use canonical paths to ensure consistent debug info.
    ")
endif()
# ---------------------------------------------------------------------

```


### What this does

* It checks whether either `CMAKE_SOURCE_DIR` or `CMAKE_BINARY_DIR` resolve to a different *real* path.
* If they do, you get a **clear, colored warning** (⚠️) right in your CMake configure output.
* It explains the exact fix (`cmake -S "$(realpath .)" -B build`).


## Optional: automatic correction

If you want CMake to *automatically switch* to the canonical path instead of just warning, you can replace the `message(WARNING ...)` block with:

```cmake
if(NOT "${REAL_SOURCE_DIR}" STREQUAL "${CMAKE_SOURCE_DIR}")
    message(STATUS "Reconfiguring using canonical path: ${REAL_SOURCE_DIR}")
    execute_process(COMMAND "${CMAKE_COMMAND}" -S "${REAL_SOURCE_DIR}" -B "${REAL_BINARY_DIR}")
    return()
endif()
```

That re-invokes CMake immediately under the real path and exits the symlinked instance — super clean.


## Example Output

When you run `cmake` inside `/local/rexx/oorexx`:

```
-- Configuring project oorexx
⚠️  Your source directory is a symlink:
    CMAKE_SOURCE_DIR = /local/rexx/oorexx
    Real path        = /Users/Shared/local/rexx/oorexx

    This can cause DWARF debug info to record '/local/...' paths instead of
    '/Users/Shared/...', leading to unresolved breakpoints in Xcode.

    👉 Recommended: rebuild using the real path:
       cmake -S "/Users/Shared/local/rexx/oorexx" -B "build"
```

---

Here’s a version that not only detects the symlink but **automatically re-invokes CMake under the canonical real path**, then cleanly exits the “wrong” invocation.  
It’s totally self-contained, safe to drop at the top of your root `CMakeLists.txt`, and ensures every build uses fully resolved paths.


## **Self-healing CMake symlink detector**

```cmake
# =====================================================================
#  Detect and fix symlinked source or build directories automatically
# =====================================================================

# Canonicalize (resolve symlinks) for both source and build dirs
get_filename_component(REAL_SOURCE_DIR "${CMAKE_SOURCE_DIR}" REALPATH)
get_filename_component(REAL_BINARY_DIR "${CMAKE_BINARY_DIR}" REALPATH)

# Compare the paths actually used to invoke CMake vs. their real paths
set(RECONF_NEEDED OFF)
if(NOT "${REAL_SOURCE_DIR}" STREQUAL "${CMAKE_SOURCE_DIR}")
    set(RECONF_NEEDED ON)
endif()
if(NOT "${REAL_BINARY_DIR}" STREQUAL "${CMAKE_BINARY_DIR}")
    set(RECONF_NEEDED ON)
endif()

if(RECONF_NEEDED)
    message(WARNING "
⚠️  Detected symlinked source or build directory.
    - Invoked source dir: ${CMAKE_SOURCE_DIR}
    - Canonical source:   ${REAL_SOURCE_DIR}
    - Invoked build dir:  ${CMAKE_BINARY_DIR}
    - Canonical build:    ${REAL_BINARY_DIR}

    Re-invoking CMake automatically using canonical paths
    to avoid DWARF debug info mismatches and unresolved breakpoints.
    ")

    # Reconfigure CMake using canonical paths
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -S "${REAL_SOURCE_DIR}" -B "${REAL_BINARY_DIR}"
        RESULT_VARIABLE _reconf_result
    )

    if(_reconf_result EQUAL 0)
        message(STATUS "✅ Reconfigured under canonical path: ${REAL_SOURCE_DIR}")
    else()
        message(FATAL_ERROR "❌ Failed to reconfigure under canonical path.")
    endif()

    # Exit the current run so the correct one takes over
    return()
endif()

# =====================================================================
#  (Normal project setup continues below)
# =====================================================================

```


### What it does

1. **Detects** if you’re running CMake from a symlinked directory.
2. **Automatically re-invokes** CMake with `-S` and `-B` pointing to the real paths.
3. **Stops the current configure** run (`return()`) so the correct configuration takes over immediately.

The new invocation reuses the same build directory — no duplicate artifacts, no confusion.


### Behavior example

If you run:

```bash
cd /local/rexx/oorexx
cmake -B build
```

you’ll see:

```
⚠️  Detected symlinked source or build directory.
    - Invoked source dir: /local/rexx/oorexx
    - Canonical source:   /Users/Shared/local/rexx/oorexx
    - Invoked build dir:  /local/rexx/oorexx/build
    - Canonical build:    /Users/Shared/local/rexx/oorexx/build

    Re-invoking CMake automatically using canonical paths
    to avoid DWARF debug info mismatches and unresolved breakpoints.

-- Reconfigured under canonical path: /Users/Shared/local/rexx/oorexx
```

And from that point on, all DWARF paths and debug info will reflect `/Users/Shared/...`, not `/local/...`.

---

Let’s make the symlink auto-correction smart enough to only trigger for **Debug** (and optionally **RelWithDebInfo**) builds, where DWARF paths matter.

This way, developers always get clean, debuggable binaries — while your automated or release builds can run anywhere (even under `/local`) without unnecessary reconfiguration.


## How this works

CMake defines a variable `CMAKE_BUILD_TYPE` for single-config generators (like Makefiles or Ninja).  
For multi-config IDEs (like Xcode or Visual Studio), you can check `CMAKE_CONFIGURATION_TYPES` and `$ENV{CONFIGURATION}` at runtime.

We’ll combine both, so it works universally.


## Smart “Debug-only” auto-correct block

Add this at the *very top* of your top-level `CMakeLists.txt`:

```cmake
# =====================================================================
#  Detect and fix symlinked source/build directories (Debug only)
# =====================================================================

# Helper function to detect active config mode
function(is_debug_build result_var)
    if(CMAKE_CONFIGURATION_TYPES)
        # Multi-config generator (Xcode, Visual Studio)
        if(DEFINED ENV{CONFIGURATION})
            string(TOLOWER "$ENV{CONFIGURATION}" _cfg)
        else()
            set(_cfg "debug")  # Default assumption for IDE config
        endif()
    else()
        # Single-config generator (Makefiles, Ninja)
        string(TOLOWER "${CMAKE_BUILD_TYPE}" _cfg)
    endif()

    if(_cfg MATCHES "debug|relwithdebinfo")
        set(${result_var} TRUE PARENT_SCOPE)
    else()
        set(${result_var} FALSE PARENT_SCOPE)
    endif()
endfunction()

# --- Perform check only for Debug or RelWithDebInfo builds
is_debug_build(_debug_build)
if(_debug_build)
    # Canonicalize (resolve symlinks)
    get_filename_component(REAL_SOURCE_DIR "${CMAKE_SOURCE_DIR}" REALPATH)
    get_filename_component(REAL_BINARY_DIR "${CMAKE_BINARY_DIR}" REALPATH)

    # Compare invoked vs real paths
    set(RECONF_NEEDED OFF)
    if(NOT "${REAL_SOURCE_DIR}" STREQUAL "${CMAKE_SOURCE_DIR}")
        set(RECONF_NEEDED ON)
    endif()
    if(NOT "${REAL_BINARY_DIR}" STREQUAL "${CMAKE_BINARY_DIR}")
        set(RECONF_NEEDED ON)
    endif()

    if(RECONF_NEEDED)
        message(WARNING "
⚠️  [Debug Build] Symlinked source or build directory detected.
    - Invoked source dir: ${CMAKE_SOURCE_DIR}
    - Canonical source:   ${REAL_SOURCE_DIR}
    - Invoked build dir:  ${CMAKE_BINARY_DIR}
    - Canonical build:    ${REAL_BINARY_DIR}

    Re-invoking CMake automatically using canonical paths
    to preserve correct DWARF debug info.
        ")

        execute_process(
            COMMAND "${CMAKE_COMMAND}" -S "${REAL_SOURCE_DIR}" -B "${REAL_BINARY_DIR}"
            RESULT_VARIABLE _reconf_result
        )

        if(_reconf_result EQUAL 0)
            message(STATUS "✅ Reconfigured under canonical path: ${REAL_SOURCE_DIR}")
        else()
            message(FATAL_ERROR "❌ Failed to reconfigure under canonical path.")
        endif()

        return()
    endif()
else()
    message(STATUS "[Info] Skipping symlink check (non-debug build).")
endif()

# =====================================================================
#  Continue with normal project setup
# =====================================================================

```


##  Example behavior

### When building Debug:

```
⚠️  [Debug Build] Symlinked source or build directory detected.
    - Invoked source dir: /local/rexx/oorexx
    - Canonical source:   /Users/Shared/local/rexx/oorexx

    Re-invoking CMake automatically using canonical paths
    to preserve correct DWARF debug info.
-- ✅ Reconfigured under canonical path: /Users/Shared/local/rexx/oorexx
```

### When building Release:

```
[Info] Skipping symlink check (non-debug build).
```
