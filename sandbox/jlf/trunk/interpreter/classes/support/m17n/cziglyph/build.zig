const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const lib = b.addStaticLibrary("cziglyph", "src/cziglyph.zig");
    lib.addPackagePath("ziglyph", "../ziglyph/src/ziglyph.zig");

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();
    lib.setBuildMode(mode);

    const target = b.standardTargetOptions(.{});
    lib.setTarget(target);

    // If I use std.heap.c_allocator then I need lib.linkLibC()
    // If I use std.heap.raw_c_allocator then I don't need libC under MacOs, but I need it under Windows
    lib.linkLibC();

    // Not needed so far
    // lib.linkLibCpp();

    //--------------------------------------------------------------------------
    // Workaround for:
    // Undefined symbols for architecture x86_64:
    //   "___zig_probe_stack", referenced from:
    //       _std.sort.sort in cziglyph.o)
    //       _std.debug.printLineFromFileAnyOs in cziglyph.o)
    //       _ModuleDebugInfo.loadOFile in cziglyph.o)
    //       _std.dwarf.DwarfInfo.getLineNumberInfo in cziglyph.o)
    // ld: symbol(s) not found for architecture x86_64

    // -fcompiler-rt
    // LibExeObjStep.bundle_compiler_rt = true;
    switch (mode) {
        .Debug, .ReleaseSafe => lib.bundle_compiler_rt = true,
        .ReleaseFast, .ReleaseSmall => lib.disable_stack_probing = true,
    }
    //--------------------------------------------------------------------------

    lib.install();

    const cziglyph_tests = b.addTest("src/cziglyph.zig");
    cziglyph_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&cziglyph_tests.step);
}
