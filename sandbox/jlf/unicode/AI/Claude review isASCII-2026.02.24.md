# isASCII code review

## Question

Since you are talking of the is-ascii optimization, here is my implementation.
A string is scanned only once, then the result is cached on the string.

```
#define  STRING_ISASCII_CHECKED 0x08    /* string is ASCII only checked     */
#define  STRING_ISASCII        0x10    /* string is ASCII only              */
   inline bool  isASCIIChecked() {return (this->Attributes & STRING_ISASCII_CHECKED) != 0;};
   inline void  setIsASCIIChecked(bool value=true)
   {
       if (value) this->Attributes |= STRING_ISASCII_CHECKED;
       else
       {
           this->Attributes &= ~STRING_ISASCII_CHECKED;
           this->setIsASCII(false); // isASCII() can be true only when isASCIIChecked() is true
       }
   }
   // if isASCII() is true then it's really ASCII
   // if isASCII() is false then it's really not ASCII only when isASCIIChecked() is true, otherwise can't tell
   inline bool  isASCII() {return (this->Attributes & STRING_ISASCII) != 0;};
   inline void  setIsASCII(bool value=true)
   {
       if (value) this->Attributes |= STRING_ISASCII;
       else this->Attributes &= ~STRING_ISASCII;
   }
bool RexxString::checkIsASCII()
{
    if (this->isASCIIChecked()) return this->isASCII();
    bool isASCII = StringUtil::checkIsASCII(this->getStringData(), this->getLength());
    this->setIsASCII(isASCII);
    this->setIsASCIIChecked(true);
    return isASCII;
}
// In behaviour
RexxInteger *RexxString::isASCIIRexx()
{
    return this->checkIsASCII() ? TheTrueObject : TheFalseObject;
}
/**
 * Checks if the buffer of data contains only ASCII characters.
 *
 * @param data   the source data buffer.
 * @param length the length of the buffer
 *
 * @return true if the buffer of data contains only ASCII characters
 */
bool StringUtil::checkIsASCII(const char *s, size_t length)
{
    if (length != 0)
    {
        // Check from start ascending, from middle descending, from middle ascending, from end descending.
        // That will divide by 4 the number of iterations, while increasing the chance to find a not-ASCII character faster..
        const char *i1 = s;
        const char *i2 = s + (length - 1) / 2;
        const char *i3 = i2;
        const char *i4 = s + length - 1;
        do
        {
            if ( (*i1++ | *i2-- | *i3++ | *i4--) & 0x80 ) return false;
        }
        while (i1 <= i2 || i3 <= i4);
    }
    return true;
}
```

## Feedback

Your `checkIsASCII` implementation is clever and the caching strategy with the
two-bit flag system is clean. The tri-state logic (unchecked / checked-false /
checked-true) encoded in two bits is exactly the right approach for lazy evaluation.

**The four-pointer scan is interesting but I'd question it.**

The idea is sound — you're trying to detect non-ASCII bytes faster by scanning
from four positions simultaneously, increasing the probability of an early exit.
But there are a few issues:

The loop condition `i1 <= i2 || i3 <= i4` is subtle and potentially wrong at the
boundaries. When `length` is odd, `i2` and `i3` start at the same position, meaning
that byte gets OR'd twice in the first iteration — harmless for correctness but
wasted work. More importantly, the four pointers don't actually give you 4x
throughput because the CPU is still doing sequential scalar loads. You're betting
on "early exit" rather than raw throughput.

For the common case (a string that *is* ASCII), you pay the full scan cost regardless,
and the four-pointer approach doesn't help there.

**What actually works better for the "all ASCII" common case is SIMD or
word-at-a-time scanning:**

```c
bool StringUtil::checkIsASCII(const char *s, size_t length)
{
    const unsigned char *p = (const unsigned char *)s;

    // Process 8 bytes at a time
    size_t chunks = length / 8;
    const uint64_t *w = (const uint64_t *)p;
    uint64_t mask = 0;
    for (size_t i = 0; i < chunks; i++)
        mask |= w[i];

    if (mask & 0x8080808080808080ULL) return false;

    // Tail
    for (size_t i = chunks * 8; i < length; i++)
        if (p[i] & 0x80) return false;

    return true;
}
```

This accumulates all bytes with OR before checking the high bit, which lets the
CPU pipeline the loads aggressively. The early-exit behavior is preserved at the
granularity of 8-byte chunks rather than individual bytes.

Note this requires the buffer to be 8-byte aligned or you need an alignment
prologue — worth checking if `RexxString` buffers have alignment guarantees.

**The caching design itself is exactly right.** Two bits, lazy evaluation,
cached on the string object. My only suggestion would be a comment clarifying
the tri-state semantics directly above the `isASCII()` method, since "false means
unknown-or-false" is non-obvious to future maintainers. You already have this in
a comment but it's worth making it impossible to miss.





# 32-bit version of ooRexx

## Question

We have a 32-bit version of ooRexx.
I assume a 32-bit version of your code should be used?


## Answer

Yes, exactly. The word-at-a-time approach should match the natural word size.
Here's a portable version:

```cpp
bool StringUtil::checkIsASCII(const char *s, size_t length)
{
    const unsigned char *p = (const unsigned char *)s;

#ifdef _WIN64 || defined(__LP64__)
    // 64-bit: process 8 bytes at a time
    typedef uint64_t word_t;
    const word_t ASCII_MASK = 0x8080808080808080ULL;
#else
    // 32-bit: process 4 bytes at a time
    typedef uint32_t word_t;
    const word_t ASCII_MASK = 0x80808080UL;
#endif

    size_t word_size = sizeof(word_t);
    size_t chunks = length / word_size;
    const word_t *w = (const word_t *)p;
    word_t mask = 0;

    for (size_t i = 0; i < chunks; i++)
        mask |= w[i];

    if (mask & ASCII_MASK) return false;

    // Tail bytes
    for (size_t i = chunks * word_size; i < length; i++)
        if (p[i] & 0x80) return false;

    return true;
}
```

That said, I'd push back slightly on the premise: even on a 32-bit *platform*,
if the compiler is GCC or Clang, `uint64_t` loads are still available and often
faster than two 32-bit loads because the compiler can emit `movq` or equivalent.
The platform being 32-bit doesn't mean 64-bit arithmetic is unavailable, just
that pointers are 32-bit.

So a more nuanced approach would be to key the decision on `sizeof(void*)` for
pointer width but always attempt 64-bit word processing if `uint64_t` is available
— which it is on all platforms ooRexx targets since it's guaranteed by C99/C++11.

The alignment concern also matters more on 32-bit platforms where strict-alignment
architectures (older ARM, SPARC) are more likely to appear. You might want an
alignment prologue:

```cpp
// Align to word boundary first
while (length > 0 && ((uintptr_t)p & (sizeof(word_t) - 1)))
{
    if (*p++ & 0x80) return false;
    length--;
}
```

This avoids undefined behavior from unaligned `word_t` reads on strict-alignment
platforms, which ooRexx almost certainly needs to support given its AIX and
Solaris targets.

