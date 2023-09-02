prompt off address directory
demo on

call loadUnicodeCharacterNames

.Unicode~memorizeConversions = .false
.Unicode~memorizeTransformations = .false


-- ===============================================================================
-- 2023 Aug 29

/*
Implementation of caselessContains, contains:
(forwards to caselessPos or pos, and returns .true if result <> 0)
(was already implemented, waiting for 'pos' implementation)
Examples:
*/
    "Père Noël Père Noël"~text~contains("oë")=                   -- .true
    "Père Noël Père Noël"~text~contains("oë", , 7)=              -- .false
    "Père Noël Père Noël"~text~contains("oë", , 8)=              -- .true
    "Père Noël Père Noël"~text~contains("oë", 8)=                -- .true
    "Père Noël Père Noël"~text~contains("oë", 8, 10)=            -- .false
    "Père Noël Père Noël"~text~contains("oë", 8, 11)=            -- .true
    "Père Noël Père Noël"~text~caselessContains("OË", 8, 11)=    -- .true

    "noël👩‍👨‍👩‍👧🎅"~text~contains("👧🎅")=                           -- UTF-8 not-ASCII 'noël👩‍👨‍👩‍👧🎅' The byte position 27 is not aligned with the character position 5.
    "noël👩‍👨‍👩‍👧🎅"~text~contains("👧🎅", aligned:.false)=           -- .true
    "noël👩‍👨‍👩‍👧🎅"~text~contains("👩‍👨‍👩‍👧🎅", aligned:.false)=  -- .true


-- ===============================================================================
-- 2023 Aug 28

/*
Add a named argument 'aligned' to caselessPos, pos:
- If aligned=.true (default) then raise an error if the byte position of the
  result is not aligned with the character index.
- If aligned=.false then return a number indexC.indexB when the result is not
  aligned (number such as the integer part is the character index and the
  decimal part is the byte index).
Example:
*/
    "noël👩‍👨‍👩‍👧🎅"~text~pos("👧🎅")=                           -- UTF-8 not-ASCII 'noël👩‍👨‍👩‍👧🎅' The byte position 27 is not aligned with the character position 5.
    "noël👩‍👨‍👩‍👧🎅"~text~pos("👧🎅", aligned:.false)=           -- 5.27
    "noël👩‍👨‍👩‍👧🎅"~text~pos("👩‍👨‍👩‍👧🎅", aligned:.false)=  -- 5 (no decimal part when the byte index is aligned)


/*
Comparison operators:
Take into account the default normalization managed by the .Unicode class
- NFC when strict
- NFKD when not strict
Example:
*/
    ("baﬄe"~text == "baffle"~text) =    -- false
    ("baﬄe"~text = "baffle"~text) =     -- true
/*
Reminder: the non-strict mode supports all the Unicode spaces, not just U+0032.
*/
    string1 = " Le\u{IDEOGRAPHIC SPACE}Pè\u{ZERO-WIDTH-SPACE}re\u{HYPHEN}Noël"~text~unescape
    string2 = "Le\u{OGHAM SPACE MARK}Père\u{EN DASH}No\u{ZERO-WIDTH-SPACE}ël "~text~unescape
    (string1 == string2) =              -- false
    (string1 = string2) =               -- true


-- ===============================================================================
-- 2023 Aug 26

t = "noël👩‍👨‍👩‍👧🎅"~text; t~c2g=    -- '6E 6F C3AB 6C F09F91A9E2808DF09F91A8E2808DF09F91A9E2808DF09F91A7 F09F8E85'
t = "noël👩‍👨‍👩‍👧🎅"~text; do indexB=1 to t~string~length + 2; indexC = t~indexer~characterIndexC(indexB); character = t~character(abs(indexC)); say "indexB" indexB~right(3) "--> indexC" indexC~right(4) "    " character~c2x; end


-- Implementation of caselessCompare, compare
-- ------------------------------------------
    "hello"~text~compare("hello")=                          -- 0
    "hello"~text~compare("helloo")=                         -- 6
    "hello"~text~compare("hellô")=                          -- 5
    "hello"~text~caselessCompare("hellô",stripMark:)=       -- 0
    "hellÔ"~text~caselessCompare("hellô")=                  -- 0
    "hellÔ"~text~caselessCompare("")=                       -- 1
    "hellÔ"~text~caselessCompare("", "h")=                  -- 2
    zwsp = "\u{ZERO WIDTH SPACE}"~text~unescape             -- ignorable
    ("he"zwsp"llo")~compare("hellô")=                       -- 3 (ok)
    ("he"zwsp"llo")~compare("hellô", stripIgnorable:)=      -- 6 (ok? not 5 because the ignorable character count as a character)


-- casefold 2 characters: "ß" becomes "ss"
    "Bundesstraße im Freiland"~text~caselessCompare("Bundesstraße")=        -- 14 (good)
    "Bundesstraße im Freiland"~text~caselessCompare("Bundesstraße", "_")=   -- 13 (good)
    "Bundesstraße im Freiland"~text~caselessCompare("bundesstrasse")=       -- 14 (good)
    "Bundesstrasse im Freiland"~text~caselessCompare("bundesstraße")=       -- 15 (good)
    "straßssßßssse"~text~compare("stra", "ß")=                              --  6 (good)
    "straßssßßssse"~text~caselessCompare("stra", "ß")=                      -- 13 (questionable? the last 's' match half of the pad 'ss')

/*
This test case is a little bit strange because:
- the case-folded character looks identical to the original character.
- the normalization and the casefold have the same effect.
*/
-- casefold 3 characters: "ΐ" 'U+0390' becomes "ΐ" 'U+03B9 U+0308 U+0301'
    iota_dt = "\u{GREEK SMALL LETTER IOTA WITH DIALYTIKA AND TONOS}"~text~unescape
    iota_dt~casefold~UnicodeCharacters==
    ("a" iota_dt "b")~compare("a")=                         -- 3
    ("a" iota_dt "b")~compare("a" iota_dt)=                 -- 5
    ("a" iota_dt~casefold "b")~compare("a" iota_dt)=                                -- 5 (yes! not 3 because the default NFC transforms iota_dt~casefold 'U+03B9 U+0308 U+0301' into 'U+0390')
    ("a" iota_dt~casefold "b")~compare("a" iota_dt, normalization: .Unicode~NFD)=   -- 5 (yes! not 3 because NFD transforms iota_dt 'U+0390' into 'U+03B9 U+0308 U+0301'
    ("a" iota_dt~casefold "b")~compare("a" iota_dt, normalization: 0)=              -- 3 because normalization deactivated
    ("a" iota_dt "b")~caselessCompare("a")=                 -- 3
    ("a" iota_dt "b")~caselessCompare("a" iota_dt)=         -- 5
    ("a" iota_dt "b")~caselessCompare("a ", iota_dt)=       -- 4


-- Implementation of caselessEndsWith, endsWith
-- --------------------------------------------
    "hello"~text~endsWith("")=                              -- false
    "hello"~text~endsWith("o")=                             -- true
    "hello"~text~endsWith("ô")=                             -- false
    "hello"~text~endsWith("ô", stripMark:)=                 -- true
    "hello"~text~endsWith("O")=                             -- false
    "hello"~text~caselessEndsWith("O")=                     -- true


-- Rework implementation of caselessMatchChar, matchChar
-- -----------------------------------------------------
    "BAFFLE"~text~caselessMatchChar(3, "ﬄ")=               -- 1      "ﬄ" becomes "ffl" (3 graphemes), there is a match on "f" at 3
    "BAFFLE"~text~caselessMatchChar(5, "ﬄ")=               -- 1      "ﬄ" becomes "ffl" (3 graphemes), there is a match on "l" at 5
    "baffle"~text~caselessMatchChar(5, "L")=                -- 1      there is a match on "l" at 5 (forward to string)
    "baﬄe"~text~caselessMatchChar(3, "ﬄ")=                -- 1      "ﬄ" at 3 (1 grapheme) becomes "ffl" (3 graphemes), there is a match on "l"
    "baﬄe"~text~caselessMatchChar(3, "F")=                 -- 1      "ﬄ" at 3 (1 grapheme) becomes "ffl" (3 graphemes), there is a match on "f"
    "baﬄe"~text~caselessMatchChar(3, "L")=                 -- 1      "ﬄ" at 3 (1 grapheme) becomes "ffl" (3 graphemes), there is a match on "l"
    "baﬄe"~text~caselessMatchChar(4, "E")=                 -- 1      the grapheme at 4 is "e", not "f". There is a match with "e"


-- Rework implementation of caselessCompareTo, compareTo
-- -----------------------------------------------------
    "Père Noël"~text~nfc~compareTo("Père Noël"~text~nfc)=                       -- 0 (equal)
    "Père Noël"~text~nfc~compareTo("Père Noël"~text~nfd)=                       -- 0 (equal)
    "Père Noël"~text~nfd~compareTo("Père Noël"~text~nfc)=                       -- 0 (equal)
    "Père Noël"~text~nfd~compareTo("Père Noël"~text~nfd)=                       -- 0 (equal)
    ---
    "Pere Noël"~text~nfc~compareTo("Père Noel"~text~nfc, stripMark:)=           -- 0 (equal)
    "Pere Noël"~text~nfc~compareTo("Père Noel"~text~nfd, stripMark:)=           -- 0 (equal)
    "Pere Noël"~text~nfd~compareTo("Père Noel"~text~nfc, stripMark:)=           -- 0 (equal)
    "Pere Noël"~text~nfd~compareTo("Père Noel"~text~nfd, stripMark:)=           -- 0 (equal)
    ---
    "1st Père Noël"~text~nfc~compareTo("2nd Père Noël"~text~nfc)=               -- -1 (lesser)
    "1st Père Noël"~text~nfc~compareTo("2nd Père Noël"~text~nfd)=               -- -1 (lesser)
    "1st Père Noël"~text~nfd~compareTo("2nd Père Noël"~text~nfc)=               -- -1 (lesser)
    "1st Père Noël"~text~nfd~compareTo("2nd Père Noël"~text~nfd)=               -- -1 (lesser)
    ---
    "Père Noël 2nd"~text~nfc~compareTo("Père Noël 1st"~text~nfc)=               -- 1 (greater)
    "Père Noël 2nd"~text~nfc~compareTo("Père Noël 1st"~text~nfd)=               -- 1 (greater)
    "Père Noël 2nd"~text~nfd~compareTo("Père Noël 1st"~text~nfc)=               -- 1 (greater)
    "Père Noël 2nd"~text~nfd~compareTo("Père Noël 1st"~text~nfd)=               -- 1 (greater)
    ---
    "Pere Noël"~text~nfc~compareTo("Père Noel"~text~nfc, 3, 4)=                 -- 0 (equal)
    "Pere Noël"~text~nfc~compareTo("Père Noel"~text~nfd, 3, 4)=                 -- 0 (equal)
    "Pere Noël"~text~nfd~compareTo("Père Noel"~text~nfc, 3, 4)=                 -- 0 (equal)
    "Pere Noël"~text~nfd~compareTo("Père Noel"~text~nfd, 3, 4)=                 -- 0 (equal)
    ---
    "PÈRE NOËL"~text~nfc~compareTo("Père Noël"~text~nfc)=                       -- -1 (lesser)
    "PÈRE NOËL"~text~nfc~compareTo("Père Noël"~text~nfd)=                       -- -1 (lesser)
    "PÈRE NOËL"~text~nfd~compareTo("Père Noël"~text~nfc)=                       -- -1 (lesser)
    "PÈRE NOËL"~text~nfd~compareTo("Père Noël"~text~nfd)=                       -- -1 (lesser)
    ---
    "PÈRE NOËL"~text~nfc~caselessCompareTo("Père Noël"~text~nfc)=               -- 0 (equal)
    "PÈRE NOËL"~text~nfc~caselessCompareTo("Père Noël"~text~nfd)=               -- 0 (equal)
    "PÈRE NOËL"~text~nfd~caselessCompareTo("Père Noël"~text~nfc)=               -- 0 (equal)
    "PÈRE NOËL"~text~nfd~caselessCompareTo("Père Noël"~text~nfd)=               -- 0 (equal)
    ---
    "PERE NOËL"~text~nfc~caselessCompareTo("Père Noel"~text~nfc, 3, 4)=         -- 0 (equal)
    "PERE NOËL"~text~nfc~caselessCompareTo("Père Noel"~text~nfd, 3, 4)=         -- 0 (equal)
    "PERE NOËL"~text~nfd~caselessCompareTo("Père Noel"~text~nfc, 3, 4)=         -- 0 (equal)
    "PERE NOËL"~text~nfd~caselessCompareTo("Père Noel"~text~nfd, 3, 4)=         -- 0 (equal)


-- Implementation of caselessPos, pos
-- ----------------------------------
    --       P  è       r  e  _  N  o  ë       l
    --       1  2       3  4  5  6  7  8       9
    -- NFC  '50 C3A8    72 65 20 4E 6F C3AB    6C'
    --       1  2 3     4  5  6  7  8  9 10    11
    -- NFD  '50 65 CC80 72 65 20 4E 6F 65 CC88 6C'
    --       1  2  3 4  5  6  7  8  9  19 1112 13
                                                            --      self needle
    "Père Noël Père Noël"~text~pos("l")=                    -- 9    NFC, NFC
    "Père Noël Père Noël"     ~pos("l")=                    -- 11   NFC, NFC

    "Père Noël Père Noël"~text~pos("l", , 8)=               -- 0    NFC, NFC
    "Père Noël Père Noël"     ~pos("l", , 10)=              -- 0    NFC, NFC

    "Père Noël Père Noël"~text~pos("l", , 9)=               -- 9    NFC, NFC
    "Père Noël Père Noël"     ~pos("l", , 11)=              -- 11   NFC, NFC

    "Père Noël Père Noël"~text~pos("l", 10)=                -- 19   NFC, NFC
    "Père Noël Père Noël"     ~pos("l", 12)=                -- 23   NFC, NFC

    "Père Noël Père Noël"~text~pos("l", 10, 9)=             -- 0    NFC, NFC
    "Père Noël Père Noël"     ~pos("l", 12, 11)=            -- 0    NFC, NFC

    "Père Noël Père Noël"~text~pos("l", 10, 10)=            -- 19   NFC, NFC
    "Père Noël Père Noël"     ~pos("l", 12, 12)=            -- 23   NFC, NFC

    ---

    "Père Noël Père Noël"~text~pos("l")=                    -- 9    NFD, NFC
    "Père Noël Père Noël"     ~pos("l")=                    -- 13   NFD, NFC

    "Père Noël Père Noël"~text~pos("l", , 8)=               -- 0    NFD, NFC
    "Père Noël Père Noël"     ~pos("l", , 12)=              -- 0    NFD, NFC

    "Père Noël Père Noël"~text~pos("l", , 9)=               -- 9    NFD, NFC
    "Père Noël Père Noël"     ~pos("l", , 13)=              -- 13   NFD, NFC

    "Père Noël Père Noël"~text~pos("l", 10)=                -- 19   NFD, NFC
    "Père Noël Père Noël"     ~pos("l", 14)=                -- 27   NFD, NFC

    "Père Noël Père Noël"~text~pos("l", 10, 9)=             -- 0    NFD, NFC
    "Père Noël Père Noël"     ~pos("l", 14, 13)=            -- 0    NFD, NFC

    "Père Noël Père Noël"~text~pos("l", 10, 10)=            -- 19   NFD, NFC
    "Père Noël Père Noël"     ~pos("l", 14, 14)=            -- 27   NFD, NFC

    ---

    "Père Noël Père Noël"~text~pos("oë")=                   -- 7    NFC, NFC
    "Père Noël Père Noël"     ~pos("oë")=                   -- 8    NFC, NFC

    "Père Noël Père Noël"~text~pos("oë", , 7)=              -- 0    NFC, NFC
    "Père Noël Père Noël"     ~pos("oë", , 9)=              -- 0    NFC, NFC

    "Père Noël Père Noël"~text~pos("oë", , 8)=              -- 7    NFC, NFC
    "Père Noël Père Noël"     ~pos("oë", , 10)=             -- 8    NFC, NFC

    "Père Noël Père Noël"~text~pos("oë", 8)=                -- 17   NFC, NFC
    "Père Noël Père Noël"     ~pos("oë", 9)=                -- 20   NFC, NFC

    "Père Noël Père Noël"~text~pos("oë", 8, 10)=            -- 0    NFC, NFC
    "Père Noël Père Noël"     ~pos("oë", 9, 13)=            -- 0    NFC, NFC

    "Père Noël Père Noël"~text~pos("oë", 8, 11)=            -- 17   NFC, NFC
    "Père Noël Père Noël"     ~pos("oë", 9, 14)=            -- 20   NFC, NFC

    ---

    "Père Noël Père Noël"~text~pos("oë")=                   -- 7    NFD, NFC
    "Père Noël Père Noël"     ~pos("oë")=                   -- 0    NFD, NFC    always 0, no need to test all the combinations

    "Père Noël Père Noël"~text~pos("oë", , 7)=              -- 0    NFD, NFC

    "Père Noël Père Noël"~text~pos("oë", , 8)=              -- 7    NFD, NFC

    "Père Noël Père Noël"~text~pos("oë", 8)=                -- 17   NFD, NFC

    "Père Noël Père Noël"~text~pos("oë", 8, 10)=            -- 0    NFD, NFC

    "Père Noël Père Noël"~text~pos("oë", 8, 11)=            -- 17   NFD, NFC

    ---

    "Père Noël Père Noël"~text~pos("oë")=                   -- 7    NFC, NFD
    "Père Noël Père Noël"     ~pos("oë")=                   -- 0    NFC, NFD   always 0, no need to test all the combinations

    "Père Noël Père Noël"~text~pos("oë", , 7)=              -- 0    NFC, NFD

    "Père Noël Père Noël"~text~pos("oë", , 8)=              -- 7    NFC, NFD

    "Père Noël Père Noël"~text~pos("oë", 8)=                -- 17   NFC, NFD

    "Père Noël Père Noël"~text~pos("oë", 8, 10)=            -- 0    NFC, NFD

    "Père Noël Père Noël"~text~pos("oë", 8, 11)=            -- 17   NFC, NFD

    ---

    "Père Noël Père Noël"~text~pos("oë")=                   -- 7    NFD, NFD
    "Père Noël Père Noël"     ~pos("oë")=                   -- 9    NFD, NFD

    "Père Noël Père Noël"~text~pos("oë", , 7)=              -- 0    NFD, NFD
    "Père Noël Père Noël"     ~pos("oë", , 11)=             -- 0    NFD, NFD

    "Père Noël Père Noël"~text~pos("oë", , 8)=              -- 7    NFD, NFD
    "Père Noël Père Noël"     ~pos("oë", , 12)=             -- 9    NFD, NFD

    "Père Noël Père Noël"~text~pos("oë", 8)=                -- 17   NFD, NFD
    "Père Noël Père Noël"     ~pos("oë", 10)=               -- 23   NFD, NFD

    "Père Noël Père Noël"~text~pos("oë", 8, 10)=            -- 0    NFD, NFD
    "Père Noël Père Noël"     ~pos("oë", 10, 16)=           -- 0    NFD, NFD

    "Père Noël Père Noël"~text~pos("oë", 8, 11)=            -- 17   NFD, NFD
    "Père Noël Père Noël"     ~pos("oë", 10, 17)=           -- 23   NFD, NFD

    ---

    "Père Noël Père Noël"~text~pos("oe")=                   -- 0    NFC, NFC    always 0, no need to test all the combinations
    "Père Noël Père Noël"~text~pos("oe", stripMark:)=       -- 7    NFC, NFC

    "Père Noël Père Noël"~text~pos("oe", , 7, stripMark:)=  -- 0    NFC, NFC

    "Père Noël Père Noël"~text~pos("oe", , 8, stripMark:)=  -- 7    NFC, NFC

    "Père Noël Père Noël"~text~pos("oe", 8, stripMark:)=    -- 17   NFC, NFC

    "Père Noël Père Noël"~text~pos("oe", 8, 10, stripMark:)=-- 0    NFC, NFC

    "Père Noël Père Noël"~text~pos("oe", 8, 11, stripMark:)=-- 17   NFC, NFC

    ---
    -- caseless tests not in the diary:
    ---

    "Père Noël Père Noël"~text~caselessPos("L")=                    -- 9    NFC, NFC
    "Père Noël Père Noël"     ~caselessPos("L")=                    -- 11   NFC, NFC

    "Père Noël Père Noël"~text~caselessPos("L", , 8)=               -- 0    NFC, NFC
    "Père Noël Père Noël"     ~caselessPos("L", , 10)=              -- 0    NFC, NFC

    "Père Noël Père Noël"~text~caselessPos("L", , 9)=               -- 9    NFC, NFC
    "Père Noël Père Noël"     ~caselessPos("L", , 11)=              -- 11   NFC, NFC

    "Père Noël Père Noël"~text~caselessPos("L", 10)=                -- 19   NFC, NFC
    "Père Noël Père Noël"     ~caselessPos("L", 12)=                -- 23   NFC, NFC

    "Père Noël Père Noël"~text~caselessPos("L", 10, 9)=             -- 0    NFC, NFC
    "Père Noël Père Noël"     ~caselessPos("L", 12, 11)=            -- 0    NFC, NFC

    "Père Noël Père Noël"~text~caselessPos("L", 10, 10)=            -- 19   NFC, NFC
    "Père Noël Père Noël"     ~caselessPos("L", 12, 12)=            -- 23   NFC, NFC

    ---

    "Père Noël Père Noël"~text~caselessPos("L")=                    -- 9    NFD, NFC
    "Père Noël Père Noël"     ~caselessPos("L")=                    -- 13   NFD, NFC

    "Père Noël Père Noël"~text~caselessPos("L", , 8)=               -- 0    NFD, NFC
    "Père Noël Père Noël"     ~caselessPos("L", , 12)=              -- 0    NFD, NFC

    "Père Noël Père Noël"~text~caselessPos("L", , 9)=               -- 9    NFD, NFC
    "Père Noël Père Noël"     ~caselessPos("L", , 13)=              -- 13   NFD, NFC

    "Père Noël Père Noël"~text~caselessPos("L", 10)=                -- 19   NFD, NFC
    "Père Noël Père Noël"     ~caselessPos("L", 14)=                -- 27   NFD, NFC

    "Père Noël Père Noël"~text~caselessPos("L", 10, 9)=             -- 0    NFD, NFC
    "Père Noël Père Noël"     ~caselessPos("L", 14, 13)=            -- 0    NFD, NFC

    "Père Noël Père Noël"~text~caselessPos("L", 10, 10)=            -- 19   NFD, NFC
    "Père Noël Père Noël"     ~caselessPos("L", 14, 14)=            -- 27   NFD, NFC

    ---

    "Père Noël Père Noël"~text~caselessPos("OË")=                   -- 7    NFC, NFC
    "Père Noël Père Noël"     ~caselessPos("OË")=                   -- 0    NFC, NFC    yes, 0, not 8 because "OË"~lower=='oË'

    "Père Noël Père Noël"~text~caselessPos("OË", , 7)=              -- 0    NFC, NFC
    "Père Noël Père Noël"     ~caselessPos("OË", , 9)=              -- 0    NFC, NFC

    "Père Noël Père Noël"~text~caselessPos("OË", , 8)=              -- 7    NFC, NFC
    "Père Noël Père Noël"     ~caselessPos("OË", , 10)=             -- 0    NFC, NFC    yes, 0, not 8 because "OË"~lower=='oË'

    "Père Noël Père Noël"~text~caselessPos("OË", 8)=                -- 17   NFC, NFC
    "Père Noël Père Noël"     ~caselessPos("OË", 9)=                -- 0    NFC, NFC    yes, 0, not 20 because "OË"~lower=='oË'

    "Père Noël Père Noël"~text~caselessPos("OË", 8, 10)=            -- 0    NFC, NFC
    "Père Noël Père Noël"     ~caselessPos("OË", 9, 13)=            -- 0    NFC, NFC

    "Père Noël Père Noël"~text~caselessPos("OË", 8, 11)=            -- 17   NFC, NFC
    "Père Noël Père Noël"     ~caselessPos("OË", 9, 14)=            -- 0    NFC, NFC    yes, 0, not 20 because "OË"~lower=='oË'

    ---

    "Père Noël Père Noël"~text~caselessPos("OË")=                   -- 7    NFD, NFC
    "Père Noël Père Noël"     ~caselessPos("OË")=                   -- 0    NFD, NFC    always 0, no need to test all the combinations

    "Père Noël Père Noël"~text~caselessPos("OË", , 7)=              -- 0    NFD, NFC

    "Père Noël Père Noël"~text~caselessPos("OË", , 8)=              -- 7    NFD, NFC

    "Père Noël Père Noël"~text~caselessPos("OË", 8)=                -- 17   NFD, NFC

    "Père Noël Père Noël"~text~caselessPos("OË", 8, 10)=            -- 0    NFD, NFC

    "Père Noël Père Noël"~text~caselessPos("OË", 8, 11)=            -- 17   NFD, NFC

    ---

    "Père Noël Père Noël"~text~caselessPos("OË")=                   -- 7    NFC, NFD
    "Père Noël Père Noël"     ~caselessPos("OË")=                   -- 0    NFC, NFD   always 0, no need to test all the combinations

    "Père Noël Père Noël"~text~caselessPos("OË", , 7)=              -- 0    NFC, NFD

    "Père Noël Père Noël"~text~caselessPos("OË", , 8)=              -- 7    NFC, NFD

    "Père Noël Père Noël"~text~caselessPos("OË", 8)=                -- 17   NFC, NFD

    "Père Noël Père Noël"~text~caselessPos("OË", 8, 10)=            -- 0    NFC, NFD

    "Père Noël Père Noël"~text~caselessPos("OË", 8, 11)=            -- 17   NFC, NFD

    ---

    "Père Noël Père Noël"~text~caselessPos("OË")=                   -- 7    NFD, NFD
    "Père Noël Père Noël"     ~caselessPos("OË")=                   -- 9    NFD, NFD   yes, 9 (it works...) because the NFD representation isolate the accent: "oë"~c2x=='6F65CC88',  "OË"~lower~c2x=='6F65CC88'

    "Père Noël Père Noël"~text~caselessPos("OË", , 7)=              -- 0    NFD, NFD
    "Père Noël Père Noël"     ~caselessPos("OË", , 11)=             -- 0    NFD, NFD

    "Père Noël Père Noël"~text~caselessPos("OË", , 8)=              -- 7    NFD, NFD
    "Père Noël Père Noël"     ~caselessPos("OË", , 12)=             -- 9    NFD, NFD   yes, 9 (it works thanks to the NFD), see previous comment

    "Père Noël Père Noël"~text~caselessPos("OË", 8)=                -- 17   NFD, NFD
    "Père Noël Père Noël"     ~caselessPos("OË", 10)=               -- 23   NFD, NFD   yes, 23 (it works thanks to the NFD), see previous comment

    "Père Noël Père Noël"~text~caselessPos("OË", 8, 10)=            -- 0    NFD, NFD
    "Père Noël Père Noël"     ~caselessPos("OË", 10, 16)=           -- 0    NFD, NFD

    "Père Noël Père Noël"~text~caselessPos("OË", 8, 11)=            -- 17   NFD, NFD
    "Père Noël Père Noël"     ~caselessPos("OË", 10, 17)=           -- 23   NFD, NFD   yes, 23 (it works thanks to the NFD), see previous comment

    ---

    "Père Noël Père Noël"~text~caselessPos("OE")=                   -- 0    NFC, NFC    always 0, no need to test all the combinations
    "Père Noël Père Noël"~text~caselessPos("OE", stripMark:)=       -- 7    NFC, NFC

    "Père Noël Père Noël"~text~caselessPos("OE", , 7, stripMark:)=  -- 0    NFC, NFC

    "Père Noël Père Noël"~text~caselessPos("OE", , 8, stripMark:)=  -- 7    NFC, NFC

    "Père Noël Père Noël"~text~caselessPos("OE", 8, stripMark:)=    -- 17   NFC, NFC

    "Père Noël Père Noël"~text~caselessPos("OE", 8, 10, stripMark:)=-- 0    NFC, NFC

    "Père Noël Père Noël"~text~caselessPos("OE", 8, 11, stripMark:)=-- 17   NFC, NFC


-- ===============================================================================
-- 2023 Aug 07

-- Add conversion from a Unicode encoding to a Byte encoding.
"Père Noël"~text~transcodeTo("cp437")~c2x=                                  -- '50 8A 72 65 20 4E 6F 89 6C'
'50 8A 72 65 20 4E 6F 89 6C'x~text("cp437")~utf8~c2x=                       -- '50 C3A8 72 65 20 4E 6F C3AB 6C'
'50 8A 72 65 20 4E 6F 89 6C'x~text("cp437")~transcodeTo("utf8")~c2x=        -- '50 C3A8 72 65 20 4E 6F C3AB 6C'

text = "Père Noël 🎅 10€"~text; do encoding over .Byte_Encoding~subclasses~~append(.Byte_Encoding); say encoding~name~left(13)":" text~transcodeTo(encoding, replace:"FF"x)~c2x; end


-- ===============================================================================
-- 2023 Aug 04


--- Following expressions return the same result correctly tagged 'ISO-8859-1'
b = .MutableBuffer~new; "Pere"~text("windows-1252")~append(" "~text("windows-1252"), :b)~appendEncoded("Noël"~text("iso-8859-1"), :b)=; result~description=
b = .MutableBuffer~new; "Pere"~text("windows-1252")~appendEncoded(" "~text("windows-1252"), :b)~appendEncoded("Noël"~text("iso-8859-1"), :b)=; result~description=
b = .MutableBuffer~new; b~appendEncoded("Pere"~text("windows-1252"), " "~text("windows-1252"), "Noël"~text("iso-8859-1"))=; result~description=

-- Following expressions (not using 'appendEncoded') return the same result as above, but wrongly tagged 'windows-1252' or 'UTF-8'
b = .MutableBuffer~new; "Pere"~text("windows-1252")~append(" "~text("windows-1252"), :b)~append("Noël"~text("iso-8859-1"), :b)=; result~description=
b = .MutableBuffer~new; b~append("Pere"~text("windows-1252"), " "~text("windows-1252"), "Noël"~text("iso-8859-1"))=; result~description=


-- ===============================================================================
-- 2023 Jun 28

-- Bitkey is now 2 bytes (4 hex digits) always.

-- For debug, give temporarily access to the flags stored on an indexer.
"Père Noël"~text~nfc(casefold:, stripMark:)~indexer~flags=


-- ===============================================================================
-- 2023 May 31

-- Add support for functional methods to RexxText.

-- Example inspired by https://elixir-lang.org/
-- Frequency of each character, ignoring the accents:
"Notre père Noël 🎅"~text~transform(stripMark:)~reduce(by: "characters", initial: .stem~new~~put(0)){accu[item~string] += 1}=

-- Add support for generator methods to RexxText.

g="Noël 🎅"~text~generateC
g~()=       -- T'N'
g~()=       -- T'o'
g~()=       -- T'ë'
g~()=       -- T'l'
g~()=       -- T' '
g~()=       -- T'🎅'
g~()=       -- [no result]


-- ===============================================================================
-- 2023 May 29

-- For convenience, additional way to search a character:
-- with a routine
.UnicodeCharacter("bed")=           -- ( "🛏"   U+1F6CF So 1 "BED" )
.UnicodeCharacter("bed", h:)=       -- ( "௭"   U+0BED Nd 1 "TAMIL DIGIT SEVEN" )
-- with the operator []
.UnicodeCharacter["bed"]=           -- ( "🛏"   U+1F6CF So 1 "BED" )
.UnicodeCharacter["bed", h:]=       -- ( "௭"   U+0BED Nd 1 "TAMIL DIGIT SEVEN" )

-- This comes in complement of:
.Unicode["bed", h:]=                -- ( "௭"   U+0BED Nd 1 "TAMIL DIGIT SEVEN" )
.Unicode~character("bed", h:)=      -- ( "௭"   U+0BED Nd 1 "TAMIL DIGIT SEVEN" )


-- New method UnicodeCharacter~properties at class level: return a list of property names.
.UnicodeCharacter~properties=


-- ===============================================================================
-- 2023 May 24

-- For convenience, it's now possible to search directly a character if it's made of one codepoint only:
.Unicode~character("a")=    -- ( "a"   U+0061 Ll 1 "LATIN SMALL LETTER A" )
.Unicode~character("à")=    -- ( "à"   U+00E0 Ll 1 "LATIN SMALL LETTER A WITH GRAVE" )
.Unicode~character("à")=    -- Error: The character 'à' is made of several codepoints: U+0061 U+0300

-- For the last example, you can get an array of characters:
"à"~text~UnicodeCharacters==


-- New method UnicodeCharacter~properties at instance level: Return a directory of properties.
.Unicode~character("U+000D")~properties=


-- ===============================================================================
-- 2023 March 20

-- Rework implementation of caselessMatch to support correctly
"Bundesstraße im Freiland"~text~caselessMatch(14, "im")     -- .true


-- ===============================================================================
-- 2023 March 08

-- Implementation of caselessMatchChar, matchChar
"Noëlle"~text~matchChar(2, "aeiouy")=                       -- 1
"Noëlle"~text~matchChar(3, "aeiouy")=                       -- 0
"Noëlle"~text~matchChar(3, "aeëiouy")=                      -- 1    include the accents in the list of accepted characters
"Noëlle"~text~matchChar(3, "aeiouy", stripMark:)=           -- 1    or remove the accents from the tested string
"Noëlle"~text~matchChar(6, "aeiouy")=                       -- 1

"Bundesschnellstraße"~text~matchChar(14, "s")=              -- 1
"Bundesschnellstraße"~text~matchChar(18, "s")=              -- 0
"Bundesschnellstraße"~text~matchChar(18, "sß")=             -- 1
"Bundesschnellstraße"~text~caselessMatchChar(18, "s")=      -- 1    "ß" becomes "ss" which is 2 graphemes. The first grapheme at 18 matches "s"
"Bundesschnellstraße"~text~caselessMatchChar(19, "s")=      -- 0    "ß" becomes "ss" which is 2 graphemes. The grapheme at 19 is "e", not the second "s"
"Bundesschnellstraße"~text~caselessMatchChar(19, "e")=      -- 1    "ß" becomes "ss" which is 2 graphemes. The grapheme at 19 is "e", not the second "s"

-- The ligature disappears in NFK[CD] but not in NF[CD]
"baﬄe"~text~NFKC=                                            -- T'baffle'
"baﬄe"~text~NFKD=                                            -- T'baffle'
"baﬄe"~text~matchChar(3, "f")=                               -- 0     "ﬄ" is ONE grapheme because NFC
"baﬄe"~text~matchChar(3, "ﬄ")=                              -- 1     "ﬄ" is ONE grapheme because NFC
"baﬄe"~text~matchChar(3, "ﬄ", normalization:.Unicode~NFKD)= -- 1     "ﬄ" becomes "ffl" (3 graphemes). There is a match because the first grapheme is "f"
"baﬄe"~text~matchChar(3, "f", normalization:.Unicode~NFKD)=  -- 1     "ﬄ" becomes "ffl" (3 graphemes). There is a match because the first grapheme is "f"
"baﬄe"~text~matchChar(4, "f", normalization:.Unicode~NFKD)=  -- 0     "ﬄ" becomes "ffl" (3 graphemes). The grapheme at 4 is "e", not the second "f"
"baﬄe"~text~matchChar(4, "e", normalization:.Unicode~NFKD)=  -- 1     "ﬄ" becomes "ffl" (3 graphemes). The grapheme at 4 is "e", not the second "f"

-- The ligature disappears when casefolded
"baﬄe"~text~casefold=                                        -- T'baffle'
"BAFFLE"~text~caselessMatchChar(3, "ﬄ")=                     -- 1      "ﬄ" becomes "ffl" (3 graphemes), there is a match on "f" at 3
"BAFFLE"~text~caselessMatchChar(5, "ﬄ")=                     -- 1      "ﬄ" becomes "ffl" (3 graphemes), there is a match on "l" at 5
"BAFFLE"~text~caselessMatchChar(5, "L")=                      -- 1      there is a match on "l" at 5 (forward to String)


-- Implementation of caselessEquals, equals
"ŒUF"~text~caselessEquals("œuf")=           -- 1
"œuf"~text~caselessEquals("ŒUF")=           -- 1
"Straße"~text~caselessEquals("strasse")=    -- 1
"strasse"~text~caselessEquals("Straße")=    -- 1


-- Some ligatures are not decomposed by NFKC.
"ŒUF"~text~caselessEquals("oeuf")=                                  -- 0
"ŒUF"~text~caselessEquals("oeuf", normalization:.Unicode~NFKC)=     -- 0


-- ===============================================================================
-- 2022 November 20

/*
For consistency, all the conversion methods accept the named argument 'strict',
even if it's not needed for the unicode encodings.
Previously, was supported only for the byte encodings.
The default value of 'strict' is now .false.

The conversion methods accept the named argument 'memorize(3)'.
Its default value is given by .unicode~memorizeConversions which is .false by default.
Example:
    s = "hello"
    t = s~text
    utf16 = t~utf16(mem:)
    utf32 = t~utf32(mem:)
    t~utf16~"==":.object(utf16)=         -- 1
    t~utf32~"==":.object(utf32)=         -- 1
*/

/*
CP1252 to UTF-8, UTF-16, UTF-32
"Un œuf de chez MaPoule™ coûte ±0.40€"
*/
str_cp1252 = "Un " || "9C"x || "uf de chez MaPoule" || "99"x || " co" || "FB"x || "te " || "B1"x || "0.40" || "80"x
txt_cp1252 = str_cp1252~text("cp1252")
utf8  = txt_cp1252~utf8(mem:)
utf16 = txt_cp1252~utf16(mem:)
utf32 = txt_cp1252~utf32(mem:)
txt_cp1252~utf8 ~"==":.object(utf8) =         -- 1
txt_cp1252~utf16~"==":.object(utf16)=         -- 1
txt_cp1252~utf32~"==":.object(utf32)=         -- 1

/*
When an optional buffer is passed, must check that its encoding is compatible.
Done for the conversion methods.
Example:
*/
b = .mutablebuffer~new      -- No encoding yet
"hello"~text~utf16(:b)      -- now the buffer's encoding is UTF-16
"bye"~text~utf8(:b)         -- Encoding: cannot append UTF-8 to UTF-16BE '[00]h[00]e[00]l[00]l[00]o'.


-- ===============================================================================
-- 2022 November 08

/*
Additional arguments are supported by NFC, NFD, NFKC, NFKD, Casefold:
    lump
        Lumps certain different codepoints together.
        All the concerned characters become the same character, but still remain distinct characters.
        E.g. HYPHEN U+2010 and MINUS U+2212 to ASCII "-"
             all space characters (general category Zs) to U+0020
    stripIgnorable
        Strips the characters whose property Default_Ignorable_Code_Point = true
        such as SOFT-HYPHEN or ZERO-WIDTH-SPACE
    stripCC
        Strips and/or converts control characters:
        characters 00-1F and 7F-9F, except 09 which is replaced by 20.
    stripMark
        Strips all character markings:
        characters whose category is Mc Me Mn (i.e. accents)
            Mc Spacing Mark
            Me Enclosing Mark
            Mn Nonspacing Mark
        This option works only with normalization.
    stripNA
        Strips the characters whose category is Cn Unassigned
        Note that the value gc=Cn does not actually occur in UnicodeData.txt,
        because that data file does not list unassigned code points.

Remark: the normalization NFKC_Casefold (short alias NFKC_CF) is done with
    ~NFKC(Casefold: .true, stripIgnorable: .true)
*/

/*
Two RexxText values are considered equal if their extended grapheme clusters are canonically equivalent.
This is the definition of Swift.
Q&A https://lists.isocpp.org/sg16/2018/08/0121.php
TODO: confirm that it's NFC, and only that.
The definition of canonical equivalence by the Unicode standard seems not limited to NFC.
https://unicode.org/notes/tn5/

The strict comparison operators now use the NFC normalization.
After normalization, they delegate to the String's strict comparison operators.

The non-strict comparison operators now use the NFC normalization plus
    stripIgnorable:.true
    lump:.true
After normalization + transformations, they delegate to the String's non-strict comparison operators.
Thanks to the lump transformation, all the Unicode spaces are supported.

Examples:
*/

textNFC = "Noël"~text~NFC
textNFC~UnicodeCharacters==
textNFD="Noël"~text~NFD
textNFD~UnicodeCharacters==
(textNFC == textNFD)=                                               -- 1
(textNFC = textNFD)=                                                -- 1
(" "textNFC == textNFD" ")=                                         -- 0 because strict
(" "textNFC = textNFD" ")=                                          -- 1
(" "textNFC = (textNFD"\u{NBSP}")~unescape)=                        -- 1
(" "textNFC = (textNFD"\u{ZWSP}")~unescape)=                        -- 1
("-"textNFC = ("\u{OBLIQUE HYPHEN}"textNFD"\u{ZWSP}")~unescape)=    -- 1

"pere noel"~text~caselessCompareTo("Père Noël")=                    -- -1 (lesser)
"pere noel"~text~caselessCompareTo("Père Noël", stripMark:.true)=   --  0 (equal because the accents are ignored)

-- Add support for ISO-8859-1 encoding (alias Latin1).
-- Example:
-- all the supported characters: ranges 20-7E and A0-FF
text = xrange("20"x, "7E"x, "A0"x, "FF"x)~text("ISO-8859-1")

-- The ? are just ISO-8859-1 encoded characters that can't be displayed as-is in a console UTF-8 (copy-paste of the console output)
-- After conversion to UTF-8, all is good.
text=       -- T' !"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~???????????????????????????????????????????????????????????????????????????????????????????????[FF]'
text~utf8=  -- T' !"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~ ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ'

-- ranges 00-1F and 7F-9F are undefined
-- an error is triggered even with the option strict: .false, because there is no fallback mapping
text = xrange("20"x, "FF"x)~text("ISO-8859-1")
text~utf8(strict: .false)=                      -- Error ISO-8859-1 encoding: cannot convert ISO-8859-1 not-ASCII character 127 (7F) at byte-position 96 to UTF-8.


-- ===============================================================================
-- 2022 November 06

/*
Refactoring
    Prefix the native methods by the library name (utf8proc_, ziglyph_ or icu4x_).
    That will make more easy the comparison of similar services.

    Remove the native methods 'NFC', 'NFD', 'NFKC', 'NFKD' and 'NFKC_Casefold':
    all replaced by 'utf8proc_transform'.

    ~Casefold is now limited to case fold.
    Previously, NKFC + case fold was applied (because the method NFKC_Casefold of utf8proc was called).

    NFC, NFD, NFKC and NFKD now supports the named argument 'casefold' (default = .false).

Examples
*/
"Père Noël ß ㎒"~text~casefold=                      -- T'père noël ss ㎒'
"Père Noël ß ㎒"~text~NFKC=                          -- T'Père Noël ß MHz'
"Père Noël ß ㎒"~text~NFKC(casefold:.true)=          -- T'père noël ss mhz'

/*
Performance
    NFC, NFD, NFKC, NFKD and Casefold now supports the named argument 'returnString'.
    - When true, the returned value is a String.
    - When false (default), the returned value is a RexxText.
    Maybe this optimization will be replaced by a more general optimization: RexxText indexation on need.

    2 cached values are managed in case of memorization:
    - one for the main transformation,
    - one for the main transformation + case fold.
    That makes 9 possible cached value and 5 indicators per indexer (so per string).
        isCasefold                  CasefoldString
        isNFC       NFCString       NFCCasefoldString
        isNFD       NFDString       NFDCasefoldString
        isNFKC      NFKCString      NFKCCasefoldString
        isNFKD      NFKDString      NFKDCasefoldString

    The memorization can be activated globally:
    .Unicode~memorizeTransformations = .true

Examples
*/
-- Direct access to utf8proc, returns a string
s = "Père Noël ß ㎒"; do 10000; .Unicode~utf8proc_transform(s, norm:3, casefold:.true); end          -- Duration:   0.05
---
t = "Père Noël ß ㎒"~text; do 10000; t~NFKC(casefold:.true); end                                     -- Duration:   7.70
t = "Père Noël ß ㎒"~text; do 10000; t~NFKC(casefold:.true, returnString:.true); end                 -- Duration:   0.33
t = "Père Noël ß ㎒"~text; do 10000; t~NFKC(casefold:.true, returnString:.true, mem:.true); end      -- Duration:   0.11
-- The cache for NFKC  + casefold is different from the cache for NFKC only:
t = "Père Noël ß ㎒"~text; do 10000; t~NFKC; end                                                     -- Duration:   6.50
t = "Père Noël ß ㎒"~text; do 10000; t~NFKC(returnString:.true); end                                 -- Duration:   0.30
t = "Père Noël ß ㎒"~text; do 10000; t~NFKC(returnString:.true, mem:.true); end                      -- Duration:   0.10


-- ===============================================================================
-- 2022 November 05

/*
New methods on RexxText
    caselessContains        (not ready: posText)
    caselessCompareTo
    caselessMatch
    caselessMatchChar       (not ready: matchCharText)
    caselessEndsWith        (not ready: endsWithText)
    caselessPos             (not ready: posText)
    caselessStartsWith      (not ready: posText)
    compareTo
    contains                (not ready: posText)
    endsWith                (not ready: endsWithText)
    match
    matchChar               (not ready: matchCharText)
    pos                     (not ready: posText)
    startsWith              (not ready: posText)

For caseless, apply NFC Casefold to all the text/string arguments.
Compared to the ooRexx methods, the purpose of these methods is to convert the grapheme indexes to/from byte indexes.
The real work is done by the ooRexx methods, called with the right byte indexes.
From a byte index returned by an ooRexx method, a grapheme index is derived.


Examples:
*/
                                                --  1  2    3  4  5  6  7  8 9  10 (grapheme indexes)
                                                --  1  2 3  4  5  6  7  8  9 10 11 (byte indexes)
    "père Noël"~text~c2x=                       -- '70 C3A8 72 65 20 4E 6F C3AB 6C'
                                                --  p  è    r  e     N  o  ë    l
    "père Noël"~match(7, "Noël")=               -- .true (byte indexes)
    "père Noël"~text~match(6, "Noël")=          -- .true (grapheme indexes)
    "père Noël"~match(11, "Noël", 5)=           -- .true (byte indexes)
    "père Noël"~text~match(9, "Noël", 4)=       -- .true (grapheme indexes)

    "père Noël"~text~caselessMatch(6, "NOËL")=  -- .true

    -- the first "äXü" is NFC, the second "äẌü" is NFD
    nfcString = "äXü"
        nfcText = nfcString~text
        nfcText~c2x=                            -- 'C3A4 58 C3BC'
        nfcText~UnicodeCharacters==
    nfdString = "äXü"
        nfdText = nfdString~text
        nfdText~c2x=                            -- '61 CC88 58 75 CC88'
        nfdText~UnicodeCharacters==

    nfcString~match(1, nfdString)=              -- 0 (because binary representation is different)
    nfcText  ~match(1, nfdText)=                -- 1
    nfdText  ~match(1, nfcText)=                -- 1

    -- match with "X"

    nfcString~match(3, nfdString, 4, 1)=        -- 1 (byte indexes)
    nfcText  ~match(2, nfdText,   2, 1)=        -- 1 (grapheme indexes)

    nfdString~match(4, nfcString, 3, 1)=        -- 1 (byte indexes)
    nfdText  ~match(2, nfcText,   2, 2)=        -- 1 (grapheme indexes)

-- ===============================================================================
-- 2022 October 15

/*
New native method .Unicode~transform
Mainly for internal use, will replace the current native methods NFC, NFD, NFKC, NFKD.
The purpose of this method is to support additional transformations provided by utf8proc.
Takes a byte string as input (UTF-8 encoded), returns a new transformed byte string as output (UTF-8).

Examples:
*/
    string = "\u{BEL}Le\u{IDEOGRAPHIC SPACE}\u{OGHAM SPACE MARK}\u{ZERO-WIDTH-SPACE}Père\t\u{HYPHEN}\u{SOFT-HYPHEN}\u{EN DASH}\u{EM DASH}Noël\x{EFB790}\r\n"
    text = string~text~unescape
    text~UnicodeCharacters==

    text=                                                               -- T'[07]Le　 ​Père[09]‐­–—Noël﷐[0D0A]'

    -- Performs unicode case folding, to be able to do a case-insensitive string comparison.
    .Unicode~utf8proc_transform(text~string, casefold:.true)=           --  '[07]le　 ​père[09]‐­–—noël﷐[0D0A]'

    -- Strip "default ignorable characters" such as SOFT-HYPHEN or ZERO-WIDTH-SPACE
    .Unicode~utf8proc_transform(text~string, stripIgnorable:.true)=     --  '[07]Le　 Père[09]‐–—Noël﷐[0D0A]'

    -- Lumps certain characters together. See lump.md for details:
    -- https://github.com/JuliaStrings/utf8proc/blob/master/lump.md
    -- E.g. HYPHEN U+2010 and MINUS U+2212 to ASCII "-"
    -- jlf: I was expecting to have only one space and one "-" but that's not the case
    -- Seems working as designed... All the concerned characters become the same character, but still remain distinct characters.
    .Unicode~utf8proc_transform(text~string, lump:.true)=               --  '[07]Le  ​Père[09]-­--Noël﷐[0D0A]'

    -- NLF2LF: Convert LF, CRLF, CR and NEL into LF
    .Unicode~utf8proc_transform(text~string, NLF:1)=                    --  '[07]Le　 ​Père[09]‐­–—Noël﷐[0A]'

    -- NLF2LS: Convert LF, CRLF, CR and NEL into LS (U+2028 Zl 0 "LINE SEPARATOR")
    .Unicode~utf8proc_transform(text~string, NLF:2)=                    --  '[07]Le　 ​Père[09]‐­–—Noël﷐'

    -- NLF2PS: convert LF, CRLF, CR and NEL into PS (U+2029 Zp 0 "PARAGRAPH SEPARATOR")
    .Unicode~utf8proc_transform(text~string, NLF:3)=                    --  '[07]Le　 ​Père[09]‐­–—Noël﷐ '

    -- Strips and/or converts control characters.
    .Unicode~utf8proc_transform(text~string, stripCC:.true)=            --  'Le　 ​Père ‐­–—Noël﷐ '

    -- Strips all character markings.
    -- This includes non-spacing, spacing and enclosing (i.e. accents).
    -- This option works only with normalization.
    .Unicode~utf8proc_transform(text~string, stripMark:.true, normalization:1)=  --  '[07]Le　 ​Pere[09]‐­–—Noel﷐[0D0A]'

    -- Strips unassigned codepoints.
    .Unicode~utf8proc_transform(text~string, stripNA:.true)=            --  '[07]Le　 ​Père[09]‐­–—Noël[0D0A]'

    -- Application of several options (abbreviated names)
    .Unicode~utf8proc_transform(text~string, casef:.true, lump:.true, norm:1, stripi:.true, stripc:.true, stripm:.true, stripn:.true)= --  'le  pere ---noel '


-- ===============================================================================
-- 2022 September 14

/*
New methods on RexxText
    center
    centre
Examples:
*/
    "noël👩‍👨‍👩‍👧🎅"~text~description=                  -- 'UTF-8 not-ASCII (6 graphemes, 12 codepoints, 34 bytes, 0 error)'
    "noël👩‍👨‍👩‍👧🎅"~text~center(10)=                   -- T'  noël👩‍👨‍👩‍👧🎅  '
    "noël👩‍👨‍👩‍👧🎅"~text~center(10)~description=       -- 'UTF-8 not-ASCII (10 graphemes, 16 codepoints, 38 bytes, 0 error)'
    pad = "═"
    pad~description=                                          -- 'UTF-8 not-ASCII (1 grapheme, 1 codepoint, 3 bytes, 0 error)'
    pad~c2x=                                                  -- 'E29590'
    "noël👩‍👨‍👩‍👧🎅"~text~center(10, pad)=              -- T'══noël👩‍👨‍👩‍👧🎅══'
    "noël👩‍👨‍👩‍👧🎅"~text~center(10, pad)~description=  -- 'UTF-8 not-ASCII (10 graphemes, 16 codepoints, 46 bytes, 0 error)'


-- ===============================================================================
-- 2022 September 09


-- Start working on encoding~previousCodepointIndexB:
    "🎅noël"~text~c2x=  -- 'F09F8E85 6E 6F C3AB 6C'
    .utf8_encoding~previousCodepointIndexB("🎅noël", 0)=   -- 0
    .utf8_encoding~previousCodepointIndexB("🎅noël", 1)=   -- 1
    .utf8_encoding~previousCodepointIndexB("🎅noël", 2)=   -- 1
    .utf8_encoding~previousCodepointIndexB("🎅noël", 3)=   -- 1
    .utf8_encoding~previousCodepointIndexB("🎅noël", 4)=   -- 1
    .utf8_encoding~previousCodepointIndexB("🎅noël", 5)=   -- 1
    .utf8_encoding~previousCodepointIndexB("🎅noël", 6)=   -- 5
    .utf8_encoding~previousCodepointIndexB("🎅noël", 7)=   -- 6
-- Currently, only Byte_encoding and UTF8_encoding supports this new method.
-- Still lot of work to detect the same errors as nextCodepointIndex.


-- ===============================================================================
-- 2022 September 08

-- Set/get an encoding on a string without having an associated RexxText
-- (similar to MutableBuffer)
s = "nonsense"
s~encoding =                      -- returns the default encoding: (The UTF8_Encoding class)
s~hasText =                       -- 0
s~encoding = .UTF16BE_Encoding    -- tag the string: encoded UTF16BE
s~encoding =                      -- (The UTF16BE_Encoding class)
s~hasText =                       -- still no associated RexxText: 0
t = s~text                        -- associates a RexxText to the string
s~hasText =                       -- the string has an associated text: 1
t~encoding =                      -- the encoding of the text is the one of the string: (The UTF16BE_Encoding class)
t~utf8 =                          -- T'湯湳敮獥'      Soup
-- Setting/getting the encoding of the string will set/get the encoding of the associated RexxText
s~encoding = .UTF16LE_Encoding
t~encoding =                      -- the encoding of the text has been changed: (The UTF16LE_Encoding class)
t~utf8 =                          -- T'潮獮湥敳'      tide


-- ===============================================================================
-- 2022 September 07

/*
Add method MutableBuffer~isASCII
Implementation more complex than for String, because mutable.
Try to avoid to rescan the whole buffer, when possible.
The native methods that modify the buffer are never scanning the buffer, they
are just setting the boolean indicators is_ASCII_checked and is_ASCII.
It's only the Rexx method ~isASCII which scans the whole buffer, if needed.
Impacted methods:
    append
    caselessChangeStr
    changeStr
    delete
    delWord
    insert
    overlay
    replaceAt
    setBufferSize
    space
    translate
*/

b = .MutableBuffer~new("pere")
b~isASCII =                             -- 1
b~insert("noël", 5)=                    -- M'pere noël'
b~isASCII =                             -- 0
b~setBufferSize(7)=                     -- M'pere no'
b~isASCII=                              -- 1
b~append("ë", "l")=                     -- M'pere noël'
b~isASCII=                              -- 0
b~replaceAt("e", 8, 2)=                 -- M'pere noel'
b~isASCII=                              -- 1
b~changeStr("noel", "noël")=            -- M'pere noël'
b~isASCII=                              -- 0
b~delete(8,2)=                          -- M'pere nol'
b~isASCII=                              -- 1
b~overlay("ël", 8)=                     -- M'pere noël'
b~isASCII=                              -- 0
b~delWord(2)=                           -- M'pere '
b~isASCII=                              -- 1
b~translate("è" || "91"x, "er ")=       -- M'pèÑ'    ("è" is "C3A8"x so "e"-->"C3"x, "r"-->A8"x and " "-->"91"x
b~isASCII=                              -- 0


-- ===============================================================================
-- 2022 August 18

/*
Added Unicode case folding.
See https://www.w3.org/TR/charmod-norm/
Case folding is the process of making two texts which differ only in case identical for comparison purposes.
Implemented with utf8proc, which applies an NFKC normalization on the case-folded string.

Methods on RexxText:
    ~Casefold   ~isCasefold
*/
"ß"~text~casefold=               -- T'ss'
"㎒"~text~casefold=              -- T'mhz'   (jlf Nov 8, 2022: now unchanged because no longer NFKC)

("sTrasse", "straße", "STRASSE")~each{item~text~casefold}==

-- utf8proc doesn't support language-sensitive case-folding.
-- Example:
-- The name of the second largest city in Turkey is "Diyarbakır", which contains both the dotted and dotless letters i.
"Diyarbakır"~text~upper=        -- T'DIYARBAKIR'   should be DİYARBAKIR
"DİYARBAKIR"~text~casefold=     -- T'di̇yarbakir'   should be diyarbakır

-- The Julia developers, who uses utf8proc, have decided to remain locale-independent.
-- See https://github.com/JuliaLang/julia/issues/7848


-- ===============================================================================
-- 2022 August 07

/*
Added normalization NFC, NFD, NFKC, NFKD.
http://unicode.org/faq/normalization.html
Implemented with utf8proc.

Methods on RexxText:
    ~NFC    ~isNFC
    ~NFD    ~isNFD
    ~NFKC   ~isNFKC
    ~NFKD   ~isNFKD

Possible values for isNFxx:
    -1  unknown
     0  no
     1  yes
A same text can be in several normalization forms.
Text exclusively containing ASCII characters (U+0000..U+007F) is left unaffected
by all of the Normalization Forms: The 4 indicators isNFxx are 1.

The methods NFxx sets the corresponding indicator isNFxx
- on the source text : 0 or 1 (test if both strings are equal)
- on the result text : 1
*/

-- The normalized text can be memorized on the original text:
    text = "père Noël"~text
    textNFD = text~nfd(memorize:.true)      -- abbreviation mem:.true
-- From now, the returned NFD is always the memorized text:
    text~nfd == textNFD=                    -- .true


/*
    Some remarks about the string used in this demo:
    - the first "äöü" is NFC, the second "äöü" is NFD
    - "x̂" is two codepoints in any normalization.
    - "ϔ" normalization forms are all different.
    - "ﷺ" is one of the worst cases regarding the expansion factor in NFKS/NFKS: 18x
    - "baﬄe"~text~subchar(3)=     -- T'ﬄ'
      "baﬄe"~text~upper=          -- T'BAﬄE', not BAFFLE
      The ligature disappears in NFK[CD] but not in NF[CD]
*/
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~UnicodeCharacters==
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~description=      -- 'UTF-8 not-ASCII (18 graphemes, 22 codepoints, 34 bytes, 0 error)'
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~upper=            -- T'ÄÖÜ ÄÖÜ X̂ ϔ ﷺ BAﬄE

/*
    NFD
    Normalization Form D
    Canonical Decomposition
    Characters are decomposed by canonical equivalence, and multiple combining characters are arranged in a specific order.
*/
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfd~UnicodeCharacters==
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfd~description=  -- 'UTF-8 not-ASCII (18 graphemes, 26 codepoints, 39 bytes, 0 error)'
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfd~upper=        -- T'ÄÖÜ ÄÖÜ X̂ ϔ ﷺ BAﬄE'

/*
    NFC
    Normalization Form C
    Canonical Decomposition, followed by Canonical Composition
    Characters are decomposed and then recomposed by canonical equivalence.
*/
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfc~UnicodeCharacters==
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfc~description=  -- 'UTF-8 not-ASCII (18 graphemes, 19 codepoints, 31 bytes, 0 error)'
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfc~upper=        -- T'ÄÖÜ ÄÖÜ X̂ ϔ ﷺ BAﬄE'

/*
    NFKD
    Normalization Form KD
    Compatibility Decomposition (K is used to stand for compatibility to avoid confusion with the C standing for composition)
    Characters are decomposed by compatibility, and multiple combining characters are arranged in a specific order.
*/
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfkd~UnicodeCharacters==
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfkd~description= -- 'UTF-8 not-ASCII (37 graphemes, 45 codepoints, 69 bytes, 0 error)'
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfkd~upper=       -- T'ÄÖÜ ÄÖÜ X̂ Ϋ صلى الله عليه وسلم BAFFLE

/*
    NFKC
    Normalization Form KC
    Compatibility Decomposition, followed by Canonical Composition
    Characters are decomposed by compatibility, then recomposed by canonical equivalence.
*/
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfkc~UnicodeCharacters==
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfkc~description= -- 'UTF-8 not-ASCII (37 graphemes, 38 codepoints, 61 bytes, 0 error)'
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfkc~upper=       -- T'ÄÖÜ ÄÖÜ X̂ Ϋ صلى الله عليه وسلم BAFFLE'


-- The normalization forms are implemented only for UTF-8 and WTF-8.
"D800 DC01"x~text("utf16")~nfd~UnicodeCharacters==  -- Method TRANSFORM is ABSTRACT and cannot be directly invoked.
"D800 DC01"x~text("utf16")~utf8~nfd~UnicodeCharacters==
"\uD800\uDC01"~text("wtf8")~unescape~nfd~UnicodeCharacters==

-- If the WTF-8 string is not a valid UTF-8 string then an error is raised by utf8proc
"D800"x     ~text("wtf16")~wtf8~nfd~UnicodeCharacters==    -- Invalid UTF-8 string
"\uD800"~text("wtf8")~unescape~nfd~UnicodeCharacters==     -- Invalid UTF-8 string


-- ===============================================================================
-- 2022 August 03

/*
https://discourse.julialang.org/t/stupid-question-on-unicode/27674/10
    Should I support this when unescaping?
    (High surrogate followed by low surrogate)
    Surrogate pairs are a UTF-16-specific construct.
    However, string escapes aren’t byte sequences of a particular encoding.
    They are somewhat arbitrary substitutions / macros.
*/

        "\uD83D\uDE3F"~text~unescape~errors==

        "\uD83D\uDE3F"~text~wtf8~unescape~errors==

--    Yes, I should support it when the encoding is WTF-8, because the concatenation manages correctly this case:
        ("\uD83D"~text~wtf8~unescape || "\uDE3F"~text~wtf8~unescape)~UnicodeCharacters==

        ("\uD83D"~text~wtf8~unescape || "\uDE3F"~text~wtf8~unescape)~description=

--    Done, now "\uD83D\uDE3F"~text~wtf8~unescape=    -- "😿"


-- ===============================================================================
-- 2022 July 20

/*
I realize that I can pass options when filtering the unicode characters.
Same options as when sending the message "matcher" to a string.

-- Options: not wholestring, trace with prefix "> "
*/
.unicode~characters("father", w:0, t:1, p:">")

-- Same options with a regular expression.
-- "/father" is faster than "/.*father.*" but still very slow compared to "father"
.unicode~characters("/father", w:0, t:1, p:"> ")

-- Note that "/.*father.*" in mode not wholestring is just unusable: 419 sec under MBP 2010 Intel Core 2 Duo
-- [2022 Dec 22] Still unusable under MBP 2021 M1 Pro: 78s (only 5.37 faster)


-- ===============================================================================
-- 2022 July 17


-- For convenience, add an optional parameter 'filter' to the method .unicode~characters
    .unicode~characters("*rex*")==
-- is equivalent to
    matcher = "*rex*"~matcher; .unicode~characters~select{expose matcher; matcher~(item~name)}==

-- Regular expressions are supported:
-- returns all the characters whose name starts with "math" and ends with "psi"
    .unicode~characters("/^math.*psi$")==

/*
The regular expressions are implemented with 100% ooRexx code, and as such
can be particularly inefficient...
When applied to a collection of 43885 Unicode characters, we have:
    .unicode~characters("/.*father.*")    -- 30.5 sec
The same filter without regular expression:
    .unicode~characters("*father*")       -- 0.9 sec

Something to clarify:
Why such a difference of duration for the following pieces of code?
In the end, it's the same code in both cases:
matcher = "/.*father.*"~matcher; supplier = .unicode~characters; collectedItems = .Array~new; do while supplier~available; item = supplier~item; if matcher~(item~name) then collectedItems~append(item); supplier~next; end; collectedItems==
64 sec
matcher = "/.*father.*"~matcher; .unicode~characters~select{expose matcher; matcher~(item~name)}==
31 sec
*/

-- ===============================================================================
-- 2022 July 13

/*
Rework ~unescape to be closer to other languages:
\u{...} and \U{...} are equivalent
\u{X..X} is now hexadecimal, no more decimal codepoint. The first character must be 0..9.
\uXXXX is now supported
\UXXXXXXXX is now supported

Ex:
*/
"\u{bed} is different from \u{0bed}"~text~unescape=                         -- T'🛏 is different from ௭'
.unicode~character("bed")=                                                  -- ( "🛏"   U+1F6CF So 1 "BED" )
.unicode~character("bed", hexadecimal:.true)=                               -- ( "௭"   U+0BED Nd 1 "TAMIL DIGIT SEVEN" )
.unicode~character("U+0bed")=                                               -- ( "௭"   U+0BED Nd 1 "TAMIL DIGIT SEVEN" )
"The \u{t-rex} shows his \u{flexed biceps}!"~text~unescape=                 -- T'The 🦖 shows his 💪!'
"\u0031 + \u0032\u0033 = \u0032\u0034"~text~unescape=                       -- T'1 + 23 = 24'
"\U00000031 + \U00000032\U00000033 = \U00000032\U00000034"~text~unescape=   -- T'1 + 23 = 24'

-- ===============================================================================
-- 2022 February 13

/*
New method unescape, available only for Byte, UTF-8 and WTF-8.
    \b                  backspace (BS)
    \t                  horizontal tab (HT)
    \n                  linefeed (LF)
    \f                  form feed (FF)
    \r                  carriage return (CR)
    \u{Unicode name}    Character name in the Unicode database
    \u{N..N}            Unicode character denoted by 1-8 hex digits. The first character must be a digit 0..9.
    \u{U+X..X}          Unicode character denoted by 1-n hex digits
    \x{X..X}            sequence of 1..n hexadecimal digits
Examples:
*/
    "hello\u{space}John\n"~text~unescape=           -- T'hello John[0A]'
    "hello\u{20}John\n"~text~unescape=
    "hello\u{U+20}John\n"~text~unescape=

    -- \u is not supported for Byte encoding, you can use \x
    "hello\u{U+20}John\n"~text("byte")~unescape=    -- Byte encoding: \u not supported.
    "hello\x{20}John\n"~text("byte")~unescape       -- T'hello John[0A]'

    -- No implementation for UTF-16, WTF-16, UTF-32.
    "hello\u{U+20}John\n"~text~utf16~unescape=      -- Method UNESCAPE is ABSTRACT and cannot be directly invoked.


-- ===============================================================================
-- 2021 September 30

/*
New methods:
.String
    join (was concatenateSeparated)

.MutableBuffer
    join (was concatenateSeparated)

.Unicode
    []  (equivalent to .Unicode~character)

.UnicodeCharacter
    makeRexxText
    text
    wtf8
    wtf16
    wtf16be
    wtf16le

.RexxText
    join
    left
    right
    x2d

Examples:
*/

-- https://www.unicode.org/reports/tr29/#Grapheme_Cluster_Boundaries
-- no break before ZWJ (GB9), but break after if not emoji modifier sequence or emoji zwj sequence (GB11)
.unicode["zwj"]~text~join("ab", "cd", .unicode["woman"], .unicode["father christmas"])~c2g=  -- '61 62E2808D 63 64E2808D F09F91A9E2808DF09F8E85'
.unicode["zwj"]~text~join("ab", "cd", .unicode["woman"], .unicode["father christmas"])~graphemes==

"noël👩‍👨‍👩‍👧🎅"~text~UnicodeCharacters==

-- https://www.unicode.org/reports/tr29/#Grapheme_Cluster_Boundaries
-- Do not break within emoji modifier sequences or emoji zwj sequences (GB11).
"noël👩‍👨‍👩‍👧🎅"~text~graphemes==

do i=0 to 9; "left("i") = " || "noël👩‍👨‍👩‍👧🎅"~text~left(i)=; end

do i=0 to 9; "right("i") = " || "noël👩‍👨‍👩‍👧🎅"~text~right(i)=; end


-- ===============================================================================
-- 2021 September 28

/*
New methods:
.RexxText
    reverse

Examples:
*/

-- Correct reverse
"noël"~text~c2x=            -- '6E 6F C3AB 6C'
"noël"~text~reverse~c2x=    -- '6C C3AB 6F 6E'
"noël"~text~reverse=        -- T'lëon'

-- Wrong reverse
"noël"~c2x=             -- '6E6FC3AB6C'
"noël"~reverse~c2x=     -- '6CABC36F6E'
"noël"~reverse=         -- 'l??on'


-- ===============================================================================
-- 2021 September 27

/*
New native methods:
.Unicode
    codepointToLower
    codepointToUpper
    codepointToTitle
    codepointIsLower
    codepointIsUpper

New methods:
.RexxText
    lower
    upper
    isLower
    isUpper
    characters

Examples:
*/

"aàâäeéèêëiîïoôöuûü"~text~isUpper=              -- .false
"aàâäeéèêëiîïoôöuûü"~text~isLower=              -- .true
"AÀÂÄEÉÈÊËIÎÏOÔÖUÛÜ"~text~isUpper=              -- .true
"AÀÂÄEÉÈÊËIÎÏOÔÖUÛÜ"~text~isLower=              -- .false
"Le père Noël est fatigué..."~text~upper=       -- T'LE PÈRE NOËL EST FATIGUÉ...'
"LE PÈRE NOËL EST FATIGUÉ..."~text~lower=       -- T'le père noël est fatigué...'

/*
utf8proc supports only the basic cases (those in UnicodeData.txt).
The cases described in SpecialCasing.txt are not supported by utf8proc.
Examples:
*/
-- # The German es-zed is special--the normal mapping is to SS.
-- # Note: the titlecase should never occur in practice. It is equal to titlecase(uppercase(<es-zed>))
-- # <code>; <lower>; <title>; <upper>; (<condition_list>;)? # <comment>
-- 00DF; 00DF; 0053 0073; 0053 0053; # LATIN SMALL LETTER SHARP S

/*
TODO: full casing not yet implemented
    .Unicode~codepointToLowerFull
    .Unicode~codepointToUpperFull
    .Unicode~codepointToTitleFull
The rest of the framework is ready for full casing.
*/

.unicode~character("LATIN SMALL LETTER SHARP S")~utf8=          -- T'ß'
.unicode~character("LATIN SMALL LETTER SHARP S")~toUpperSimple= -- 7838, which is the codepoint of (U+1E9E Lu "LATIN CAPITAL LETTER SHARP S")
.unicode~character(7838)~utf8=                                  -- T'ẞ'
-- T'ß' to uppercase should be T'SS':
"0053 0053"x~text("utf16")~UnicodeCharacters==

-- # Preserve canonical equivalence for I with dot. Turkic is handled below.
-- 0130; 0069 0307; 0130; 0130; # LATIN CAPITAL LETTER I WITH DOT ABOVE
.unicode~character("LATIN CAPITAL LETTER I WITH DOT ABOVE")~utf8=           -- T'İ'
.unicode~character("LATIN CAPITAL LETTER I WITH DOT ABOVE")~toLowerSimple=  -- 105, which is the codepoint of (U+0069 Ll "LATIN SMALL LETTER I")
.unicode~character(105)~utf8=                                               -- T'i'
-- T'İ' to lowercase should be T'i̇̇':
"0069 0307"x~text("utf16")~UnicodeCharacters==

-- # Turkish and Azeri
-- # I and i-dotless; I-dot and i are case pairs in Turkish and Azeri
-- # The following rules handle those cases.
-- 0130; 0069; 0130; 0130; tr; # LATIN CAPITAL LETTER I WITH DOT ABOVE
-- 0130; 0069; 0130; 0130; az; # LATIN CAPITAL LETTER I WITH DOT ABOVE

-- # Note: the following case is already in the UnicodeData.txt file.
-- # 0131; 0131; 0049; 0049; tr; # LATIN SMALL LETTER DOTLESS I
.unicode~character("LATIN SMALL LETTER DOTLESS I")~utf8=            -- T'ı'
.unicode~character("LATIN SMALL LETTER DOTLESS I")~toUpperSimple=   -- 73, which is the codepoint of (U+0049 Lu "LATIN CAPITAL LETTER I")
.unicode~character(73)~utf8=                                        -- T'I'


-- Which characters have their title character different from their upper character?
.unicode~characters~select{item~toTitleSimple <> item~toUpperSimple}~each{.Unicode[item~toTitleSimple]~utf8 .Unicode[item~ToUpperSimple]~utf8 item~utf8 item~string}==


-- ===============================================================================
-- 2021 September 22

/*
New native methods:
.Unicode
    codepointBidiMirrored
    codepointDecompositionType


Add character aliases.
.unicode~characters returns now a supplier, instead of the internal array of characters.
The indexes of the characters supplier are the codepoints, not the indexes of the
internal array which are codepoint+2.
*/
.unicode~characters==

/*
Add character intervals.
.UnicodeCharacterInterval
    codepointFrom
    codepointTo
    name
    isExpanded
*/
.unicode~characterIntervals==


-- Informations about Unicode:
-- Remove dataDirectory because the value is different between Windows and Macos/Linux
.Unicode~informations~~remove("dataDirectory")=


-- ===============================================================================
-- 2021 September 13, updated September 22

/*
Add character informations.

The loading of the character names is optional.
By default, they are not loaded.
From ooRexxShell, execute: call loadUnicodeCharacterNames
By default, the character intervals are not expanded.
From ooRexxShell, execute: call expandUnicodeCharacterIntervals

The other character properties are always loaded (provided by utf8proc)

.Unicode
    characters          --> supplier of UnicodeCharacter
    character(index)    --> UnicodeCharacter (index can be a loose matching name (UAX44-LM2) or a codepoint)
    characterIntervals  --> supplier of UnicodeCharacterInterval

.UnicodeCharacter
    codepoint       --> integer -1..1114111
    name            --> string
    aliases         --> array of .UnicodeAlias

    bidiClass       --> enum 1, 2, 3, ...
    bidiClassName   --> enum 'L', 'LRE', 'LRO', ...
    boundClass      --> enum 0, 1, 2, ...
    boundClassName  --> enum 'START', 'OTHER', 'CR', ...
    category        --> enum 0, 1, 2, ...
    categoryName    --> enum 'Cn', 'Lu', 'Ll', ...
    charWidth       --> integer
    combiningClass  --> integer 0..254
    controlBoundary --> boolean
    decompType      --> enum 0, 1, 2, ...
    decompTypeName  --> enum '<none>', '<font>', '<nobreak>, ...
    ignorable       --> boolean

Examples:
*/
-- All the Unicode characters (sparse array).
.unicode~characters==

-- The last 10 characters
.unicode~characters~pipe(.take "last" 10 | .console)

-- get a character by codepoint
.unicode~character(8203)=                   -- (U+200B Cf "ZERO WIDTH SPACE")
.unicode~character("U+200B")=               -- (U+200B Cf "ZERO WIDTH SPACE")
.unicode~character("u+200b")=               -- (U+200B Cf "ZERO WIDTH SPACE")

-- get a character by name.
-- loose matching name. See https://unicode.org/reports/tr44/#UAX44-LM2
.unicode~character("ZERO WIDTH SPACE")=     -- (U+200B Cf "ZERO WIDTH SPACE")
.unicode~character("ZERO_WIDTH-SPACE")=     -- (U+200B Cf "ZERO WIDTH SPACE")
.unicode~character("ZEROWIDTHSPACE")=       -- (U+200B Cf "ZERO WIDTH SPACE")
.unicode~character("zerowidthspace")=       -- (U+200B Cf "ZERO WIDTH SPACE")

-- select characters using a matcher
-- remember: it's better to initialize the matcher outside the iteration.
matcher = "*chris*"~matcher; .unicode~characters~select{expose matcher; matcher~(item~name)}==

-- string character names
"noël👩‍👨‍👩‍👧🎅"~text~codepoints~each{uchar = .unicode~character(item); uchar~charWidth uchar~categoryName uchar~name}==

-- shortest name:
.unicode~characters~reduce{if accu~name~length > item~name~length, item~name~length <> 0 then item }=

-- longest name:
.unicode~characters~reduce{if accu~name~length < item~name~length then item }=


-- ===============================================================================
-- 2021 September 12

/*
[String chunks]

The functionality of splitting text by quoted/unquoted chunks is moved from
ooRexxShell to a dedicated package:
extension/stringChunk.cls               (compatible with official ooRexx)

The initial need was to parse a command line and split it the same way as a cmd
or bash shell. Also used to parse the queries in ooRexxShell.
The quotes are removed, but each character is associated to a 'quote flag' to
remember if the character was inside a quoted section.
These flags are typically used by the matchers of type string pattern, to decide
if a character can be special or not.

Description:
    routine stringChunks
    use strict arg string, withInfos=.false, breakTokens="", splitLevel=1

    Converts a string to an array of String or to an array of stringChunk.
    The type of result is indicated by the argument withInfos:
    - If withInfos == .false (default) then the result is an array of String.
    - If withInfos == .true then the result is an array of StringChunk.

    A StringChunk is a substring which references the start and end character
    in its container. It's associated to a string of booleans (quotedFlags)
    which indicate for each character if it was inside a quoted section.

    A quote is either " or '.

    An unquoted section is splitted in StringChunks delimited by whitespaces
    (anything <= 32) and break tokens.

    A quoted section is not splitted:
    - Whitespaces are kept,
    - single occurences of quotes are removed,
    - double occurrence of quotes are replaced by a single embedded quote,
    - break tokens and escape characters are ignored.

    An escape character is any character passed in the argument escapeCharacters.
    An escape character sets the quote flag of the next character to 1.
    Escape characters are removed, even if they are not followed by another
    character (truncated string).
    Example with 'a' declared escape character:
    - "a" --> ""
    - "aa" --> "a"
    - "aaa" --> "a"
    - "aaaa" --> "aa"

    If a quote is declared escape character, there is no impact: a quote is
    already an escape mechanism.

    If a space is declared escape character, there is an impact when splitLevel=0:
    the quote flag of a character following an unquoted space is set to 1, the
    unquoted spaces are removed
    Example:
        'one two "three four" five six' --> onetwothree fourfivesix
                                            00010011111111111000100

    Break tokens are passed in the argument breakTokens.
    A break token cannot contains spaces.
    The break tokens can be case sensitive (default) or case insensitive.
    Each break token can be prefixed by:
    - cs:  case sensitive
    - ci:  case insensitive
    - cl:  caseless (synonym of case insensitive)
    Any other prefix is not an error. It's just not a case prefix.

    If a quote is declared break token then it's no longer recognized as a quote.
    If an escape character is declared break token then it's no longer recognized
    as an escape character.

    The split process is controlled by the argument splitLevel:
    - If splitLevel == 0 then the string is not splitted but the quotes and
      escape characters are managed, quotedFlags is set.
        'xx aa"b b"cc"d d"ee yy' is 1 StringChunk.
    - If splitLevel == 1 (default) then adjacent quoted/unquoted sections are kept glued.
        'xx aa"b b"cc"d d"ee yy' is 3 StringChunk: xx "aab bccd dee" yy
    - If splitLevel == 2 then adjacent quoted/unquoted sections are separated.
        'xx aa"b b"cc"d d"ee yy' is splitted in 7 StringChunk: xx aa "b b" cc "d d" ee yy

    Illustration with splitLevel=1:
     11111111111111111111111111 222222222222222 333333333333333333333
    '"hello "John" how are you" good" bye "John "my name is ""BOND"""'
     0000000001111111111222222222233333333334444444444555555555566666
     1234567890123456789012345678901234567890123456789012345678901234
    arg1 = |hello John how are you|      containerStart = 01      containerEnd = 26      quotedFlags = 1111110000111111111111
    arg2 = |good bye John|               containerStart = 28      containerEnd = 42      quotedFlags = 0000111110000
    arg3 = |my name is "BOND"|           containerStart = 44      containerEnd = 64      quotedFlags = 11111111111111111

Extensions available in Executor only:
    .String~chunk           withInfos is true, splitLevel is 0 --> always returns ONE StringChunk
    .String~chunks          withInfos is true by default, splitLevel is 1 by default

Examples:
*/
    -- splitLevel = 0: no split
    'aa"b\ b"cc"d\ d"ee\* ff'~chunks(splitLevel:0)~each{item~sayDescription(25, index, 2)}
/*
        1  |aab\ bccd\ dee\* ff|       01 23 |aa"b\ b"cc"d\ d"ee\* ff|
        1  |0011110011110000000|
*/

    -- splitLevel = 1: Adjacent quoted/unquoted sections are kept glued
    'aa"b\ b"cc"d\ d"ee\* ff'~chunks(splitLevel:1)~each{item~sayDescription(25, index, 2)}
/*
        1  |aab\ bccd\ dee\*|          01 20 |aa"b\ b"cc"d\ d"ee\*|
        1  |0011110011110000|
        2  |ff|                        22 23 |ff|
        2  |00|
*/

    -- splitLevel = 2: Adjacent quoted/unquoted sections are separated
    'aa"b\ b"cc"d\ d"ee\* ff'~chunks(splitLevel:2)~each{item~sayDescription(25, index, 2)}
/*
        1  |aa|                        01 02 |aa|
        1  |00|
        2  |b\ b|                      03 08 |"b\ b"|
        2  |1111|
        3  |cc|                        09 10 |cc|
        3  |00|
        4  |d\ d|                      11 16 |"d\ d"|
        4  |1111|
        5  |ee\*|                      17 20 |ee\*|
        5  |0000|
        6  |ff|                        22 23 |ff|
        6  |00|
*/

    -- Default splitLevel (1)
    -- The quote is declared break token, there is no more quoted sections, and the quote itself is returned
    'aa"b\ b"cc"d\ d"ee\* ff'~chunks(breakTokens: '"')~each{item~sayDescription(25, index, 2)}
/*
        1  |aa|                        01 02 |aa|
        1  |00|
        2  |"|                         03 03 |"|
        2  |0|
        3  |b\|                        04 05 |b\|
        3  |00|
        4  |b|                         07 07 |b|
        4  |0|
        5  |"|                         08 08 |"|
        5  |0|
        6  |cc|                        09 10 |cc|
        6  |00|
        7  |"|                         11 11 |"|
        7  |0|
        8  |d\|                        12 13 |d\|
        8  |00|
        9  |d|                         15 15 |d|
        9  |0|
        10 |"|                         16 16 |"|
        10 |0|
        11 |ee\*|                      17 20 |ee\*|
        11 |0000|
        12 |ff|                        22 23 |ff|
        12 |00|
*/

    -- Same as previous, plus \ which is declared escape character
    'aa"b\ b"cc"d\ d"ee\* ff'~chunks(breakTokens: '"', escapeCharacters:"\")~each{item~sayDescription(25, index, 2)}
/*
        1  |aa|                        01 02 |aa|
        1  |00|
        2  |"|                         03 03 |"|
        2  |0|
        3  |b b|                       04 07 |b\ b|
        3  |010|
        4  |"|                         08 08 |"|
        4  |0|
        5  |cc|                        09 10 |cc|
        5  |00|
        6  |"|                         11 11 |"|
        6  |0|
        7  |d d|                       12 15 |d\ d|
        7  |010|
        8  |"|                         16 16 |"|
        8  |0|
        9  |ee*|                       17 20 |ee\*|
        9  |001|
        10 |ff|                        22 23 |ff|
        10 |00|
*/

    -- A break token can be made of several characters, and can contain a quote
    'aa"b\ b"cc"d\ d"ee\* ff'~chunks(breakTokens: ' a"b ')~each{item~sayDescription(25, index, 2)}
/*
        1  |a|                         01 01 |a|
        1  |0|
        2  |a"b|                       02 04 |a"b|
        2  |000|
        3  |\|                         05 05 |\|
        3  |0|
        4  |bccd\|                     07 13 |b"cc"d\|
        4  |01100|
        5  |dee\* ff|                  15 23 |d"ee\* ff|
        5  |01111111|
*/

    -- If an escape character is also declared break token then it's no longer an escape character
    'aa"b\ b"cc"d\ d"ee\* ff'~chunks(breakTokens:"\", escapeCharacter:"\")~each{item~sayDescription(25, index, 2)}==
/*
        1  |aab\ bccd\ dee|            01 18 |aa"b\ b"cc"d\ d"ee|
        1  |00111100111100|
        2  |\|                         19 19 |\|
        2  |0|
        3  |*|                         20 20 |*|
        3  |0|
        4  |ff|                        22 23 |ff|
        4  |00|
*/

    -- A break token can contain characters that are declared escape character
    'aa"b\ b"cc"d\ d"ee\* ff'~chunks(breakTokens:"e\*", escapeCharacters:"\*")~each{item~sayDescription(25, index, 2)}==
/*
        1  |aab\ bccd\ de|             01 17 |aa"b\ b"cc"d\ d"e|
        1  |0011110011110|
        2  |e\*|                       18 20 |e\*|
        2  |000|
        3  |ff|                        22 23 |ff|
        3  |00|
*/

    -- A break token can be case insensitive (prefix ci: or cl:)
    '1Plus2'~chunks(breakTokens:"ci:plus")~each{item~sayDescription(25, index, 2)}
/*
        1  |1|                         1 1 |1|
        1  |0|
        2  |Plus|                      2 5 |Plus|
        2  |0000|
        3  |2|                         6 6 |2|
        3  |0|
*/

/*
[String patterns]

The functionality of selecting text using patterns is moved from ooRexxShell
to a dedicated package:
extension/stringChunkExtended.cls       (not compatible with official ooRexx)

Description
    .StringChunk~matcher
    use strict named arg wholeString(1)=.true, caseless(1)=.true,-
                         trace(1)=.false, displayer(1)=.traceOutput, prefix(1)=""

    Pattern matching by equality (whole) or by inclusion (not whole), caseless or not.

    If the package regex.cls is loaded, then the pattern (a StringChunk) can be
    a regular expression prefixed by "/".

    When whole, and the pattern is not a regular expression, then the charecter
    "*" is recognized as a generic character when first or last character.

    When not whole, and the pattern is not a regular expression, then the character
    "^" is recognized as the metacharacter 'begining of string' when first character.

    When not whole, and the pattern is not a regular expression, then the character
    "$" is recognized as the metacharacter 'end of string' when last character.

    The returned result is a closure (matcher) which implements the pattern matching,
    or .nil if error.

    The pattern matching is tested when the closure is evaluated with a string passed
    as argument.

    Examples:

        '*' or '**'      : matches everything
        '"*"' or '"**"'  : matches exactly "*" or "**", see case stringPattern
        '***'            : matches all names containing "*", see case *stringPattern*
        '*"*"*'          : matches all names containing "*", see case *stringPattern*
        '*"**"*'         : matches all names containing "**", see case *stringPattern*
        '*stringPattern' : string~right(stringPattern~length)~caselessEquals(stringPattern)
        'stringPattern*' : string~left(stringPattern~length)~caselessEquals(stringPattern)
        '*stringPattern*': string~caselessPos(stringPattern) <> 0
        'stringPattern'  : string~caselessEquals(stringPattern)
*/

        -- caseless equality
        matcher = "object"~matcher
        say matcher~("ObjeCt") -- true
        say matcher~("my ObjeCt") -- false

        -- caseless equality with generic character
        matcher = "*object"~matcher
        say matcher~("ObjeCt") -- true
        say matcher~("my ObjeCt") -- true

        -- caseless inclusion
        matcher = "object"~matcher(wholeString:.false)
        say matcher~("ObjeCt") -- true
        say matcher~("my ObjeCt") -- true

        -- caseless inclusion, regular expression: "object" at the begining or at the end.
        matcher = "/^object|object$"~matcher(wholeString:.false)
        say matcher~("ObjeCt") -- true
        say matcher~("my ObjeCt") -- true
        say matcher~("my ObjeCts") -- false

        -- trace
        "*stringPattern"~matcher(trace:.true)
/*
        output:
            description: stringChunkPattern="*stringPattern" wholeString=1 caseless=1
            stringPattern="stringPattern"
            matcher: expose description stringPattern; use strict arg string; return string~right(stringPattern~length)~caselessEquals(stringPattern)
*/

        -- trace when regular expression
        "/.*stringPattern"~matcher(trace:.true)
/*
        output:
            description: stringChunkPattern="/.*stringPattern" wholeString=1 caseless=1
            stringPattern=".*stringPattern"
            pattern = .Pattern~compile(stringPattern, .RegexCompiler~new(.RegexCompiler~caseless))
            matcher: expose description pattern; use strict arg string; return pattern~matches(string)
*/

-- ===============================================================================
-- 2021 August 11

/*
Added support for strings of codepoints encoded as native integers.
3 representations:
    Unicode8_Encoding
    Unicode16_Encoding
    Unicode32_Encoding.
The method ~unicode returns one of these encodings, depending on the character
with the largest Unicode codepoint (1, 2, or 4 bytes) in the source string.
Unlike the flexible representation of Python, the 3 representions are first-class.
No BOM, the endiannes is the CPU one. This is for internal use only.
Unicode32_Encoding can be used with utf8proc for the functions taking a buffer of 32-bit integers.
*/

"côté"~text("unicode8")=    -- T'côté Just an interpretative layer put above the string
"côté"~text("unicode8")~pipe{item~description(s:1) ":" item~c2x}=
--    'Unicode8 not-ASCII : 63 C3 B4 74 C3 A9

"côté"~text~unicode=        -- T'c?t?' UTF-8 converted to Unicode8
"côté"~text~unicode~pipe{item~description(s:1) ":" item~c2x}=
--    'Unicode8 not-ASCII : 63 F4 74 E9

"noël‍👨‍👩‍👧"~text~maximumCodepoint~pipe{"U+"item~d2x}=   -- U+1F469 is the maximum codepoint
"noël‍👨‍👩‍👧"~text~unicode~description(t:1)=              -- For this maximum codepoint, we need Unicode32
--    'Unicode32 not-ASCII (5 graphemes (1 index from index 5), 10 codepoints (0 index), 40 bytes, 0 error)'

-- The endianness of the UnicodeXX_Encoding is the one of the machine.
-- With an Intel CPU, it's little-endian.
"noël‍👨‍👩‍👧"~text~unicode~c2x=
--    '6E000000 6F000000 EB000000 6C000000 0D200000 68F40100 0D200000 69F40100 0D200000 67F40100'

-- The default endianness for UTF32 is big-endian.
"noël‍👨‍👩‍👧"~text~utf32~c2x=
--    '0000006E 0000006F 000000EB 0000006C 0000200D 0001F468 0000200D 0001F469 0000200D 0001F467'


-- ===============================================================================
-- 2021 may 31

/*
Encodeded strings.
The ooRexx programmer has the choice:
- working with String at byte level
- working with RexxText at grapheme level.
- the same instance of String is used in both cases.

    aString
     ▲  text --------> aRexxText
     │                     indexer (anEncoding)
     │                          codepoints (sequential access)
     │                          graphemes  (direct access)
     +-----------------------<- string
*/

-- First binding of utf8proc, for the detection of grapheme cluster break.
"( ͡° ͜ʖ﻿ ͡°)"~text~description=                    -- 'UTF-8 not-ASCII ( 9 graphemes, 12 codepoints, 20 bytes )'
"( ͡° ͜ʖ﻿ ͡°)"~text~graphemes~each{item~c2x}=       -- [ 28,'20CDA1','C2B0','20CD9C','CA96','EFBBBF','20CDA1','C2B0', 29]

-- Classes in relation with Unicode and encoded strings:
?c *encoding* *encoded* *indexer* *codepoint* *grapheme* *RexxText* *Unicode*

-- ===============================================================================
-- 2021 mar 24

/*
Optimization of String~isASCII:
The old implementation checks from start to end.
The new implementation checks from start ascending, from middle descending, from middle ascending, from end descending.
That will divide by 4 the number of iterations, while increasing the chance to find a not-ascii character faster.
Strangely, the new implementation is also faster when all the characters are ASCII.

Benchmark using a version where the flag isASCII is not stored:
*/
big10m = "0123456789"~copies(1e6)
s = big10m                              -- 10 millions of ASCII characters, must check all of them
-- do 1000; s~isASCIIold; end              -- 9.3s
do 1000; s~isASCII; end                 -- 6.2s
s = "é" || big10m                       -- 1 non-ASCII character followed by 10 millions of ASCII characters
-- do 1000; s~isASCIIold; end              -- 0.001s
do 1000; s~isASCII; end                 -- 0.001s
s = big10m || "é"                       -- 10 millions of ASCII characters followed by 1 non-ASCII character
-- do 1000; s~isASCIIold; end              -- 9.3s
do 1000; s~isASCII; end                 -- 0.001s
big5m = "01234"~copies(1e6)
s = big5m || "é" || big5m               -- 1 non-ASCII character in the middle of 10 millions of ASCII characters
-- do 1000; s~isASCIIold; end              -- 4.7s
do 1000; s~isASCII; end                 -- 0.001s


-- ===============================================================================
-- 2021 mar 15

/*
Encoded strings (prototype).
Added support for UTF-8.
Added suppliers for codepoints and graphemes.
*/

s = "ça va ?"
s~length=                           -- 8
s~eachC{item~c2x" "}=               -- ['C3 ','A7 ', 61 , 20 , 76 , 61 , 20 ,'3F ']
s~text~encoding=                    -- (The Byte_Encoding class)
s~text~length=                      -- 8
s~text("utf8")~length==             -- 7
s~text~codepoints~each=             -- [ 231, 97, 32, 118, 97, 32, 63]
s~text~graphemes~each("c2x")=       -- ['C3A7', 61, 20, 76, 61, 20,'3F']
