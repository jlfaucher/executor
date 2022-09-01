const std = @import("std");
const testing = std.testing;
const unicode = std.unicode;

const ziglyph = @import("ziglyph");

// Functionality by popular Unicode General Category.
const letter = ziglyph.letter;
const mark = ziglyph.mark;
const number = ziglyph.number;
const punct = ziglyph.punct;
const symbol = ziglyph.symbol;

// Display width calculation.
const display_width = ziglyph.display_width;

// String segmentation.
const CodePoint = ziglyph.CodePoint;
const CodePointIterator = CodePoint.CodePointIterator;
const Grapheme = ziglyph.Grapheme;
const GraphemeIterator = Grapheme.GraphemeIterator;
const Word = ziglyph.Word;
const WordIterator = Word.WordIterator;
const Sentence = ziglyph.Sentence;
const SentenceIterator = Sentence.SentenceIterator;
const ComptimeSentenceIterator = Sentence.ComptimeSentenceIterator;

// Collation
const Collator = ziglyph.Collator;

// Normalization
const Normalizer = ziglyph.Normalizer;


//------------------------------------------------------------------------------
// Workaround for:
// Undefined symbols for architecture x86_64:
//  "__availability_version_check", referenced from:
//      ___isPlatformVersionAtLeast in compiler_rt.o)
// https://trac.macports.org/ticket/64658
// https://github.com/ziglang/zig/pull/10232#issue-1064864004
// did not retain the backwards compatibility logic [...] Zig supports only the last three macOS versions

// https://code.woboq.org/llvm/compiler-rt/lib/builtins/os_version_check.c.html
// _availability_version_check darwin API support.

const dyld_platform_t = u32;
const dyld_build_version_t = extern struct {
    platform: dyld_platform_t,
    version: u32,
};
// Darwin-only
export fn _availability_version_check(_: u32, _: [*c]const dyld_build_version_t) bool
{
    return false;
}


//------------------------------------------------------------------------------
// Wrappers

export fn ziglyph_free(memory: [*]const u8, length: usize) void {
    std.heap.c_allocator.free(memory[0..length]);
}

// Caller must free out_utf8str
export fn ziglyph_toTitleStr(utf8str: [*]const u8, length: usize, out_utf8str: *?[*]const u8, out_length: *usize) void {
    out_utf8str.* = null;
    out_length.* = 0;
    const optional_result: ?[]u8 = ziglyph.toTitleStr(std.heap.c_allocator, utf8str[0..length]) catch null;
    if (optional_result) |result| {
        out_utf8str.* = result.ptr;
        out_length.* = result.len;
    }
}
