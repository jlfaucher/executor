# ooRexx String Flags: isASCII Review and Merged `setFlags` Proposal

## Review of the `isASCII` Implementation

The caching design with the two-bit tri-state (unchecked / checked-false / checked-true) is well done. The `setIsASCIIChecked(false)` correctly clears the `STRING_ISASCII` bit too — a good defensive detail.

**However, the isASCII flags use a different mechanism** (`#define` bitmasks with `this->Attributes`) than the existing case flags (which use the `FlagSet<StringFlag, 32> attributes` enum-based system). For consistency and to enable the merged `setFlags` approach, I'd recommend migrating `isASCII` to the same `FlagSet` mechanism by adding two new enum entries:

```cpp
typedef enum
{
    STRING_HASLOWER,
    STRING_NOLOWER,
    STRING_HASUPPER,
    STRING_NOUPPER,
    STRING_NONNUMERIC,
    STRING_ISASCII_CHECKED,   // new
    STRING_ISASCII,           // new
} StringFlag;
```

Then the inline methods become:

```cpp
inline bool  isASCIIChecked() const { return attributes[STRING_ISASCII_CHECKED]; }
inline void  setIsASCIIChecked() { attributes.set(STRING_ISASCII_CHECKED); }
inline bool  isASCII() const { return attributes[STRING_ISASCII]; }
inline void  setIsASCII() { attributes.set(STRING_ISASCII); }
inline void  clearIsASCII()
{
    attributes.reset(STRING_ISASCII_CHECKED);
    attributes.reset(STRING_ISASCII);
}
```

This keeps all string flags in one place and avoids mixing two different bitmask systems on the same object.


## The Four-Pointer Scan

The other AI's critique is fair. The four-pointer approach doesn't increase throughput — it's still one byte examined per pointer advancement. It increases the *probability* of early exit for strings that contain non-ASCII bytes, but for the common case (fully ASCII), you pay the full cost with extra pointer bookkeeping overhead.

The word-at-a-time approach (processing 4 or 8 bytes per iteration) is genuinely faster for the all-ASCII case because it reduces loop iterations by 4× or 8×.

**Two corrections to the other AI's code:**

1. The alignment prologue is essential, not optional — ooRexx targets platforms (AIX, Solaris) where unaligned word reads are UB or trap. You need it.

2. The `#ifdef _WIN64 || defined(__LP64__)` is syntactically wrong — preprocessor `#ifdef` only takes a single token. It should be:

```cpp
#if defined(_WIN64) || defined(__LP64__) || defined(__x86_64__) || defined(__aarch64__)
```

Or more simply, just key off `sizeof(size_t)`:

```cpp
bool StringUtil::checkIsASCII(const char *s, size_t length)
{
    const unsigned char *p = (const unsigned char *)s;

    // Alignment prologue: process byte-by-byte until word-aligned
    while (length > 0 && ((uintptr_t)p & (sizeof(size_t) - 1)))
    {
        if (*p & 0x80) return false;
        p++;
        length--;
    }

    // Word-at-a-time: use size_t which is the natural word size on all platforms
    const size_t *w = (const size_t *)p;
    size_t word_size = sizeof(size_t);
    size_t chunks = length / word_size;

    // Per-word early exit: stop as soon as any high bit is found.
    // The branch predictor handles the all-ASCII case efficiently.
    for (size_t i = 0; i < chunks; i++)
    {
        if (w[i] & (size_t)(~(size_t)0 / 0xFF * 0x80))  // 0x8080...80 for any word size
            return false;
    }

    // Tail bytes
    p += chunks * word_size;
    length -= chunks * word_size;
    while (length > 0)
    {
        if (*p & 0x80) return false;
        p++;
        length--;
    }

    return true;
}
```

Using `size_t` as the word type is portable: it's 4 bytes on 32-bit, 8 bytes on 64-bit, no `#ifdef` needed. The mask expression `~(size_t)0 / 0xFF * 0x80` computes `0x80808080` or `0x8080808080808080` at compile time depending on `sizeof(size_t)`.

I changed from the accumulate-then-check-at-end pattern to per-word early exit. The accumulating pattern (`mask |= w[i]` then check once at the end) is only faster when the string is fully ASCII. For the non-ASCII case, per-word checking is better because you stop immediately. Per-word checking is still fast for the all-ASCII case — the branch predictor will predict "not taken" after a few iterations.


## Is the Merged `setFlags` Worth It?

Let's analyze the call patterns:

- **`upper()`** calls `checkLower()` → iterates to find any lowercase byte → then iterates again to copy+uppercase. These two loops can't really merge because `checkLower` is a predicate that might short-circuit the copy entirely.
- **`lower()`** calls `checkUpper()` → same pattern.
- **`checkIsASCII()`** is called from `evaluate()`, which is a completely separate code path.

The key insight is: **`upper()` never calls `checkIsASCII()`, and `evaluate()` never calls `checkLower()/checkUpper()`**. So the "3 loops" don't actually run on the same string in the same call path. They run in different scenarios.

That said, a merged `setFlags` is still worthwhile for a different reason: **opportunistic flag-setting**. When any one of these methods does scan the string, it can cheaply set *all* the flags as a side effect, so that future calls on the same string object skip their scan entirely.


## Implementation of `setFlags`

```cpp
/**
 * Scan the string once and set all character-class flags:
 * hasLower/upperOnly, hasUpper/lowerOnly, and isASCII.
 *
 * After this call, checkLower(), checkUpper(), and checkIsASCII()
 * will all return cached results without re-scanning.
 */
void RexxString::setFlags()
{
    const unsigned char *data = (const unsigned char *)getStringData();
    size_t len = getLength();

    bool foundLower = false;
    bool foundUpper = false;
    bool foundNonASCII = false;

    for (size_t i = 0; i < len; i++)
    {
        unsigned char ch = data[i];

        if (ch & 0x80)
        {
            foundNonASCII = true;
            // Non-ASCII bytes are neither upper nor lower in the C locale,
            // so we can skip the case checks — but we still need to
            // continue scanning to determine upper/lower status of
            // the remaining ASCII bytes... unless we already found both.
            if (foundLower && foundUpper)
            {
                // All three flags determined — no need to continue.
                break;
            }
        }
        else
        {
            // ASCII byte — check case
            if (!foundLower && Utilities::isLower((char)ch))
            {
                foundLower = true;
                if (foundUpper && foundNonASCII)
                    break;  // all flags determined
            }
            else if (!foundUpper && Utilities::isUpper((char)ch))
            {
                foundUpper = true;
                if (foundLower && foundNonASCII)
                    break;  // all flags determined
            }
        }
    }

    // Set the lower/upper flags
    if (foundLower)
        setHasLower();
    else
        setUpperOnly();

    if (foundUpper)
        setHasUpper();
    else
        setLowerOnly();

    // Set the ASCII flags
    setIsASCIIChecked();
    if (!foundNonASCII)
        setIsASCII();
    // else isASCII stays unset (false)
}
```

## Modified Callers

```cpp
bool RexxString::checkLower()
{
    // If we already know the answer, return cached result
    if (hasLower()) return true;
    if (upperOnly()) return false;

    // Scan once and set all flags
    setFlags();
    return hasLower();
}

bool RexxString::checkUpper()
{
    if (hasUpper()) return true;
    if (lowerOnly()) return false;

    setFlags();
    return hasUpper();
}

bool RexxString::checkIsASCII()
{
    if (isASCIIChecked()) return isASCII();

    setFlags();
    return isASCII();
}
```


## Trade-offs

**When this helps:** If `evaluate()` calls `checkIsASCII()` on a string, and later `upper()` or `lower()` is called on the same string object, the case flags are already set — zero cost. Same in reverse.

**When this costs slightly more:** A call to `checkLower()` on a string that's all uppercase will now scan the *entire* string (to set all flags) instead of scanning and finding no lowercase characters with the same cost. But it also sets the ASCII and upper flags as a bonus. The extra work per byte is just an `& 0x80` check and a conditional — negligible.

**For multi-GB strings:** The single-pass approach is a clear win if there's any chance the same string gets multiple flag checks. Even if only one check is needed, the overhead per byte of checking all three properties simultaneously is tiny compared to the memory bandwidth cost of a second full scan.

**One important caveat:** The byte-at-a-time loop in `setFlags` loses the word-at-a-time optimization for the ASCII check. If you want both, you could do the word-at-a-time scan for ASCII as a fast path, then fall back to the byte-at-a-time scan for case flags only when needed. But that adds complexity. For most strings (which are not multi-GB), the simple single-pass byte loop will be plenty fast.

If you want the best of both worlds for very large strings, you could do the word-at-a-time ASCII check first, and if the string *is* ASCII, do the case check in a second pass (which only needs to check `isLower`/`isUpper` on known-ASCII bytes). Two passes over an all-ASCII string is still cache-friendly and much cheaper than three separate scans. But honestly, the single byte-at-a-time pass with all three checks is likely the sweet spot for simplicity and performance.
