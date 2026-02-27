# Graphemes indexer

This discussion happens after I share the Gemini conversation with Claude.

## Question

ok, then can you provide your full code? You don't need to keep the code of the 
other AI, feel free to provide your own code.

Reminder of the context:

- I know the string length in bytes.
- I know that the string is not ASCII.
- I will iterate over the string by codepoints.
- I call utf8proc's graphemeBreak for each codepoint.
- For each grapheme, I will notify the indexer.

To be extremely precise, here is the ooRexx code that I use currently to index 
a string using utf8proc.  
You will see "encoding = self".  
Here, "self" is a class of encoding, who knows how to get the next codepoint 
byte position from the current byte position.  
When the indexation is finished, an instance of this encoding class is created, 
which holds the index and the errors.  

In this version, I manage 2 indexes: codepoint index and grapheme index.  
In the C implementation, I will keep only the grapheme index, because I don't 
need a direct access by codepoint.

```
::method createIndexer class
    use strict arg string
    maximumCodepoint = 0
    codepointIndexes = .array~new -- sparse array: only the string indexes different from the array index are stored
    graphemeIndexes = .array~new -- idem
    codepointCount = 0
    graphemeCount = 0
    errors = .nil
    indexB = 1
    previousCodepoint = .nil
    previousCodepointIndexB = .nil
    graphemeBreakArgs = (.nil, .nil, 0) -- codepoint1, codepoint2, state. Will use the same array at each iteration.
    case = 3 -- bitor(2,1) both isUpper isLower

    encoding = self
    errorInfo = .array~new(1) -- simulate a variable reference: errorInfo[1] = errorMessage
    forever:
        codepoint = .nil
        nextB = encoding~nextCodepointIndexB(string, indexB, :errorInfo)
        if nextB < 0 then signal error
        codepoint = encoding~decode(string, indexB, nextB - indexB) -- codepoint can be .nil if nextB == indexB

        -- Remember : previousCodepoint can be .nil (first codepoint) or <0 (error recovery)
        checkResult = encoding~checkCodepoint(codepoint, indexB, previousCodepoint, previousCodepointIndexB, :errorInfo)
        if checkResult == -1 then do
            -- The byte-sequence starting at previousCodepointIndexB is invalid,
            -- undo the last index
            -- currently, that can happen only for WTF-8 in case of high-surrogate followed by a low-surrogate
            /*
                "D800"x~text("wtf16")~wtf8~c2x=             -- 'EDA080' is the high surrogate U+D800 encoded in WTF-8
                "DC00"x~text("wtf16")~wtf8~c2x=             -- 'EDB080' is the low surrogate U+DC00 encoded in WTF-8

                -- Remember: keep "41 42", it's to illustrate that the isolated surrogate is a grapheme in WTF-8

                "41 42 EDA080"x~text("wtf8")~c2u=           -- 'U+0041 U+0042 U+D800'   no error, the isolated high surrogate is a grapheme
                "41 42 EDA080"x~text("wtf8")~c2g=           -- '41 42 EDA080'

                                                            -- BUT if the next codepoint is a low surrogate then it's an error
                "41 42 EDA080 EDB080"x~text("wtf8")~c2u=    -- 'U+0041 U+0042 U+FFFD U+FFFD U+FFFD U+DC00'
                "41 42 EDA080 EDB080"x~text("wtf8")~c2g=    -- '41     42     ED     A0     80     EDB080'
            */
            codepointCount -= 1         -- yes, always, no problem
            graphemeCount -= 1          -- This is true ONLY for WTF-8
                                        -- See the example above. The isolated high surrogate is a grapheme when encoded in WTF-8.
                                        -- If, in the future, checkCodepoint can return -1 for an encoding other than WTF-8
                                        -- then the update of graphemeCount is maybe to rework!
            indexB = previousCodepointIndexB
            nextB = indexB + encoding~codeUnitSizeInBytes -- add 1 or 2 or 4
            signal error
        end
        else if checkResult == 0 then do
            -- The byte-sequence starting at indexB is invalid,
            nextB = indexB + encoding~codeUnitSizeInBytes -- add 1 or 2 or 4
            signal error
        end

        -- From here, we know that the current codepoint is valid
        if .nil == codepoint then signal leave -- End of string
        call indexCodepoint
        if .nil == previousCodepoint then call indexGrapheme -- First codepoint
        else if previousCodepoint < 0 then call indexGrapheme -- Error recovery
        else do
            graphemeBreakArgs[1] = previousCodepoint
            graphemeBreakArgs[2] = codepoint
            if .Unicode~utf8proc_graphemeBreak(graphemeBreakArgs) then call indexGrapheme
        end
        call checkCase
        previousCodepoint = codepoint
        previousCodepointIndexB = indexB
        indexB = nextB
    signal forever
    leave:

    -- Optimization if no need of indexes (when direct access is possible)
    if codepointIndexes~size == 0 then codepointIndexes = .nil
    if graphemeIndexes~size == 0 then graphemeIndexes = .nil
    return encoding~new(string, maximumCodepoint, codepointIndexes, codepointCount, graphemeIndexes, graphemeCount, case, errors)

    /*
        No need to store the string indexes which can be calculated from the array index.
        All the string indexes below can be calculated:
        index   UTF-8   UTF-16  UTF-32
          1       1       1       1
          2       2       3       5
          3       3       5       9
          ...
    */
    indexCodepoint:
        codepointCount += 1
        if indexB <> encoding~codeUnitSizeInBytes * (codepointCount -1) + 1 then do
            codepointIndexes[codepointCount] = indexB
        end
        maximumCodepoint = max(maximumCodepoint, codepoint)
        return

    indexGrapheme:
        graphemeCount += 1
        if indexB <> encoding~codeUnitSizeInBytes * (graphemeCount -1) + 1 then do
            graphemeIndexes[graphemeCount] = indexB
        end
        return

    checkCase:
        if case <> 0 then do
            if case == 1, \.Unicode~utf8proc_codepointIsLower(codepoint) then case = 0
            else if case == 2, \.Unicode~utf8proc_codepointIsUpper(codepoint) then case = 0
            else do -- case == 3
                if .Unicode~utf8proc_codepointIsLower(codepoint) then case = 1 -- can no longer be upper
                else if .Unicode~utf8proc_codepointIsUpper(codepoint) then case = 2 -- can no longer be lower
                else case = 0 -- can no longer be lower or upper
            end
        end
        return

    error:
        if .nil == errors then errors = .array~new
        errors~append(errorInfo[1])
        -- follow the recommendation of W3C : U+FFFD Substitution of Maximal Subparts
        nextB = abs(nextB)
        codepointCount += 1
        codepointIndexes[codepointCount] = -indexB -- a negative index means "error", a replacement character will be returned
        maximumCodepoint = max(maximumCodepoint, .Unicode~replacementCharacter~codepoint)
        graphemeCount += 1
        graphemeIndexes[graphemeCount] = -indexB -- idem
        graphemeBreakArgs[3] = 0 -- reset the extended grapheme state
        previousCodepoint = codepoint
        if .nil <> codepoint then previousCodepoint = -codepoint -- Negative codepoint allows to get the original value, if needed, while knowing it's invalid
        previousCodepointIndexB = indexB
        indexB = nextB -- resume at the next valid code unit
        signal forever

```

## Answer

Looking at your ooRexx code, I can see the exact interface I need to implement against. 
Let me write a clean C++ `GraphemeIndexer` that matches your actual usage pattern.

Key observations from your code:
- Negative index = error (malformed sequence), the absolute value is the byte position
- Grapheme indexes are sparse: only stored when they differ from the "predictable" position
- You notify the indexer per grapheme, not per byte
- You already know `byteLength` upfront

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
    // ----------------------------------------------------------
    // Construction / destruction
    // ----------------------------------------------------------

    explicit GraphemeIndexer(size_t byteLength)
        : byteLength_(byteLength)
        , graphemeCount_(0)
        , bitVector_(nullptr)
        , errorVector_(nullptr)
        , summaryTable_(nullptr)
        , summarySize_(0)
        , finalized_(false)
    {
        // 1 bit per byte of the original string
        size_t numWords = wordCount(byteLength_);
        bitVector_   = allocWords(numWords);   // grapheme-start bits
        errorVector_ = allocWords(numWords);   // error bits (same layout)
    }

    ~GraphemeIndexer()
    {
        freeWords(bitVector_);
        freeWords(errorVector_);
        freeWords(summaryTable_);
    }

    // ----------------------------------------------------------
    // Called once per grapheme during the scan
    //
    // bytePos  : 1-based byte position of the grapheme start
    //            (matches ooRexx indexB convention)
    // isError  : true if this grapheme is a U+FFFD replacement
    //            (i.e. your "negative index" case)
    // ----------------------------------------------------------

    void notifyGrapheme(size_t bytePos, bool isError)
    {
        assert(!finalized_);
        assert(bytePos >= 1 && bytePos <= byteLength_);

        size_t bitIndex = bytePos - 1;   // convert to 0-based bit position
        setBit(bitVector_,   bitIndex);
        if (isError)
            setBit(errorVector_, bitIndex);

        graphemeCount_++;
    }

    // ----------------------------------------------------------
    // Call after all notifyGrapheme() calls.
    // Builds the summary table for O(1) lookup.
    // ----------------------------------------------------------

    void finalize()
    {
        assert(!finalized_);

        // Summary table: one entry per SUMMARY_WORDS 64-bit words.
        // Each entry stores the cumulative grapheme count BEFORE
        // that block of words.
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

    // ----------------------------------------------------------
    // Direct access: given a 1-based grapheme index,
    // return the 1-based byte offset of that grapheme.
    //
    // Returns byteLength_ + 1 if targetIdx > graphemeCount_
    // (one-past-end sentinel, consistent with ooRexx length+1).
    // ----------------------------------------------------------

    size_t getByteOffset(size_t targetIdx) const
    {
        assert(finalized_);
        assert(targetIdx >= 1);

        if (targetIdx > graphemeCount_)
            return byteLength_ + 1;

        // --- 1. Binary search the summary table ---
        // We want the largest summaryIdx such that
        // summaryTable_[summaryIdx] < targetIdx.
        // Since summaryTable_[0] == 0 and targetIdx >= 1,
        // summaryIdx is always >= 0.

        size_t lo = 0, hi = summarySize_;
        while (lo + 1 < hi)
        {
            size_t mid = lo + (hi - lo) / 2;
            if (summaryTable_[mid] < targetIdx)
                lo = mid;
            else
                hi = mid;
        }
        // lo is now the best summary block

        size_t graphemesSoFar = summaryTable_[lo];
        size_t wordIdx        = lo * SUMMARY_WORDS;
        size_t numWords       = wordCount(byteLength_);

        // --- 2. Walk 64-bit words (at most SUMMARY_WORDS iterations) ---
        while (wordIdx < numWords)
        {
            uint64_t word       = bitVector_[wordIdx];
            int      countInWord = gidx_popcount64(word);

            if (graphemesSoFar + (uint64_t)countInWord >= targetIdx)
            {
                // --- 3. Target bit is in this word ---
                int localTarget = (int)(targetIdx - graphemesSoFar);

                // Clear the lowest set bit (localTarget - 1) times
                for (int i = 0; i < localTarget - 1; i++)
                    word &= word - 1;

                int bitPos = gidx_ctz64(word);      // 0-based bit in word
                size_t bitIndex = wordIdx * 64 + bitPos;  // 0-based in string
                return bitIndex + 1;                // back to 1-based
            }

            graphemesSoFar += (uint64_t)countInWord;
            wordIdx++;
        }

        // Should never reach here if graphemeCount_ is consistent
        assert(false);
        return byteLength_ + 1;
    }

    // ----------------------------------------------------------
    // Returns true if the grapheme at the given 1-based index
    // is a U+FFFD error replacement.
    // Uses the same Rank/Select logic on errorVector_.
    // ----------------------------------------------------------

    bool isErrorGrapheme(size_t targetIdx) const
    {
        assert(finalized_);
        size_t bytePos = getByteOffset(targetIdx);   // 1-based
        if (bytePos > byteLength_) return false;

        size_t bitIndex = bytePos - 1;
        return getBit(errorVector_, bitIndex);
    }

    // ----------------------------------------------------------
    // Accessors
    // ----------------------------------------------------------

    size_t graphemeCount() const { return graphemeCount_; }
    size_t byteLength()    const { return byteLength_;    }

private:
    // ----------------------------------------------------------
    // Tuning constant:
    // Number of 64-bit words between summary checkpoints.
    // 8 words = 512 bits = 512 bytes of original string per block.
    // Worst-case inner loop: 8 iterations of popcount.
    // Memory overhead: ~2% on top of the 12.5% bit-vector.
    // ----------------------------------------------------------
    static const size_t SUMMARY_WORDS = 8;

    size_t   byteLength_;
    size_t   graphemeCount_;
    uint64_t* bitVector_;     // 1 bit per input byte; 1 = grapheme start
    uint64_t* errorVector_;   // 1 bit per input byte; 1 = error grapheme
    uint64_t* summaryTable_;  // cumulative grapheme counts at checkpoints
    size_t    summarySize_;
    bool      finalized_;

    // ----------------------------------------------------------
    // Helpers
    // ----------------------------------------------------------

    static size_t wordCount(size_t byteLen)
    {
        return (byteLen + 63) / 64;
    }

    static uint64_t* allocWords(size_t count)
    {
        // Zero-initialized
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

A few design decisions worth explaining:

**Why `errorVector_` mirrors `bitVector_` in layout.** 
    It costs the same 12.5% overhead as the main bit-vector, but keeps 
    `isErrorGrapheme()` fast — once you have the byte position from 
    `getByteOffset()`, the error check is a single bit test with no binary 
    search. Since error checks happen at the same rate as grapheme accesses, 
    this is worth it.

**Why `calloc` instead of `new`.** 
    You mentioned ooRexx has its own memory manager. 
    I used `calloc` as a placeholder that you can swap for 
    `MemoryManager::allocate()` or whatever ooRexx uses. 
    The zero-initialization is required — `calloc` gives it for free, 
    `malloc` would not.

**The `byteLength_ + 1` sentinel.** 
    This mirrors ooRexx's "length + 1" convention for one-past-end positions, 
    which is what `substr` implementations typically use internally.

**What you need to add.** 
    The `notifyGrapheme` call site in your scanning loop, replacing the current 
    `graphemeIndexes[graphemeCount] = -indexB` logic. 
    The `isError` flag maps directly to your existing `signal error` path.
