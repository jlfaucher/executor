# Grapheme Indexer — Code Review Conversation

## User

*Uploaded file: `question2-graphemes_indexing.txt`*

### Context

ooRexx supports only byte-encoded strings. A layer above the native strings is planned to support Unicode, using the Unicode algorithms to decompose a string into graphemes.

Direct access to graphemes is needed (not sequential via an iterator), so an indexer associating a byte position to each grapheme will be managed. This is because all methods of the ooRexx String class use indexes, not iterators.

Example:
```
"direct access"~substr(2,3) == "ire"
```

For performance, an on-demand (incremental) indexer is planned:
- Calculate the length in graphemes only when needed (needs a full scan)
- Detect errors only when needed (can stop at the first error if the query is "is this string well-formed")

A prototype was started using utf8proc. The current implementation uses an ooRexx array to manage the grapheme indexes — fast and good for small strings, but not adapted for big strings. Multi-stage tables and other data structures are being considered.

### Question

Can you provide an implementation of the grapheme indexer?

Constraints:
- String length in bytes is known
- String is known to be non-ASCII
- Iteration over the string is by codepoints
- `utf8proc`'s `graphemeBreak` is called for each codepoint
- For each grapheme, the indexer is notified

The existing ooRexx scanning code was provided, along with a C++ answer from another AI using a bit-vector + summary table (rank/select) approach for review.

### Provided C++ Implementation (by another AI)

```cpp
#ifndef GRAPHEME_INDEXER_HPP
#define GRAPHEME_INDEXER_HPP

#include <cstdint>
#include <cstdlib>
#include <cassert>

// ============================================================
// Portable bit intrinsics
// ============================================================

static inline int gidx_popcount64(uint64_t v)
{
#if defined(_MSC_VER)
  #if defined(_WIN64)
    return (int)__popcnt64(v);
  #else
    return (int)(__popcnt((uint32_t)v) + __popcnt((uint32_t)(v >> 32)));
  #endif
#else
    return __builtin_popcountll(v);
#endif
}

static inline int gidx_ctz64(uint64_t v)
{
    // Undefined behavior if v == 0; callers must ensure v != 0
#if defined(_MSC_VER)
    unsigned long r;
    _BitScanForward64(&r, v);
    return (int)r;
#else
    return __builtin_ctzll(v);
#endif
}

// ============================================================
// GraphemeIndexer
//
// 1-based grapheme indexing to match ooRexx conventions.
//
// Usage:
//   GraphemeIndexer idx(byteLength);
//   // ... iterate codepoints, call graphemeBreak ...
//   idx.notifyGrapheme(bytePos, isError);   // once per grapheme
//   idx.finalize();
//   size_t bytePos = idx.getByteOffset(n);  // 1-based
// ============================================================

class GraphemeIndexer
{
public:
    explicit GraphemeIndexer(size_t byteLength)
        : byteLength_(byteLength)
        , graphemeCount_(0)
        , bitVector_(nullptr)
        , errorVector_(nullptr)
        , summaryTable_(nullptr)
        , summarySize_(0)
        , finalized_(false)
    {
        size_t numWords = wordCount(byteLength_);
        bitVector_   = allocWords(numWords);
        errorVector_ = allocWords(numWords);
    }

    ~GraphemeIndexer()
    {
        freeWords(bitVector_);
        freeWords(errorVector_);
        freeWords(summaryTable_);
    }

    void notifyGrapheme(size_t bytePos, bool isError)
    {
        assert(!finalized_);
        assert(bytePos >= 1 && bytePos <= byteLength_);

        size_t bitIndex = bytePos - 1;
        setBit(bitVector_,   bitIndex);
        if (isError)
            setBit(errorVector_, bitIndex);

        graphemeCount_++;
    }

    void finalize()
    {
        assert(!finalized_);

        size_t numWords = wordCount(byteLength_);
        summarySize_  = (numWords + SUMMARY_WORDS - 1) / SUMMARY_WORDS;
        summaryTable_ = allocWords(summarySize_);

        uint64_t running = 0;
        for (size_t w = 0; w < numWords; w++)
        {
            if (w % SUMMARY_WORDS == 0)
                summaryTable_[w / SUMMARY_WORDS] = running;
            running += (uint64_t)gidx_popcount64(bitVector_[w]);
        }

        finalized_ = true;
    }

    size_t getByteOffset(size_t targetIdx) const
    {
        assert(finalized_);
        assert(targetIdx >= 1);

        if (targetIdx > graphemeCount_)
            return byteLength_ + 1;

        size_t lo = 0, hi = summarySize_;
        while (lo + 1 < hi)
        {
            size_t mid = lo + (hi - lo) / 2;
            if (summaryTable_[mid] < targetIdx)
                lo = mid;
            else
                hi = mid;
        }

        size_t graphemesSoFar = summaryTable_[lo];
        size_t wordIdx        = lo * SUMMARY_WORDS;
        size_t numWords       = wordCount(byteLength_);

        while (wordIdx < numWords)
        {
            uint64_t word       = bitVector_[wordIdx];
            int      countInWord = gidx_popcount64(word);

            if (graphemesSoFar + (uint64_t)countInWord >= targetIdx)
            {
                int localTarget = (int)(targetIdx - graphemesSoFar);

                for (int i = 0; i < localTarget - 1; i++)
                    word &= word - 1;

                int bitPos = gidx_ctz64(word);
                size_t bitIndex = wordIdx * 64 + bitPos;
                return bitIndex + 1;
            }

            graphemesSoFar += (uint64_t)countInWord;
            wordIdx++;
        }

        assert(false);
        return byteLength_ + 1;
    }

    bool isErrorGrapheme(size_t targetIdx) const
    {
        assert(finalized_);
        size_t bytePos = getByteOffset(targetIdx);
        if (bytePos > byteLength_) return false;

        size_t bitIndex = bytePos - 1;
        return getBit(errorVector_, bitIndex);
    }

    size_t graphemeCount() const { return graphemeCount_; }
    size_t byteLength()    const { return byteLength_;    }

private:
    static const size_t SUMMARY_WORDS = 8;

    size_t   byteLength_;
    size_t   graphemeCount_;
    uint64_t* bitVector_;
    uint64_t* errorVector_;
    uint64_t* summaryTable_;
    size_t    summarySize_;
    bool      finalized_;

    static size_t wordCount(size_t byteLen)
    {
        return (byteLen + 63) / 64;
    }

    static uint64_t* allocWords(size_t count)
    {
        uint64_t* p = (uint64_t*)calloc(count, sizeof(uint64_t));
        if (!p) throw std::bad_alloc();
        return p;
    }

    static void freeWords(uint64_t* p)
    {
        free(p);
    }

    static void setBit(uint64_t* vec, size_t bitIndex)
    {
        vec[bitIndex >> 6] |= (uint64_t)1 << (bitIndex & 63);
    }

    static bool getBit(const uint64_t* vec, size_t bitIndex)
    {
        return (vec[bitIndex >> 6] >> (bitIndex & 63)) & 1;
    }
};

#endif // GRAPHEME_INDEXER_HPP
```

---

## Claude — Review

### Overall Assessment

The design is solid — a bit-vector with rank/select via a two-level summary table is a classic and appropriate choice for this problem. The memory overhead is low (~12.5% for the bit-vector + ~2% for the summary table), and `getByteOffset` performs an efficient "select" operation. The interface (`notifyGrapheme` → `finalize` → `getByteOffset`) maps cleanly to the scanning loop.

That said, there are several issues worth addressing, ranging from correctness bugs to design improvements.

### Correctness Issues

**1. `getByteOffset` select logic has an off-by-one risk when `targetIdx == summaryTable_[mid]`**

The binary search looks for the largest `lo` where `summaryTable_[lo] < targetIdx`. This is correct — but consider the edge case where `targetIdx` equals a summary entry exactly. In that scenario `summaryTable_[mid] < targetIdx` is false, so `hi = mid`, which is the right thing. This part is actually fine on closer inspection.

**2. The inner select loop (`word &= word - 1`) is correct but fragile**

The technique of clearing the lowest set bit `localTarget - 1` times and then using `ctz` to find the position of the `localTarget`-th set bit is a well-known idiom. However, if `localTarget` is ever 0 (which shouldn't happen given the logic, but defensively), the `ctz` call would operate on the original word, not an error — but it could return the wrong result silently. An `assert(localTarget >= 1)` would be prudent.

**3. The `graphemesSoFar + countInWord >= targetIdx` comparison mixes `uint64_t` and `int`**

`countInWord` is `int` but gets added to a `uint64_t`. This works in practice (promotion handles it), but it's cleaner to declare `countInWord` as `size_t` or `uint64_t` consistently.

### Design Considerations

**4. `getByteOffset` complexity is not truly O(1) — it's O(SUMMARY_WORDS) per lookup**

With `SUMMARY_WORDS = 8`, the worst case walks 8 words after the binary search, plus up to 64 bit-clearing iterations within a word. That's effectively O(log(n/512) + 512) in the worst case. This is fine for most practical string sizes. But the comment "O(1) lookup" in `finalize()` is misleading — it's more accurately O(log(n) + constant).

If true O(1) select is ever needed, a three-level structure (superblocks → blocks → in-word lookup table) would be required. But for strings under a few hundred MB, the current approach is more than adequate.

**5. The incremental/on-demand indexing described isn't supported yet**

The context mentions wanting lazy indexing — index only the first N graphemes if only the beginning of a string is accessed. The current design requires a full scan before `finalize()`, and `finalize()` must be called before any `getByteOffset()`. To support incremental use, either `finalize()` would need to be deferred (extending the summary table on demand) or a different structure like a B-tree of byte positions that grows incrementally would be needed.

One practical approach: keep this bit-vector design for "fully indexed" strings, and add a small separate fast-path for "index up to position N" that simply scans forward and caches the last known position. Most real-world access patterns are either "access near the beginning" or "full scan needed anyway" (e.g., computing length).

**6. No reverse lookup (`byteOffset → graphemeIndex`)**

The ooRexx `String` class likely needs this too — for instance, `pos()` returns a character position, so after finding a byte match the result needs to be converted back to a grapheme index. This would be a "rank" query on the bit-vector, which is actually simpler than "select": binary-search the summary table, then `popcount` the remaining words. Worth adding.

**7. Error vector could be optional**

`errorVector_` is allocated unconditionally, but for well-formed strings it will be entirely zeroed. A simple optimization: defer its allocation until the first `isError == true` call in `notifyGrapheme`. This saves 12.5% memory for the common case of valid strings.

```cpp
void notifyGrapheme(size_t bytePos, bool isError)
{
    assert(!finalized_);
    assert(bytePos >= 1 && bytePos <= byteLength_);

    size_t bitIndex = bytePos - 1;
    setBit(bitVector_, bitIndex);
    if (isError) {
        if (!errorVector_)
            errorVector_ = allocWords(wordCount(byteLength_));
        setBit(errorVector_, bitIndex);
    }
    graphemeCount_++;
}
```

Then `isErrorGrapheme` checks `if (!errorVector_) return false;` before doing the bit test.

**8. Memory management: no copy/move semantics**

The class uses raw `calloc`/`free` but has no copy constructor, move constructor, or assignment operators. In C++ this is a dangling-pointer bug waiting to happen. At minimum, delete the copy operations:

```cpp
GraphemeIndexer(const GraphemeIndexer&) = delete;
GraphemeIndexer& operator=(const GraphemeIndexer&) = delete;
```

And ideally add move semantics if the indexer ever needs to be returned from a function or stored in a container.

**9. `SUMMARY_WORDS = 8` tuning**

The comment says "512 bytes of original string per block." This means for a 1 MB string there are ~2048 summary entries, and the binary search is ~11 iterations. For a 1 GB string, ~22 iterations. This is reasonable. But if most strings are short (< 10 KB), a smaller `SUMMARY_WORDS` (e.g., 4) might be considered to reduce the linear scan after the binary search — or even skip the summary entirely for strings below a threshold and just scan the bit-vector directly.

### Integration with the ooRexx Code

The mapping from the current code is straightforward:

- In `indexGrapheme:`, replace `graphemeIndexes[graphemeCount] = indexB` with `indexer.notifyGrapheme(indexB, false)`
- In `error:`, replace `graphemeIndexes[graphemeCount] = -indexB` with `indexer.notifyGrapheme(indexB, true)`
- After the scan loop, call `indexer.finalize()`
- Replace `graphemeIndexes[n]` lookups with `indexer.getByteOffset(n)`
- Replace `abs(graphemeIndexes[n])` / sign checks with `indexer.getByteOffset(n)` + `indexer.isErrorGrapheme(n)`

The sign-encoding trick (`-indexB` for errors) is neatly replaced by the separate error vector, which is cleaner.

### Summary

The bit-vector + summary table approach is well-chosen for this use case. The main things to address before production use are: adding the Rule of Five (delete copy, add move), making the error vector lazily allocated, adding an `assert(localTarget >= 1)` guard, and considering whether a rank query (byte → grapheme) is needed in addition to the select query (grapheme → byte). The incremental indexing story is the biggest architectural gap relative to what was described, but that can be layered on top.
