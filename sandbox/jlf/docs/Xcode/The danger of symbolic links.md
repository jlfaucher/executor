The danger of symbolic links
============================

(ChatGPT)

---

That `/local → /Users/Shared/local` symlink is the *root cause* of the `/local/rexx/...` prefix inside your DWARF data.  
Let’s unpack precisely **why** the compiler used that path, and how you can control it.

---

## How DWARF records source paths

When `clang++` compiles a file like:

```bash
clang++ -c /local/rexx/oorexx/.../RexxActivity.cpp
```

it embeds the **exact path string passed to the compiler** (from the current working directory or file argument) into the DWARF info — literally the text it sees.

So if your build system (CMake, make, etc.) invoked the compiler through `/local/rexx/...`, that becomes baked into the debug info.

---

## Why your build used `/local/...`

Because of this symbolic link:

```
/local -> /Users/Shared/local
```

you probably built from `/local/rexx/oorexx/...` — or at least your build configuration used that canonicalized path at generation time.

CMake is notorious for “freezing” absolute paths at *configure* time.  
That means:

* It wrote `/local/rexx/...` into `CMakeCache.txt`,
* Then propagated that to compile commands,
* And those got baked into DWARF.

Even if you later accessed the same directory via `/Users/Shared/local/...`, the DWARF entries already contained `/local/...`, so Xcode couldn’t find the files.

---

## Why Xcode doesn’t automatically resolve that

Xcode’s DWARF-to-editor mapping is *literal*.  
It won’t follow symlinks, and it won’t resolve `/local → /Users/Shared/local` on its own — LLDB needs an explicit `target.source-map` to translate one into the other.

That’s why the fix you applied works so beautifully:

```lldb
settings set target.source-map /local/rexx /Users/Shared/local/rexx
```

It tells LLDB:

> “Whenever you see `/local/rexx/...` in DWARF, look in `/Users/Shared/local/rexx/...` instead.”

---

## How to prevent it in future builds

You have three main options:

### Option 1 — Always build from the canonical path

Instead of `cd /local/rexx/...`, do:

```bash
cd /Users/Shared/local/rexx/...
```

and rebuild.  
All DWARF entries will then contain `/Users/Shared/...`, matching your editor and eliminating the need for a source-map.

---

### Option 2 — Force CMake to canonicalize paths

If you must use `/local/...`, you can tell CMake to normalize to the *real path* at configure time:

```bash
cmake -DCMAKE_USE_REAL_PATHS=ON /Users/Shared/local/rexx/oorexx
```

or (manually):

```bash
cmake -S "$(realpath /local/rexx/oorexx)" -B build
```

`realpath` resolves symlinks before CMake stores them.

---

### Option 3 — Keep the symlink but make it intentional

If you *want* to keep `/local` as your canonical build root (for consistency across systems), then it’s perfectly fine — just maintain the `source-map` rule in `.lldbinit-Xcode`.  
That’s common practice in larger projects (e.g., Linux distros build under `/buildroot` or `/srcroot` and map to developer paths).

