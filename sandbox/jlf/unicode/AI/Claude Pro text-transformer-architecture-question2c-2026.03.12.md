
# TextTransformer Architecture — Conversation

## User

Please provide a C or C++ implementation of the RexxTextTransformer class.
Then provide a C or C++ implementation of the posText method, to have an example of usage of the RexxTextTransformer services.
Please use the GraphemeIndexer to illustrate how it's used.
I don't need an accurate C or C++ implementation of all the ooRexx code, I need just a detailed illustration of the architecture that you described.

---

## Claude — Implementation

*(The complete `text_transformer.hpp` file follows, then the architectural walkthrough.)*

### `text_transformer.hpp`

```cpp
// ============================================================================
// text_transformer.hpp
//
// Architectural illustration of the Unicode text transformation layer
// for ooRexx, showing how GraphemeIndexer, TransformMapping, and
// TextTransformer work together.
//
// This is NOT production code. It is a detailed design sketch that
// shows the data structures, their relationships, and how posText
// uses them. Placeholder functions (transform_grapheme, byte_strstr,
// etc.) represent operations that would delegate to utf8proc or
// similar libraries in the real implementation.
//
// All indexes are 1-based to match ooRexx conventions.
// ============================================================================

#ifndef TEXT_TRANSFORMER_HPP
#define TEXT_TRANSFORMER_HPP

#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <cassert>
#include <new>       // std::bad_alloc


// ============================================================================
// Forward declarations
// ============================================================================

class GraphemeIndexer;
class TransformMapping;
class TextTransformer;
struct TransformOptions;
struct Ib2xcResult;


// ============================================================================
// TransformOptions
//
// Corresponds to the ooRexx named arguments:
//   normalization, casefold, lump, stripIgnorable, stripMark, stripCC, stripNA
//
// Packed into a single struct for convenience.
// ============================================================================

struct TransformOptions
{
    int  normalization;     // e.g., NFC=1, NFD=2, NFKC=3, NFKD=4, 0=none
    bool casefold;
    bool lump;
    bool stripIgnorable;
    bool stripMark;
    bool stripCC;
    bool stripNA;
};


// ============================================================================
// Ib2xcResult
//
// The result of translating an internal byte position to an external
// grapheme position. Replaces the ooRexx convention of encoding
// alignment in the sign of the integer.
//
// graphemePosC : 1-based grapheme position in the FULL external text
//                (global, not relative to the subtext)
// bytePosB     : 1-based byte position in the FULL internal text
//                (global, not relative to the subtext)
// aligned      : true if the internal byte position falls exactly on
//                a grapheme boundary in the external text
// ============================================================================

struct Ib2xcResult
{
    size_t graphemePosC;    // external grapheme position (1-based, global)
    size_t bytePosB;        // internal byte position (1-based, global)
    bool   aligned;         // true = byte pos is on a grapheme boundary
};


// ============================================================================
// PORTABLE BIT INTRINSICS
// (copied from the GraphemeIndexer review — shared by both classes)
// ============================================================================

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
#if defined(_MSC_VER)
    unsigned long r;
    _BitScanForward64(&r, v);
    return (int)r;
#else
    return __builtin_ctzll(v);
#endif
}


// ============================================================================
// GraphemeIndexer
//
// Bit-vector + summary table for O(log n) select on a single string.
// Permanent structure: built once when a RexxText is created, lives
// as long as the string.
//
// Provides:
//   - select(k)      : grapheme index k  -->  byte offset   (getByteOffset)
//   - rank(bytePos)  : byte offset       -->  grapheme index (getGraphemeIndex)
//   - error queries  : isErrorGrapheme(k)
//
// The rank query was added per the review suggestion — it is the
// inverse of select and is needed by characterIndexC.
// ============================================================================

class GraphemeIndexer
{
public:
    GraphemeIndexer(const GraphemeIndexer&) = delete;
    GraphemeIndexer& operator=(const GraphemeIndexer&) = delete;

    explicit GraphemeIndexer(size_t byteLength)
        : byteLength_(byteLength)
        , graphemeCount_(0)
        , bitVector_(nullptr)
        , errorVector_(nullptr)   // lazily allocated
        , summaryTable_(nullptr)
        , summarySize_(0)
        , finalized_(false)
    {
        size_t numWords = wordCount(byteLength_);
        bitVector_ = allocWords(numWords);
    }

    ~GraphemeIndexer()
    {
        freeWords(bitVector_);
        freeWords(errorVector_);
        freeWords(summaryTable_);
    }

    // --- Building phase ---

    void notifyGrapheme(size_t bytePos, bool isError)
    {
        assert(!finalized_);
        assert(bytePos >= 1 && bytePos <= byteLength_);

        size_t bitIndex = bytePos - 1;
        setBit(bitVector_, bitIndex);

        if (isError)
        {
            if (!errorVector_)
                errorVector_ = allocWords(wordCount(byteLength_));
            setBit(errorVector_, bitIndex);
        }

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

    // --- Select: grapheme index --> byte offset (1-based) ---
    //
    // "Give me the byte position of the k-th grapheme."
    // This is what ooRexx's characterIndexB(k) calls.

    size_t getByteOffset(size_t targetIdx) const
    {
        assert(finalized_);
        assert(targetIdx >= 1);

        if (targetIdx > graphemeCount_)
            return byteLength_ + 1;

        // Binary search the summary table
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
            uint64_t word     = bitVector_[wordIdx];
            size_t countInWord = (size_t)gidx_popcount64(word);

            if (graphemesSoFar + countInWord >= targetIdx)
            {
                size_t localTarget = targetIdx - graphemesSoFar;
                assert(localTarget >= 1);

                for (size_t i = 0; i < localTarget - 1; i++)
                    word &= word - 1;

                int bitPos = gidx_ctz64(word);
                size_t bitIndex = wordIdx * 64 + (size_t)bitPos;
                return bitIndex + 1;
            }

            graphemesSoFar += countInWord;
            wordIdx++;
        }

        assert(false);
        return byteLength_ + 1;
    }

    // --- Rank: byte offset --> grapheme index (1-based) ---
    //
    // "Which grapheme does this byte belong to?"
    // Returns the grapheme index whose start byte is <= bytePos.
    //
    // If bytePos falls exactly on a grapheme start, this returns
    // that grapheme's index and sets *aligned = true.
    // If bytePos falls in the middle of a grapheme, this returns
    // that grapheme's index and sets *aligned = false.
    //
    // This is what ooRexx's characterIndexC(posB) calls.

    size_t getGraphemeIndex(size_t bytePos, bool* aligned = nullptr) const
    {
        assert(finalized_);
        assert(bytePos >= 1 && bytePos <= byteLength_);

        size_t bitIndex = bytePos - 1;   // 0-based

        // Is this byte a grapheme start?
        bool isStart = getBit(bitVector_, bitIndex);
        if (aligned)
            *aligned = isStart;

        // Count the number of set bits in [0..bitIndex] = rank query.
        // Walk summary table, then count remaining words.

        size_t wordIdx    = bitIndex >> 6;           // which 64-bit word
        size_t summaryIdx = wordIdx / SUMMARY_WORDS; // which summary block

        size_t rank = summaryTable_[summaryIdx];

        // Add popcount for full words between summary checkpoint and wordIdx
        size_t startWord = summaryIdx * SUMMARY_WORDS;
        for (size_t w = startWord; w < wordIdx; w++)
            rank += (size_t)gidx_popcount64(bitVector_[w]);

        // Add popcount for partial word up to and including bitIndex
        uint64_t word = bitVector_[wordIdx];
        uint64_t mask = ((uint64_t)1 << (bitIndex & 63)) - 1;
        // mask has bits [0..bitIndex%64 - 1] set
        // We want to include the bit at bitIndex itself in the count:
        mask |= (uint64_t)1 << (bitIndex & 63);
        rank += (size_t)gidx_popcount64(word & mask);

        // If bytePos is not a grapheme start, rank gives the grapheme
        // that contains this byte (the last grapheme start <= bytePos).
        // If bytePos is a grapheme start, rank gives exactly that grapheme.
        return rank;
    }

    // --- Error query ---

    bool isErrorGrapheme(size_t targetIdx) const
    {
        assert(finalized_);
        if (!errorVector_) return false;

        size_t bytePos = getByteOffset(targetIdx);
        if (bytePos > byteLength_) return false;
        return getBit(errorVector_, bytePos - 1);
    }

    // --- Accessors ---

    size_t graphemeCount() const { return graphemeCount_; }
    size_t byteLength()    const { return byteLength_;    }

private:
    static const size_t SUMMARY_WORDS = 8;

    size_t    byteLength_;
    size_t    graphemeCount_;
    uint64_t* bitVector_;
    uint64_t* errorVector_;
    uint64_t* summaryTable_;
    size_t    summarySize_;
    bool      finalized_;

    static size_t wordCount(size_t byteLen) { return (byteLen + 63) / 64; }

    static uint64_t* allocWords(size_t count)
    {
        uint64_t* p = (uint64_t*)calloc(count, sizeof(uint64_t));
        if (!p) throw std::bad_alloc();
        return p;
    }

    static void freeWords(uint64_t* p) { free(p); }

    static void setBit(uint64_t* vec, size_t bitIndex)
    {
        vec[bitIndex >> 6] |= (uint64_t)1 << (bitIndex & 63);
    }

    static bool getBit(const uint64_t* vec, size_t bitIndex)
    {
        return (vec[bitIndex >> 6] >> (bitIndex & 63)) & 1;
    }
};


// ============================================================================
// TransformMapping
//
// Ephemeral structure built during transformation. Maps between:
//   - external grapheme positions (in the untransformed subtext)
//   - internal byte positions (in the transformed subtext)
//
// Built once per transformation, replaces the per-call re-transformation
// that the ooRexx ib2xc method does.
//
// Layout:
//   For each external grapheme g (0-based index into the arrays):
//     xGraphemeIndex[g] = 1-based grapheme index in external subtext
//     iByteLow[g]       = 1-based start byte in internal (transformed) text
//     iByteHigh[g]      = 1-based end byte + 1 in internal text (exclusive)
//
//   So the internal bytes produced by external grapheme g are
//   [iByteLow[g] .. iByteHigh[g] - 1].
//
//   If a grapheme is stripped (transforms to empty string), then
//   iByteLow[g] == iByteHigh[g] (zero-length range).
//
// The ib2xc lookup is then a binary search on iByteLow[], which is
// monotonically non-decreasing.
//
// Memory: 3 × sizeof(size_t) × externalGraphemeCount.
// For a 10000-grapheme string, that's ~240 KB on 64-bit — acceptable
// for an ephemeral search-time structure.
// ============================================================================

class TransformMapping
{
public:
    TransformMapping(const TransformMapping&) = delete;
    TransformMapping& operator=(const TransformMapping&) = delete;

    // Allocate for a known number of external graphemes.
    explicit TransformMapping(size_t externalGraphemeCount)
        : count_(0)
        , capacity_(externalGraphemeCount)
    {
        xGraphemeIndex_ = (size_t*)calloc(capacity_, sizeof(size_t));
        iByteLow_       = (size_t*)calloc(capacity_, sizeof(size_t));
        iByteHigh_      = (size_t*)calloc(capacity_, sizeof(size_t));
        if (!xGraphemeIndex_ || !iByteLow_ || !iByteHigh_)
            throw std::bad_alloc();
    }

    ~TransformMapping()
    {
        free(xGraphemeIndex_);
        free(iByteLow_);
        free(iByteHigh_);
    }

    // --- Building phase ---
    //
    // Called once per external grapheme, in order, during transformation.
    //
    // xGraphemeIdx : 1-based grapheme index in external subtext
    // iByteLow     : 1-based start byte of this grapheme's transformed bytes
    // iByteHigh    : 1-based byte AFTER the last transformed byte (exclusive)
    //
    // For a stripped grapheme: iByteLow == iByteHigh.

    void addEntry(size_t xGraphemeIdx, size_t iByteLow, size_t iByteHigh)
    {
        assert(count_ < capacity_);
        xGraphemeIndex_[count_] = xGraphemeIdx;
        iByteLow_[count_]       = iByteLow;
        iByteHigh_[count_]      = iByteHigh;
        count_++;
    }

    // --- Lookup: internal byte position --> external grapheme ---
    //
    // Given a 1-based byte position in the internal (transformed) text,
    // find which external grapheme produced those bytes, and whether
    // the byte position is aligned with the start of that grapheme's
    // transformed output.
    //
    // This replaces the stateful dual-cursor walk in ooRexx's ib2xc.
    // O(log n) via binary search on iByteLow_.

    Ib2xcResult lookup(size_t iBytePos,
                       size_t startC,   // global grapheme offset of subtext
                       size_t startB    // global byte offset of subtext
                       ) const
    {
        Ib2xcResult result;

        // Binary search: find the last entry where iByteLow <= iBytePos.
        //
        // We want the largest index `lo` such that iByteLow_[lo] <= iBytePos.
        // This identifies the external grapheme that "owns" the byte at iBytePos.

        size_t lo = 0, hi = count_;
        while (lo + 1 < hi)
        {
            size_t mid = lo + (hi - lo) / 2;
            if (iByteLow_[mid] <= iBytePos)
                lo = mid;
            else
                hi = mid;
        }

        // lo is now the owning grapheme (0-based in the mapping array).
        //
        // Aligned means: iBytePos falls exactly on this grapheme's iByteLow.
        // Not aligned means: iBytePos is in the middle of this grapheme's
        // transformed bytes, so a match starting or ending here would split
        // a grapheme. Example: searching for "s" in "ß" (which casefolded
        // to "ss") — the match covers byte 1 of "ss" but the grapheme "ß"
        // occupies bytes 1-2.

        result.aligned = (iByteLow_[lo] == iBytePos);

        // Convert to global positions.
        // xGraphemeIndex_[lo] is relative to the subtext (1-based).
        // startC is the global grapheme position of the subtext's first grapheme.
        result.graphemePosC = startC - 1 + xGraphemeIndex_[lo];

        // startB is the global byte position of the subtext's first byte.
        result.bytePosB = startB - 1 + iBytePos;

        return result;
    }

    // --- Convenience: check alignment at the end of a match ---
    //
    // A match ending at internal byte position iBytePos is aligned if
    // iBytePos falls exactly on the iByteLow of a grapheme (meaning the
    // match covers the ENTIRE last grapheme up to — but not including —
    // the next one).

    bool isAlignedEnd(size_t iBytePos) const
    {
        // iBytePos here is the "one past end" position of the match
        // in the internal text. It must equal some iByteLow (or be
        // past the end of the entire internal text).
        if (iBytePos > totalInternalBytes())
            return true;   // past-end is always aligned

        // Binary search for exact match in iByteLow_
        size_t lo = 0, hi = count_;
        while (lo < hi)
        {
            size_t mid = lo + (hi - lo) / 2;
            if (iByteLow_[mid] < iBytePos)
                lo = mid + 1;
            else if (iByteLow_[mid] > iBytePos)
                hi = mid;
            else
                return true;   // exact match found
        }
        return false;
    }

    // --- Accessors ---

    size_t count() const { return count_; }

    size_t totalInternalBytes() const
    {
        // The last entry's iByteHigh - 1 is the last internal byte.
        // iByteHigh of the last entry = one past end.
        if (count_ == 0) return 0;
        return iByteHigh_[count_ - 1] - 1;
    }

    // Get the iByteLow for the grapheme AFTER the one at mapping index `idx`.
    // Used to advance the search position past a matched grapheme.
    size_t nextGraphemeIByte(size_t mappingIdx) const
    {
        if (mappingIdx + 1 < count_)
            return iByteLow_[mappingIdx + 1];
        return iByteHigh_[mappingIdx];   // past end
    }

private:
    size_t  count_;
    size_t  capacity_;
    size_t* xGraphemeIndex_;   // external grapheme index (1-based, relative)
    size_t* iByteLow_;         // internal byte start (1-based, inclusive)
    size_t* iByteHigh_;        // internal byte end (1-based, exclusive)
};


// ============================================================================
// Placeholder: RexxText
//
// Represents a string + its GraphemeIndexer. In the real implementation,
// this would be the C-level backing for ooRexx's RexxText object.
// ============================================================================

struct RexxText
{
    const char*     bytes;       // raw UTF-8 byte string (not owned)
    size_t          byteLength;  // length in bytes
    GraphemeIndexer* indexer;    // owned, built during construction

    // In a real implementation, this would be constructed by the
    // encoding's createIndexer method. Here we just store the pieces.

    RexxText(const char* b, size_t len, GraphemeIndexer* idx)
        : bytes(b), byteLength(len), indexer(idx)
    {}
};


// ============================================================================
// PLACEHOLDER FUNCTIONS
//
// These represent operations that would delegate to utf8proc, ICU, or
// your own Unicode library. They are declared here so the architectural
// code compiles conceptually — their bodies would live elsewhere.
// ============================================================================

// Transform a single grapheme's UTF-8 bytes according to the given options.
// Returns the number of bytes written to `outBuf`.
// `outBuf` must be large enough (worst case: ~18× for NFKD + casefold).
//
// This replaces the ooRexx:
//   c~transform(:normalization, :casefold, ..., returnString:.true)
size_t transform_grapheme(
    const char* graphemeBytes, size_t graphemeByteLen,
    char* outBuf, size_t outBufSize,
    const TransformOptions& opts);

// Transform an entire RexxText, producing a new byte string and its
// GraphemeIndexer. In the real implementation, this might use a
// memorization cache.
//
// Returns a RexxText that owns its bytes and indexer.
// Caller must free the returned RexxText.
RexxText* transform_text(const RexxText* src, const TransformOptions& opts);

// Byte-level substring search (like C's strstr but with offset and length).
// Returns 1-based byte position of `needle` in `haystack` starting from
// `startB` (1-based), or 0 if not found.
//
// This is the fast path — it delegates to the native ooRexx String~pos
// or to a C-level algorithm like Boyer-Moore.
size_t byte_strstr(
    const char* haystack, size_t haystackLen,
    const char* needle,   size_t needleLen,
    size_t startB /* 1-based */);


// ============================================================================
// TextTransformer
//
// Corresponds to ooRexx's RexxTextTransformer class.
//
// Holds:
//   - The external subtext (a slice of the original full text)
//   - The internal subtext (the transformed version)
//   - The TransformMapping (precomputed during transformation)
//
// Key difference from the ooRexx version: the per-grapheme mapping is
// precomputed during transform(), so ib2xc() is a stateless binary
// search instead of a stateful cursor walk.
// ============================================================================

class TextTransformer
{
public:
    TextTransformer(const TextTransformer&) = delete;
    TextTransformer& operator=(const TextTransformer&) = delete;

    // ---------------------------------------------------------------
    // Construction
    //
    // fulltext : the complete original text
    // startC   : 1-based grapheme start position in fulltext
    // lengthC  : number of graphemes to include
    //
    // Corresponds to ooRexx:
    //   .RexxTextTransformer~new(fulltext, startC, lengthC)
    // ---------------------------------------------------------------

    TextTransformer(const RexxText* fulltext, size_t startC, size_t lengthC)
        : fulltext_(fulltext)
        , startC_(startC)
        , startB_(0)
        , xSubtext_(nullptr)
        , iSubtext_(nullptr)
        , mapping_(nullptr)
        , transformed_(false)
    {
        // Resolve the byte position of startC using the fulltext's
        // GraphemeIndexer. This is the select query.
        startB_ = fulltext_->indexer->getByteOffset(startC_);

        // Extract the external subtext.
        // In a real implementation, this would be fulltext->substr(startC, lengthC).
        // For this illustration, we store the slice boundaries.
        // The xSubtext_ would be a RexxText over the substring.
        //
        // Placeholder: we'd build xSubtext_ here.
        // xSubtext_ = substr(fulltext, startC, lengthC);
        (void)lengthC;
    }

    ~TextTransformer()
    {
        // In a real implementation: free iSubtext_ and mapping_
        // if they were allocated by transform().
        delete mapping_;
        // delete iSubtext_;   // if we own it
    }

    // ---------------------------------------------------------------
    // transform()
    //
    // Applies the Unicode transformation to xSubtext_, producing
    // iSubtext_ AND building the TransformMapping in a single pass.
    //
    // This is the key architectural change from the ooRexx version:
    // instead of transforming the whole string and then re-transforming
    // individual graphemes in ib2xc, we capture the mapping HERE.
    //
    // Returns `this` for chaining, matching the ooRexx pattern:
    //   transformer = fulltext~transformer(4,5)~transform(...)
    // ---------------------------------------------------------------

    TextTransformer* transform(const TransformOptions& opts)
    {
        assert(!transformed_);

        opts_ = opts;

        // ---------------------------------------------------------
        // PHASE 1: Walk xSubtext_ grapheme by grapheme.
        //
        // For each external grapheme:
        //   1. Extract its bytes from xSubtext_
        //   2. Transform the grapheme (normalize, casefold, etc.)
        //   3. Append the transformed bytes to the internal buffer
        //   4. Record the mapping entry
        //
        // This produces both iSubtext_ and mapping_ in one pass.
        // ---------------------------------------------------------

        size_t xGraphemeCount = xSubtext_->indexer->graphemeCount();

        // Allocate the mapping
        mapping_ = new TransformMapping(xGraphemeCount);

        // Buffer for the internal (transformed) bytes.
        // Worst case: each grapheme can expand substantially
        // (e.g., ﬄ -> ffl under NFKD, ß -> ss under casefold).
        // We'll grow as needed in a real implementation.
        size_t iBufCapacity = xSubtext_->byteLength * 4; // generous estimate
        char* iBuf = (char*)malloc(iBufCapacity);
        if (!iBuf) throw std::bad_alloc();

        size_t iBufLen = 0;       // current length of internal buffer
        char   tmpBuf[256];       // per-grapheme transform output buffer

        for (size_t g = 1; g <= xGraphemeCount; g++)
        {
            // Get the byte range of grapheme g in xSubtext_.
            size_t gByteStart = xSubtext_->indexer->getByteOffset(g);     // 1-based
            size_t gByteEnd;
            if (g < xGraphemeCount)
                gByteEnd = xSubtext_->indexer->getByteOffset(g + 1);      // 1-based, exclusive
            else
                gByteEnd = xSubtext_->byteLength + 1;                     // past end

            size_t gByteLen = gByteEnd - gByteStart;

            // Transform this single grapheme
            size_t transformedLen = transform_grapheme(
                xSubtext_->bytes + (gByteStart - 1),   // pointer to grapheme bytes
                gByteLen,
                tmpBuf, sizeof(tmpBuf),
                opts_
            );

            // Record the mapping entry BEFORE appending.
            //
            //   xGraphemeIndex = g (1-based in xSubtext)
            //   iByteLow       = iBufLen + 1 (1-based start in internal text)
            //   iByteHigh      = iBufLen + 1 + transformedLen (exclusive)
            //
            // If the grapheme was stripped (transformedLen == 0), then
            // iByteLow == iByteHigh, which correctly represents a zero-
            // length range.

            size_t iLow  = iBufLen + 1;
            size_t iHigh = iBufLen + 1 + transformedLen;
            mapping_->addEntry(g, iLow, iHigh);

            // Append transformed bytes to internal buffer
            // (grow if needed — omitted for brevity)
            memcpy(iBuf + iBufLen, tmpBuf, transformedLen);
            iBufLen += transformedLen;
        }

        // Build the internal subtext's GraphemeIndexer.
        // In a real implementation, this would scan iBuf for grapheme
        // boundaries. For this illustration, we assume it's done.
        //
        // GraphemeIndexer* iIndexer = buildIndexer(iBuf, iBufLen);
        // iSubtext_ = new RexxText(iBuf, iBufLen, iIndexer);

        (void)iBuf;
        (void)iBufLen;

        transformed_ = true;
        return this;
    }

    // ---------------------------------------------------------------
    // ib2xc()
    //
    // Convert an internal byte position (1-based, relative to iSubtext)
    // to an external grapheme position (1-based, GLOBAL in fulltext).
    //
    // This is now STATELESS — it just delegates to the precomputed
    // TransformMapping. No cursors, no backup/restore, no per-grapheme
    // re-transformation.
    //
    // Corresponds to ooRexx's ib2xc method, but replaces:
    //   - The dual-cursor walk
    //   - The per-grapheme c~transform() calls
    //   - The sign-encoding of alignment
    //   - The backup/restore mechanism
    //
    // with a single binary search on the precomputed mapping.
    // ---------------------------------------------------------------

    Ib2xcResult ib2xc(size_t iBytePos) const
    {
        assert(transformed_);
        return mapping_->lookup(iBytePos, startC_, startB_);
    }

    // ---------------------------------------------------------------
    // Convenience: check if a match endpoint is aligned.
    // ---------------------------------------------------------------

    bool isAlignedEnd(size_t iBytePos) const
    {
        assert(transformed_);
        return mapping_->isAlignedEnd(iBytePos);
    }

    // ---------------------------------------------------------------
    // Accessors
    // ---------------------------------------------------------------

    const RexxText* xSubtext() const { return xSubtext_; }
    const RexxText* iSubtext() const { return iSubtext_; }
    size_t startC() const { return startC_; }
    size_t startB() const { return startB_; }

private:
    const RexxText*   fulltext_;
    size_t            startC_;       // global grapheme offset
    size_t            startB_;       // global byte offset (from GraphemeIndexer select)
    const RexxText*   xSubtext_;     // external subtext (slice of fulltext)
    RexxText*         iSubtext_;     // internal subtext (transformed)
    TransformMapping* mapping_;      // the precomputed internal<->external map
    TransformOptions  opts_;
    bool              transformed_;
};


// ============================================================================
// posText()
//
// Architectural illustration of the ooRexx posText method in C++.
//
// Shows how GraphemeIndexer, TextTransformer, and TransformMapping
// work together to implement Unicode-aware substring search with
// grapheme alignment checking.
//
// Parameters:
//   haystack    : the text to search in (has a GraphemeIndexer)
//   needle      : the text to search for
//   startC      : 1-based grapheme position to start searching (global)
//   lengthC     : number of graphemes in the search area
//   opts        : transformation options (normalization, casefold, etc.)
//   aligned     : if true, only report matches on grapheme boundaries
//
// Returns:
//   0           : not found (or found but not aligned)
//   > 0         : 1-based grapheme position of the match in haystack (global)
//
// For the non-aligned / asList modes: the ooRexx version returns richer
// structures. This illustration focuses on the aligned=true case.
// ============================================================================

size_t posText(
    const RexxText*        haystack,
    const RexxText*        needle,
    size_t                 startC,
    size_t                 lengthC,
    const TransformOptions& opts,
    bool                   aligned)
{
    // -----------------------------------------------------------------
    // Step 0: Early exits
    // -----------------------------------------------------------------

    if (haystack->indexer->graphemeCount() == 0) return 0;
    if (needle->indexer->graphemeCount() == 0)   return 0;
    if (startC > haystack->indexer->graphemeCount()) return 0;

    // Clamp lengthC
    size_t maxLen = haystack->indexer->graphemeCount() - startC + 1;
    if (lengthC > maxLen) lengthC = maxLen;
    if (lengthC == 0) return 0;

    // -----------------------------------------------------------------
    // Step 1: Transform the search area and the needle.
    //
    // This builds:
    //   - searchTransformer->iSubtext() : the transformed search area
    //   - searchTransformer->mapping_   : the internal<->external map
    //   - needleTransformed              : the transformed needle
    //
    // The GraphemeIndexer of the haystack is used here to resolve
    // startC --> startB (the select query).
    // -----------------------------------------------------------------

    TextTransformer searchTransformer(haystack, startC, lengthC);
    searchTransformer.transform(opts);

    RexxText* needleTransformed = transform_text(needle, opts);

    // Get raw byte pointers for the fast byte-level search.
    const char* searchBytes    = searchTransformer.iSubtext()->bytes;
    size_t      searchBytesLen = searchTransformer.iSubtext()->byteLength;
    const char* needleBytes    = needleTransformed->bytes;
    size_t      needleBytesLen = needleTransformed->byteLength;

    // -----------------------------------------------------------------
    // Step 2: Search loop
    //
    // Use fast byte-level search on the transformed strings, then
    // validate grapheme alignment using the TransformMapping.
    //
    // This mirrors the ooRexx do-forever loop in posText, but replaces
    // the stateful ib2xc calls with stateless binary searches.
    // -----------------------------------------------------------------

    size_t searchStartB = 1;   // 1-based byte position in iSubtext

    for (;;)
    {
        // --- 2a. Fast byte search ---
        //
        // This is the native string~pos call: find the needle bytes
        // somewhere in the transformed search area bytes.

        size_t posBFirst = byte_strstr(
            searchBytes, searchBytesLen,
            needleBytes, needleBytesLen,
            searchStartB
        );

        if (posBFirst == 0)
            break;   // not found at all

        // --- 2b. Check alignment of match START ---
        //
        // posBFirst is a byte position in the transformed (internal) text.
        // We need to know:
        //   1. Which external grapheme does this byte belong to?
        //   2. Is the byte aligned with the start of that grapheme's
        //      transformed output?
        //
        // Example:
        //   External "ß" -> Internal "ss" (casefold)
        //   If needle is "s", byte search finds posBFirst = 1.
        //   ib2xc(1) -> grapheme "ß", aligned = true (byte 1 is the
        //   start of ß's transformed output).
        //   But the match END is at byte 2, and ß's output occupies
        //   bytes 1-2, so the END is not aligned (it would need to be
        //   at byte 3 to cover the entire grapheme).

        Ib2xcResult startResult = searchTransformer.ib2xc(posBFirst);

        // --- 2c. Check alignment of match END ---
        //
        // The match covers bytes [posBFirst .. posBFirst + needleBytesLen - 1].
        // The "one past end" position is:
        size_t posBLastPlus1 = posBFirst + needleBytesLen;

        // The END is aligned if posBLastPlus1 falls on a grapheme boundary
        // in the internal text (i.e., it equals some entry's iByteLow).
        // This check does NOT need ib2xc — it only needs the mapping.

        bool endAligned = searchTransformer.isAlignedEnd(posBLastPlus1);

        // --- 2d. Decide ---

        if (aligned)
        {
            // Both start and end must be aligned for a valid match.
            if (startResult.aligned && endAligned)
            {
                // Match found! Return the global grapheme position.
                // free needleTransformed...
                return startResult.graphemePosC;
            }

            // Not aligned — advance and try again.
            // Advance by 1 byte in the internal text (pessimistic but safe).
            // A smarter strategy: advance to the next grapheme boundary
            // in the internal text, which we can get from the mapping.
            searchStartB = posBFirst + 1;
        }
        else
        {
            // Non-aligned mode: return the match even if not on a
            // grapheme boundary. The ooRexx version encodes this as
            // +/-posC.posB; in C we'd return a richer result struct.
            // For this illustration, just return the grapheme position.
            // free needleTransformed...
            return startResult.graphemePosC;
        }

        // --- 2e. Ligature guard ---
        //
        // Ensure we don't re-search within the expansion of a
        // partially matched grapheme.
        //
        // Example: "ﬄ" -> "ffl" (NFKD). If we searched for "ff"
        // and found it at byte 1 of "ffl", but the match is not
        // aligned (it doesn't cover all 3 bytes of ﬄ's expansion),
        // we must skip past the ENTIRE "ffl" before retrying.
        //
        // This is what the ooRexx code does with:
        //   searchAreaNormalizedStartB = max(searchAreaNormalizedStartB,
        //       searchAreaTransformer~iSubtextPosB)
        //
        // With the precomputed mapping, we can compute this directly.
        // (In this simplified illustration, the +1 advance above is
        // a safe fallback; a production version would use the mapping
        // to skip to the next grapheme boundary.)
    }

    // free needleTransformed...
    return 0;   // not found
}


// ============================================================================
// USAGE EXAMPLE
//
// Shows the full flow for:
//   "Père Noël Père Noël"~caselessPos("OË") = 7
//
// Step by step:
//
// 1. The haystack "Père Noël Père Noël" has a GraphemeIndexer built
//    at construction time. The indexer's bit-vector has a 1-bit at each
//    byte that starts a grapheme:
//
//    Bytes:     P  è  r  e     N  o  ë  l     P  è  r  e     N  o  ë  l
//    (UTF-8):   50 C3A8 72 65 20 4E 6F C3AB 6C 20 50 C3A8 72 65 20 4E 6F C3AB 6C
//    Grapheme:  1  2    3  4  5  6  7  8    9  10 11 12   13 14 15 16 17 18   19
//    BitVec:    1  1 0  1  1  1  1  1  1 0  1  1  1  1 0  1  1  1  1  1  1 0  1
//
//    The GraphemeIndexer allows O(log n) select and rank queries.
//
// 2. caselessPos("OË") calls posText with casefold=true.
//
// 3. posText creates a TextTransformer for the full string (startC=1,
//    lengthC=19). The transform() call:
//
//    a) Walks each external grapheme
//    b) Casefolding: "P"->"p", "è"->"è", ..., "N"->"n", "O"->"o", "Ë"->"ë", ...
//    c) Builds the TransformMapping, recording for each external grapheme
//       which internal bytes it produced:
//
//       External Grapheme 1 "P" -> Internal bytes [1..2)  ("p")
//       External Grapheme 2 "è" -> Internal bytes [2..4)  ("è")
//       External Grapheme 3 "r" -> Internal bytes [4..5)  ("r")
//       ...
//       External Grapheme 7 "O" -> Internal bytes [9..10) ("o")    <-- NOTE: not "O"
//       External Grapheme 8 "Ë" -> Internal bytes [10..12) ("ë")   <-- NOTE: not "Ë"
//       ...
//       (byte positions are illustrative; real positions depend on
//        NFC/NFD and exact casefold output)
//
// 4. The needle "OË" is transformed to "oë" (casefold).
//
// 5. byte_strstr finds "oë" in the internal text at byte position 9.
//
// 6. ib2xc(9) does a binary search on the TransformMapping:
//    -> iByteLow[6] = 9 (0-indexed entry 6, grapheme 7)
//    -> aligned = true (9 == iByteLow exactly)
//    -> graphemePosC = 1 - 1 + 7 = 7
//
// 7. isAlignedEnd(9 + len("oë")) checks if byte 12 is a grapheme boundary:
//    -> iByteLow of the next entry exists and equals 12
//    -> endAligned = true
//
// 8. Both aligned -> return 7.
//
// ============================================================================


#endif // TEXT_TRANSFORMER_HPP
```

---

### Architectural Walkthrough

**Three layers, three lifetimes:**

1. **`GraphemeIndexer`** — permanent, attached to every `RexxText`. 
Provides select (grapheme→byte via `getByteOffset`) and the new rank query (byte→grapheme via `getGraphemeIndex`). 
The haystack's indexer is used at the very start of `posText` to resolve `startC` into `startB`.

2. **`TransformMapping`** — ephemeral, built inside `TextTransformer::transform()`. 
Three parallel arrays (`xGraphemeIndex`, `iByteLow`, `iByteHigh`) record exactly which internal bytes each external grapheme produced. 
This is what eliminates the stateful dual-cursor walk: `ib2xc` becomes a binary search on `iByteLow`.

3. **`TextTransformer`** — ephemeral, one per search operation. 
Owns the mapping and the internal subtext. 
The `transform()` method does a single pass over external graphemes, 
calling `transform_grapheme` once per grapheme, 
appending to the internal buffer 
and populating the mapping simultaneously.

**How `posText` uses them together:**

- `byte_strstr` does the fast work on the transformed bytes (the existing native `String~pos`)
- When it finds a candidate, `ib2xc` does a stateless O(log n) binary search on the mapping to get the external grapheme position and alignment
- `isAlignedEnd` checks the match end with another binary search — no backup/restore needed
- The ligature guard becomes a direct mapping lookup instead of cursor state

**What changed from the ooRexx version:**

- No `previousPosB` monotonicity constraint — each `ib2xc` call is independent
- No `backupPos`/`restorePos` — no state to save
- No per-grapheme `c~transform(...)` in the inner loop — all transforms happen once in `transform()`
- Alignment is a boolean in a struct, not encoded in the sign of an integer

The placeholder functions (`transform_grapheme`, `transform_text`, `byte_strstr`) 
represent the hooks into the existing utf8proc layer and native string search.
