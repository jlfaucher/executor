# Byte-to-Grapheme Reverse Lookup — Review Conversation

## User

*Uploaded file: `question2b-byte_to_grapheme.txt`*

### Context

In the previous review of the `GraphemeIndexer`, design consideration #6 noted:

> The ooRexx String class likely needs a reverse lookup (byteOffset → graphemeIndex) too — for instance, `pos()` returns a character position, so after finding a byte match the result needs to be converted back to a grapheme index. This would be a "rank" query on the bit-vector, which is actually simpler than "select": binary-search the summary table, then popcount the remaining words. Worth adding.

The response: it's more complicated than a simple byteOffset → graphemeIndex.

The caseless methods work on strings that can be shorter or longer than the original string. This is called **contraction and expansion**. Two cursors must be managed:

- An **external cursor** in the external untransformed subtext (`xSubtextPosC`)
- An **internal cursor** in the internal transformed subtext (`iSubtextPosB`)

Each cursor has a byte position and a character (grapheme) position.

### Examples

```
-- caselessPos
"Père Noël Père Noël"~caselessPos("OË")=                   -- 7
"Père Noël Père Noël"~caselessPos("OË", 8)=                -- 17
"Père Noël Père Noël"~caselessPos("OË", 8, 10)=            -- 0
"Père Noël Père Noël"~caselessPos("OE")=                   -- 0
"Père Noël Père Noël"~caselessPos("OE", stripMark:)=       -- 7
"noël👩‍👨‍👩‍👧🎅"~caselessPos("🎅")=                  -- 6
"noël👩‍👨‍👩‍👧🎅"~caselessPos("👧🎅")=               -- 0

-- caselessPos in not-aligned mode
"noël👩‍👨‍👩‍👧🎅"~caselessPos("👧🎅", aligned:.false)=           -- [-5.27,+7.35]
"noël👩‍👨‍👩‍👧🎅"~caselessPos("👩‍👨‍👩‍👧🎅", aligned:.false)=   -- [+5.6,+7.35]

-- pos
"noel"~pos("oe")=           -- 2
"noel"~pos("oë")=           -- 0
"noël"~pos("oe")=           -- 0
"noël"~pos("oë")=           -- 2
"noël"~pos("l")=            -- 4
"Père Noël Père Noël"~pos("oë")=                        -- 7
"Père Noël Père Noël"~pos("oë", 8)=                     -- 17
"Père Noël Père Noël"~pos("oë", 8, 10)=                 -- 0
"Père Noël Père Noël"~pos("oe")=                        -- 0
"Père Noël Père Noël"~pos("oe", stripMark:)=            -- 7
"noël👩‍👨‍👩‍👧🎅"~pos("🎅")=                      -- 6
"noël👩‍👨‍👩‍👧🎅"~pos("👧🎅")=                    -- 0
"noël👩‍👨‍👩‍👧🎅"~pos("👧🎅", aligned:.false)=    -- [-5.27,+7.35]
"noël👩‍👨‍👩‍👧🎅"~pos("👩‍👨‍👩‍👧🎅", aligned:.false)=   -- [+5.6,+7.35]
```

### Illustration of the Coordinate Spaces

```
fulltext = "éßﬄ#éßﬄ#…"~text
transformer = fulltext~transformer(4, 5)~NFD(casefold:)

                     --                          Transformed part of the full text
                     --                       +-------------------------------------+
                     --  01   | 02   | 03     | 04 | 05     | 06    | 07       | 08 | 09
                     --  1 2  | 3 4  | 5 6 7  | 8  | 9 0    | 1 2   | 3 4 5    | 6  | 7 8 9
"éßﬄ#éßﬄ#…"~c2g   --  C3A9 | C39F | EFAC84 | 23 | C3A9   | C39F  | EFAC84   | 23 | E280A6
                     --  é    | ß    | ﬄ     | #  | é      | ß     | ﬄ       | #  | …

                                              --  RELATIVE INDEXES (external)
                                              --  01 | 02     | 03    | 04       | 05
                                              --  1  | 2 3    | 4 5   | 6 7 8    | 9
"#éßﬄ#"~c2g=                                --  23 | C3A9   | C39F  | EFAC84   | 23
                                              --  #  | é      | ß     | ﬄ       | #

                                              --  RELATIVE INDEXES (internal, after NFD + casefold)
                                              --  01 | 02     | 03 04 | 05 06 07 | 08
                                              --  1  | 2 3 4  | 5  6  | 7  8  9  | 0
"#éßﬄ#"~NFD(casefold:)~c2g=                 --  23 | 65CC81 | 73 73 | 66 66 6C | 23
                                              --  #  | é      | s  s  | f  f  l  | #
```

### ooRexx Implementation

The `posText` method, `RexxTextTransformer` class, and `ib2xc` method were provided for review. Key points:

- `ib2xc` converts an internal byte position in the transformed subtext to an external character (grapheme) position in the untransformed full text
- It uses a dual-cursor walk: advance the external cursor one grapheme at a time, transforming each grapheme, accumulating internal bytes until reaching or overshooting the target
- Aligned matches return positive positions; non-aligned matches return negative positions
- A backup/restore mechanism allows probing the end position without permanently advancing the cursor

### ooRexx Code

#### `caselessPos` and `pos`

```rexx
::method caselessPos
    use strict arg needle, startC=1, lengthC=(self~length)
    use strict named arg strict=.true, normalization=(.Unicode~defaultNormalization(:strict)),
        lump=(\strict), stripIgnorable=(\strict), stripMark=.false, stripCC=.false,
        stripNA=.false, aligned=.true, asList=.false, overlap=.false, debug=.false
    return self~posText(needle, startC, lengthC, :normalization, casefold:.true,
        :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA, :aligned, :asList, :overlap, :debug)


::method pos
    use strict arg needle, startC=1, lengthC=(self~length)
    use strict named arg strict=.true, normalization=(.Unicode~defaultNormalization(:strict)),
        lump=(\strict), stripIgnorable=(\strict), stripMark=.false, stripCC=.false,
        stripNA=.false, aligned=.true, asList=.false, overlap=.false, debug=.false
    return self~posText(needle, startC, lengthC, :normalization, casefold:.false,
        :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA, :aligned, :asList, :overlap, :debug)
```

#### `posText`

```rexx
::method posText private
    use strict arg needle, startC=1, lengthC=(self~length)
    use strict named arg normalization, casefold, lump, stripIgnorable, stripMark,
        stripCC, stripNA, aligned=.true, asList=.false, overlap=.false, debug=.false

    needleText = needle~request("RexxText")
    if .nil == needleText then signal argument_1_must_have_a_text_or_string_value

    .Encoding~comparisonMode(self, needleText)

    if \datatype(startC, "w") then signal invalid_position
    if startC < 1 then signal invalid_position
    if \datatype(lengthC, "w") then signal invalid_length
    if lengthC < 0 then signal invalid_length
    if length == 0 then return 0
    if self~length == 0 then return 0
    if needleText~length == 0 then return 0
    if startC > self~length then return 0

    lengthC = min(lengthC, self~length - startC + 1)
    searchAreaTransformer = self~transformer(startC, lengthC)
        ~transform(:normalization, :casefold, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA)
    needleTextTransformed = needleText
        ~transform(:normalization, :casefold, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA)
    searchArea =            searchAreaTransformer~xSubtext
    searchAreaTransformed = searchAreaTransformer~iSubtext

    -- default result
    if asList then list = .list~new
    else pos = 0

    startB = self~characterIndexB(startC)
    searchAreaNormalizedStartB = 1
    do forever
        posBFirst = searchAreaTransformed~string~pos(
            needleTextTransformed~string, searchAreaNormalizedStartB)
        if posBFirst == 0 then leave -- not found

        posCFirst = searchAreaTransformer~ib2xc(posBFirst, :aligned, :debug)

        posCLastPlus1 = .nil
        if \(aligned & posCFirst < 0) then do
            posBLastPlus1 = posBFirst + needleTextTransformed~string~length
            searchAreaTransformer~backupPos
            posCLastPlus1 = searchAreaTransformer~ib2xc(posBLastPlus1, :aligned, :debug)
            searchAreaTransformer~restorePos
        end

        if aligned, .nil == posCFirst | .nil == posCLastPlus1 then pos = 0
        else if aligned, posCFirst < 0 | posCLastPlus1 < 0 then pos = 0
        else if \aligned then pos = (posCFirst, posCLastPlus1)
        else pos = posCFirst

        if pos \== 0 then do
            if asList then list~append(pos)
            else leave
        end

        if pos == 0 then searchAreaNormalizedStartB += 1
        else if overlap then searchAreaNormalizedStartB = posBFirst + 1
        else searchAreaNormalizedStartB = posBFirst + needleTextTransformed~string~length
        searchAreaNormalizedStartB = max(searchAreaNormalizedStartB,
            searchAreaTransformer~iSubtextPosB) -- for ligatures like "ﬄ"
    end
    if asList then return list
    return pos
```

#### `RexxTextTransformer` class (key methods)

```rexx
::class "RexxTextTransformer" public

::method init
    expose fulltext startB startC -
           xSubtext -
           iSubtext -
           backupCount transformed

    use strict arg fulltext, startC=1,
        lengthC=(max(0, fulltext~length - startC + 1)),
        pad=(fulltext~encoding~spaceCharacter)

    self~resetPos
    startB = fulltext~indexer~characterIndexB(startC)
    if startC == 1, lengthC == fulltext~length then xSubtext = fulltext
    else xSubtext = fulltext~substr(startC, lengthC, pad)
    iSubtext = .nil
    backupCount = 0
    transformed = .false


::method transform
    expose xSubtext iSubtext -
           normalization casefold lump stripIgnorable stripMark stripCC stripNA -
           transformed
    use strict named arg normalization, casefold, lump, stripMark,
        stripIgnorable, stripCC, stripNA, memorize

    if transformed then raise syntax 93.900 array("A transformation has already been applied")
    iSubtext = xSubtext~transform(:normalization, :casefold, :lump,
        :stripIgnorable, :stripMark, :stripCC, :stripNA, :memorize)
    transformed = .true
    self~resetPos
    return self


::method resetPos
    expose xSubtextPosC iSubtextPosB previousPosB
    xSubtextPosC = 1
    iSubtextPosB = 1
    previousPosB = 0


::method backupPos
    expose xSubtextPosC iSubtextPosB previousPosB -
           xSubtextPosC_ iSubtextPosB_ previousPosB_ -
           backupCount
    if backupCount == 1 then raise syntax 93.900 array("the backup stack is full")
    xSubtextPosC_ = xSubtextPosC
    iSubtextPosB_ = iSubtextPosB
    previousPosB_ = previousPosB
    backupCount += 1


::method restorePos
    expose xSubtextPosC iSubtextPosB previousPosB -
           xSubtextPosC_ iSubtextPosB_ previousPosB_ -
           backupCount
    if backupCount == 0 then raise syntax 93.900 array("the backup stack is empty")
    xSubtextPosC = xSubtextPosC_
    iSubtextPosB = iSubtextPosB_
    previousPosB = previousPosB_
    backupCount -= 1
```

#### `ib2xc` — Internal Byte to External Character

```rexx
::method ib2xc
    expose,
        startB startC -
        xSubtext xSubtextPosC -
        iSubtext iSubtextPosB -
        normalization casefold lump stripIgnorable stripMark stripCC stripNA -
        previousPosB transformed

    use strict arg posB
    use strict named arg aligned=.true, debug=.false

    if \transformed then raise syntax 93.900 array("You must apply a transformation before using 'ib2xc'")
    if posB < previousPosB then raise syntax 93.900 array("Byte position lower than previous one")
    previousPosB = posB

    posC = iSubtext~indexer~characterIndexC(posB)
    absposC = abs(posC)

    do while xSubtextPosC <= xSubtext~length
        if iSubtextPosB == posB then leave  -- exactly reached

        c = xSubtext~character(xSubtextPosC)
        cTransformed = c~transform(:normalization, :casefold, :lump,
            :stripIgnorable, :stripMark, :stripCC, :stripNA,
            memorize:.false, returnString:.true)

        iSubtextPosB += cTransformed~string~length
        xSubtextPosC += 1

        if iSubtextPosB > posB then do
            /*
            Case where the start or end of the matching does not cover all
            the bytes of the transformed grapheme.
            Ex:
            - "ß"~text~caselessPos("s") --> 0, not 1 because 1 would match
              only the first byte of "ß"-->"ss"
            - "sß"~text~caselessPos("ss") --> 2, not 1 because 1 would match
              only the first byte of "ß"-->"ss"
            */
            posC = -absPosC  -- force negative to indicate not-aligned

            -- undo the last progression
            iSubtextPosB -= cTransformed~string~length
            xSubtextPosC -= 1
            leave
        end
    end

    -- calculate global positions from relative positions
    posB = startB - 1 + posB
    posC = sign(posC) * (startC - 1 + xSubtextPosC)
    absposC = abs(posC)

    if aligned then do
        nop -- return the negative value, needed for compareText
    end
    else do
        if posC < 0 then posC = "-"absposC"."posB
        else posC = "+"absposC"."posB
    end
    return posC
```

---

## Claude — Review

### Understanding the Architecture

What's been built here is a **coordinate-space translator** between two views of the same text:

- The **external** (untransformed) text, where positions are in grapheme units — this is what the user sees.
- The **internal** (transformed) text, where searching happens at the byte level after normalization, casefolding, mark stripping, etc.

The core challenge: a single external grapheme like `ß` may expand to `ss` internally (casefold expansion), or a ligature like `ﬄ` may expand to `ffl`. The reverse can happen too (contraction). So there's no simple arithmetic mapping between internal byte positions and external grapheme positions.

### Review of `ib2xc`

The dual-cursor walk is the right fundamental approach. The external cursor is advanced one grapheme at a time, transforming each grapheme individually, and accumulating the internal byte length until reaching or overshooting the target internal byte position. This is correct because the transformation is compositional at the grapheme level — transforming the whole string produces the same bytes as concatenating per-grapheme transformations.

#### Strengths

- The **aligned/not-aligned distinction** is essential and well-handled. The `ß` → `ss` example is a perfect illustration: if you search for `"s"` in `"ß"`, the match covers only half the transformed grapheme, so it shouldn't be reported as a match at grapheme position 1. The negative-position encoding conveys this cleanly.
- The **backup/restore mechanism** for `posCLastPlus1` is necessary — probing the end position without permanently advancing the cursor is required since on a mismatch the search retries from a nearby position.
- The **`+/-posC.posB` encoding** for the non-aligned debug mode is clever for diagnostics.

#### Issues and Suggestions

**1. Per-grapheme re-transformation in the inner loop is expensive**

Inside `ib2xc`, `c~transform(...)` is called for every grapheme on every call. Since `ib2xc` is called twice per match attempt (once for `posBFirst`, once for `posBLastPlus1`), and the outer loop in `posText` may try many positions, this is O(n × m) transformations in the worst case where n is the haystack length and m is the average scan distance per call.

For the C implementation, consider **precomputing a mapping array** during the initial transformation. When the search area is transformed, it is already processed grapheme by grapheme — at that point a parallel array recording `(externalGraphemeIndex, internalByteStart, internalByteEnd)` for each grapheme could be emitted. Then `ib2xc` becomes a binary search on `internalByteStart` instead of a linear walk with re-transformation.

This would change `ib2xc` from O(k) per call (where k is the distance walked) to O(log n), and eliminate the per-grapheme `transform` calls entirely.

**2. The forward-only cursor constraint is fragile**

The `previousPosB` check enforces monotonically increasing byte positions, which makes sense for the `pos` search pattern (scanning left to right). But:

- The `searchAreaNormalizedStartB += 1` fallback on mismatch advances by a single byte, which is correct for byte-level search but means the cursor also advances by at most one byte's worth. This is fine.
- However, the backup/restore is limited to a single level. If nested probing is ever needed (e.g., for a more complex matching strategy), this will need to become a stack or use a different mechanism.

For the C implementation, rather than maintaining stateful cursors, making `ib2xc` a **pure function** that takes a precomputed mapping and returns the result would be preferable. State management adds complexity and makes it harder to reason about correctness.

**3. The `posText` search strategy is byte-level `pos` on the transformed strings**

The line `searchAreaTransformed~string~pos(needleTextTransformed~string, ...)` is a plain byte-level substring search on the already-transformed text, then alignment is post-validated. This is correct and probably the best approach: let the native (fast) byte search do the heavy lifting, then validate grapheme alignment.

One subtlety: on mismatch, `searchAreaNormalizedStartB` advances by 1 (one byte). This is safe but pessimistic — advancing to the next internal grapheme boundary instead would be possible. In the C version with a precomputed mapping, this becomes trivial.

**4. The ligature guard is important**

```rexx
searchAreaNormalizedStartB = max(searchAreaNormalizedStartB,
    searchAreaTransformer~iSubtextPosB) -- for ligatures like "ﬄ"
```

This handles the case where a ligature like `ﬄ` expands to `ffl` — re-searching within the expansion of a ligature that's already been partially matched must not happen. This is subtle and correct.

**5. The `posText` alignment-checking logic needs rework (as noted in code)**

The code itself marks lines 199–236 as "to rework." The original design had `ib2xc` returning `.nil` for non-aligned, which was cleaner conceptually but less informative. The current negative-position encoding is better for `compareText` but makes the conditionals harder to read. For the C rewrite, separating the concerns is recommended: have `ib2xc` return a struct `{ graphemePos, bytePos, isAligned }` instead of overloading the sign of an integer. This eliminates all the `sign(posC)`, `abs(posC)` gymnastics.

### Impact on the Grapheme Indexer

To answer the direct question: yes, this does impact the indexer, but not its core data structure. What's needed in addition:

**A. The bit-vector indexer serves the external text** — it maps grapheme index → byte offset in the untransformed string. This is what `characterIndexB(startC)` already uses.

**B. For the internal (transformed) text, a separate but simpler structure is needed** — since the transformed text is typically ephemeral (created for one search operation), a lightweight mapping array `(internalByteOffset → externalGraphemeIndex, aligned?)` is more appropriate than a full bit-vector indexer.

**C. The precomputed mapping suggested in point 1 would live in the `RexxTextTransformer`**, not in the `GraphemeIndexer` itself. Think of it as:

- `GraphemeIndexer`: permanent, attached to a string, handles grapheme↔byte in a single text
- `TransformMapping`: ephemeral, attached to a search operation, handles internal↔external across a transformation

The `GraphemeIndexer` doesn't need a built-in rank query for this use case — the transformation mapping handles the cross-domain translation. The rank query would only be needed for byte→grapheme within a *single* untransformed string, which is a simpler problem.

### Summary

The `ib2xc` dual-cursor approach is functionally correct and handles the hard cases (expansion, contraction, non-aligned matches) properly. For the C rewrite, the main optimization opportunity is precomputing the internal↔external mapping during transformation so that `ib2xc` becomes a stateless binary search instead of a stateful linear walk. The grapheme indexer itself doesn't need modification — the cross-domain translation is a separate concern that belongs in the transformer layer.
