Xcode Minimum deployment target
===============================

(Dialog with ChatGPT)

xcode 26 complains that macOS 15.6.1 is lower than the minimum deployment target.  
I changed the setting macOS deployment target to Sequoia both in Project settings AND Target settings.  
But the problem is still there.

---

Yeah — that’s a frustrating one. Let’s go through what’s happening here carefully.

When Xcode 26 complains that *“macOS 15.6.1 is lower than the minimum deployment target”* even though you’ve set the **Deployment Target** to **macOS Sequoia**, it’s usually because **Xcode is confused between the build SDK version and the deployment target**.

Let’s unpack that:

---

### What the error actually means

This message doesn’t mean your *build machine’s macOS version* (15.6.1) is too low — it means that **the app’s minimum deployment target is *higher* than the version of the SDK or system you’re building against.**

In other words:

* The *deployment target* is newer than the *SDK version* Xcode has installed.

---

### Common causes

1. **You selected a macOS deployment target that doesn’t exist yet in your SDK.**

   * “macOS Sequoia” corresponds to macOS 15.
   * But if you’ve set “macOS Sequoia” as the *deployment target*, and your Xcode SDK is for macOS 15.0 (or earlier), it may internally treat that as “> available SDK”.

   → Check your SDK list:

   ```bash
   ls /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/
   ```

   You should see something like:

   ```
   MacOSX15.0.sdk
   ```

   If you **don’t** see `MacOSX15.0.sdk` (or higher), that’s your problem.

---

2. **The project setting vs target setting mismatch.**

   * Even if you changed both, check:

     * `Build Settings → Base SDK` — it should say *“macOS 15.0 (Sequoia)”*
     * `Build Settings → macOS Deployment Target` — it should be ≤ Base SDK.

   If Deployment Target > Base SDK, you’ll get this exact warning.

---

3. **A 3rd-party framework or Swift package sets its own minimum deployment target.**

   * Check your dependencies: if one of them sets `MACOSX_DEPLOYMENT_TARGET = 16.0` or similar, the compiler thinks you’re targeting a newer system.

   Try:

   ```bash
   grep -R MACOSX_DEPLOYMENT_TARGET .
   ```

   in your project directory.

---

4. **Xcode or the OS beta mismatch.**

   * If you’re on macOS 15.6.1 and Xcode 26 expects a newer SDK (e.g. macOS 16), this can happen when Xcode 26 is from a newer beta cycle or developer preview.

---

### Fixes to try

1. **Make sure Base SDK matches what you actually have:**

   * In *Build Settings*:

     * **Base SDK** → “macOS 15.0 (Sequoia)”
     * **Deployment Target** → “macOS 15.0” or *lower* (e.g. 14.0 if you want backward compatibility).

2. **Clean build and derived data:**

   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

   Then rebuild.

3. **If your Base SDK dropdown doesn’t show Sequoia**, your Xcode installation might be missing the SDK:

   * Reinstall or update Xcode from the App Store (or developer.apple.com).
   * Make sure `/Applications/Xcode.app` is the active developer directory:

     ```bash
     sudo xcode-select -s /Applications/Xcode.app
     ```

4. **Last resort:** If you need to build for Sequoia but Xcode 26’s SDK doesn’t include it, set the deployment target manually:

   ```bash
   export MACOSX_DEPLOYMENT_TARGET=15.0
   ```

   before building from command line (or add to Build Settings → “Other C Flags”).

---


If you want to make it cleaner later, you can also set it globally by adding this to your project’s **Build Settings → User-Defined Settings**:

```
MACOSX_DEPLOYMENT_TARGET = 15.0
```

That way you don’t need to repeat it in multiple flag lists.

