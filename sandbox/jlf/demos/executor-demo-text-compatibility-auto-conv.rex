prompt off directory
demo on

call loadUnicodeCharacterNames

-- These demos were designed before the introduction of the immediate
-- "invalid text" error and before the introduction of the privileged encoding
-- status of Byte_Encoding.
.Unicode~immediateError = .false
.Unicode~promoteByteEncoding = .false

----------------------------------------------------------------
-- Text encoding - Compatibility with String
-- Automatic conversion of String literals to RexxText instances
----------------------------------------------------------------

/*
Compatibility with the class String.
This is a work in progress, many methods not yet supported,
Unicode implementation still missing for many methods.
*/
sleep no prompt

/*
This string is used in several places:
"noël👩‍👨‍👩‍👧🎅"
Depending on your editor/browser, you may see 5 emojis, or 3 emojis.
With Unicode 13, the display is 3 emojis (woman + family + father christmas).
👩	U+1F469	WOMAN
‍	U+200D	ZERO WIDTH JOINER
👨	U+1F468	MAN
‍	U+200D	ZERO WIDTH JOINER
👩	U+1F469	WOMAN
‍	U+200D	ZERO WIDTH JOINER
👧	U+1F467	GIRL
🎅	U+1F385	FATHER CHRISTMAS

Notice that 👩‍👨‍👩‍👧 constitute only 1 grapheme thanks to the ZERO WIDTH JOINER.
*/
sleep no prompt


"noël👩‍👨‍👩‍👧🎅"~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~c2u=
sleep
"noël👩‍👨‍👩‍👧🎅"~c2x=
sleep
"noël👩‍👨‍👩‍👧🎅"~c2g=
sleep no prompt


/*
Two RexxText values are considered equal if their extended grapheme clusters
are canonically equivalent.This is used by the Swift language.
Q&A: https://lists.isocpp.org/sg16/2018/08/0121.php

TODO: confirm that it's NFC, and only that.
The definition of canonical equivalence by the Unicode standard seems not
limited to NFC. https://unicode.org/notes/tn5/
*/
sleep no prompt

/*
The strict comparison operators use the NFC normalization.
After normalization, they delegate to the String's strict comparison operators.

The non-strict comparison operators use the NFKD normalization plus
    stripIgnorable:.true
    lump:.true
After normalization + transformations, they delegate to the String's non-strict
comparison operators. Thanks to the lump transformation, all the Unicode spaces
are supported.
*/

textNFC = "Noël"~NFC
sleep
textNFC~UnicodeCharacters==
sleep
textNFD="Noël"~NFD
sleep
textNFD~UnicodeCharacters==
sleep
(textNFC == textNFD)=                                               -- 1
sleep
(textNFC = textNFD)=                                                -- 1
sleep
(" "textNFC == textNFD" ")=                                         -- 0 because strict
sleep
(" "textNFC = textNFD" ")=                                          -- 1
sleep
(" "textNFC = (textNFD"\u{NBSP}")~unescape)=                        -- 1
sleep
(" "textNFC = (textNFD"\u{ZWSP}")~unescape)=                        -- 1
sleep
("-"textNFC = ("\u{OBLIQUE HYPHEN}"textNFD"\u{ZWSP}")~unescape)=    -- 1
sleep no prompt


-- []
"noël👩‍👨‍👩‍👧🎅"[3]=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"[3,3]=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"[3,6]=; result~description=
sleep no prompt


-- ?
"0"~?("true", "false")=
sleep
"1"~?("true", "false")=
sleep
"not a boolean value"~?("true", "false")=
sleep
"not a boolean value 🤔"~?("true", "false")=
sleep
"0"~?("true 🤔", "false 🤔")=
sleep
"1"~?("true 🤔", "false 🤔")=
sleep no prompt


-- append
"hello"~append(" ")~append("john")=
sleep
"\uD83D"~text("wtf8")~append("\uDE3F")~unescape=    -- High surrogate followed by low surrogate is valid WTF-8
sleep
"\uD83D"~text("utf8")~append("\uDE3F")~unescape=    -- High surrogate followed by low surrogate is INVALID UTF-8
sleep
-- Something to rework: the String BIF/BIM lose the encoding
-- Must use ~text to have the right encoding after concatenation of WTF-8 with UTF-8
-- See diary on 2022 August 03: The ~unescape will manage correctly this concatenation when WTF-8
-- Using ~~setEncoding("wtf8") instead of ~text("wtf8") doesn't work because the encoding is lost:
"\uD83D"~text("wtf8")~append("\uDE3F")=; result~description=            -- T'\uD83D\uDE3F'  'WTF-8 ASCII (12 characters, 12 codepoints, 12 bytes, 0 error)'
"\uD83D"~text("wtf8")~append("\uDE3F")~unescape~c2x=                    -- 'F09F98BF'   good!
"\uD83D"~~setEncoding("wtf8")~append("\uDE3F")=; result~description=    -- '\uD83D\uDE3F'   'UTF-8 ASCII by default (12 bytes)'
"\uD83D"~~setEncoding("wtf8")~append("\uDE3F")~unescape~c2x=            -- 'ED A0 BD ED B8 BF'  not good!
sleep no prompt


-- c2d
"e"~c2d=
"é"~c2d=
sleep no prompt


-- c2x
"noël👩‍👨‍👩‍👧🎅"~c2x=
sleep no prompt


/*
A caseless method is transforming its arguments using CaseFold.
The default normalization is NFC, it's possible to change it with the argument
normalization
    .unicode~NFC    (default)
    .unicode~NFD
    .unicode~NFKC
    .unicode~NFKD
There is no value NFKC_CF because it can be done using the caseless methods by
passing NFKC + stripIgnorable.
*/
sleep no prompt


-- caselessCompare
-- casefold 2 characters: "ß" becomes "ss"
"Bundesstraße im Freiland"~caselessCompare("Bundesstraße")=        -- 14
sleep
"Bundesstraße im Freiland"~caselessCompare("Bundesstraße", "_")=   -- 13
sleep
"Bundesstraße im Freiland"~caselessCompare("bundesstrasse")=       -- 14
sleep
"Bundesstrasse im Freiland"~caselessCompare("bundesstraße")=       -- 15
sleep
"straßssßßssse"~compare("stra", "ß")=                              --  6
sleep
"straßssßßssse"~caselessCompare("stra", "ß")=                      -- 12 (not 13 because the last 's' matches only half of the casefolded pad "ß" which is "ss")
sleep no prompt


-- caselessCompareTo
"pere noel"~caselessCompareTo("Père Noël")=                    -- -1 (lesser)
sleep
"pere noel"~caselessCompareTo("Père Noël", stripMark:.true)=   --  0 (equal because the accents are ignored)
sleep no prompt


-- caselessEndsWith
"hello"~caselessEndsWith("")=                  -- false
sleep
"hello"~caselessEndsWith("O")=                 -- true
sleep
"hello"~caselessEndsWith("Ô")=                 -- false
sleep
"hello"~caselessEndsWith("Ô", stripMark:)=     -- true
sleep no prompt
sleep
"noël👩‍👨‍👩‍👧🎅"~caselessEndsWith("🎅")=                -- true
sleep
"noël👩‍👨‍👩‍👧🎅"~caselessEndsWith("👧🎅")=              -- false (not aligned with a grapheme)
sleep
"noël👩‍👨‍👩‍👧🎅"~caselessEndsWith("‍👧🎅")=             -- false (not aligned with a grapheme)
sleep
"noël👩‍👨‍👩‍👧🎅"~caselessEndsWith("👩‍👧🎅")=           -- false (not aligned with a grapheme)
sleep
"noël👩‍👨‍👩‍👧🎅"~caselessEndsWith("ël👩‍👨‍👩‍👧🎅")=   -- true
sleep
"noël👩‍👨‍👩‍👧🎅"~caselessEndsWith("ËL👩‍👨‍👩‍👧🎅")=   -- true


-- caselessEquals
"ŒUF"~caselessEquals("œuf")=           -- 1
sleep
"œuf"~caselessEquals("ŒUF")=           -- 1
sleep
"Straße"~caselessEquals("strasse")=    -- 1
sleep
"strasse"~caselessEquals("Straße")=    -- 1
sleep no prompt

-- caselessEquals (cont.) strict versus non-strict
string1 = "LE\u{IDEOGRAPHIC SPACE}PÈ\u{ZERO-WIDTH-SPACE}RE\u{HYPHEN}NOËL"~unescape
string2 = "Le\u{OGHAM SPACE MARK}Père\u{EN DASH}No\u{ZERO-WIDTH-SPACE}ël"~unescape
sleep
string1=                                                -- T'LE　PÈ​RE‐NOËL
string2=                                                -- T'Le Père–No​ël'
sleep
string1~c2x=                                            -- '4C 45 E38080 50 C388 E2808B 52 45 E28090 4E 4F C38B 4C'
string2~c2x=                                            -- '4C 65 E19A80 50 C3A8 72 65 E28093 4E 6F E2808B C3AB 6C'
sleep
string1~caselessEquals(string2)=                        -- false (strict mode by default)
sleep no prompt

-- The non-strict mode applies these transformations:
string1~nfkd(casefold:, lump:, stripIgnorable:)~c2x=    -- '6C 65 20 70 65 CC80 72 65 2D 6E 6F 65 CC88 6C'
string2~nfkd(casefold:, lump:, stripIgnorable:)~c2x=    -- '6C 65 20 70 65 CC80 72 65 2D 6E 6F 65 CC88 6C'
sleep
string1~caselessEquals(string2, strict:.false)=         -- true (non-strict mode)
sleep no prompt


-- caselessMatch
-- "Bundesschnellstraße"                                    -- at 14: "s", at 18:"ß"
--  1234567890123456789
"Bundesstraße im Freiland"~caselessMatch(14, "im")=    -- .true
sleep no prompt


-- caselessMatchChar
-- "Bundesschnellstraße"                               -- at 14: "s", at 18:"ß"
--  1234567890123456789
"Bundesschnellstraße"~caselessMatchChar(18, "s")=      -- 0    "ß" becomes "ss" which is 2 characters. "s" doesn't match "ss".
sleep
"Bundesschnellstraße"~caselessMatchChar(19, "s")=      -- 0    "ß" becomes "ss" which is 2 characters. The character at 19 is "e", not the second "s"
sleep
"Bundesschnellstraße"~caselessMatchChar(19, "e")=      -- 1    "ß" becomes "ss" which is 2 characters. The character at 19 is "e", not the second "s"
sleep no prompt

-- caselessMatchChar (cont.)
-- The ligature disappears when casefolded
"baﬄe"~casefold=                                        -- T'baffle'
sleep
"BAFFLE"~caselessMatchChar(3, "ﬄ")=                     -- 0   The 3rd character "F" casefolded "f" doesn't match ""ﬄ"" casefolded "ffl"
sleep
"BAFFLE"~caselessMatchChar(5, "ﬄ")=                     -- 0   The 5th character "L" casefolded "l" doesn't match ""ﬄ"" casefolded "ffl"
sleep
"BAFFLE"~caselessMatchChar(5, "L")=                      -- 1   There is a match on "l" at 5
sleep no prompt

-- caselessMatchChar (cont.)
-- Some ligatures are not decomposed by NFKC.
"ŒUF"~caselessEquals("oeuf")=                                  -- 0
sleep
"ŒUF"~caselessEquals("oeuf", normalization:.Unicode~NFKC)=     -- 0
sleep no prompt


-- caselessPos
"Père Noël Père Noël"~caselessPos("OË")=                   -- 7
sleep
"Père Noël Père Noël"~caselessPos("OË", 8)=                -- 17
sleep
"Père Noël Père Noël"~caselessPos("OË", 8, 10)=            -- 0
sleep
"Père Noël Père Noël"~caselessPos("OE")=                   -- 0
sleep
"Père Noël Père Noël"~caselessPos("OE", stripMark:)=       -- 7
sleep
"noël👩‍👨‍👩‍👧🎅"~caselessPos("🎅")=                  -- 6
sleep
"noël👩‍👨‍👩‍👧🎅"~caselessPos("👧🎅")=               -- 0
sleep no prompt

-- caselessPos in not-aligned mode
/*
aligned=.false is intended for analysis of matchings and [non-]regression tests.
Otherwise, I don't see any use.

If aligned=.false then return a couple (array) of numbers +/-posC.posB where
posB is the position of the matched byte in the transformed haystack, and posC
is the corresponding grapheme position in the untransformed haystack.
A number is negative if the byte position is not aligned with the corresponding
character position.
The first number is the start of the matching.
The second number is the end of the matching + 1.
*/
"noël👩‍👨‍👩‍👧🎅"~caselessPos("👧🎅", aligned:.false)=   -- [-5.27,+7.35]
sleep
"noël👩‍👨‍👩‍👧🎅"~caselessPos("👩‍👨‍👩‍👧🎅", aligned:.false)=   -- [+5.6,+7.35]
sleep no prompt


-- center
"noelFC"~center(10)=; result~description=              -- forward to String
sleep
"noël👩‍👨‍👩‍👧🎅"~center(10)=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~center(9)=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~center(8)=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~center(7)=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~center(6)=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~center(5)=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~center(4)=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~center(3)=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~center(2)=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~center(1)=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~center(0)=; result~description=
sleep no prompt

-- center with pad
"="~description=                                            -- 'UTF-8 ASCII (1 byte)'
"="~c2x=                                                    -- '3D'
sleep
"noelFC"~center(10, "=")=; result~description=              -- forward to String
sleep
"═"~description=                                            -- 'UTF-8 not-ASCII (1 character, 1 codepoint, 3 bytes, 0 error)'   (was 'UTF-8 not-ASCII (3 bytes)')
sleep
"═"~description=                                            -- 'UTF-8 not-ASCII (1 character, 1 codepoint, 3 bytes, 0 error)'
sleep
"═"~c2x=                                                    -- 'E29590'
sleep
"noelFC"~center(10, "═")=; result~description=              -- don't forward to String because the pad is more than 1 byte
sleep
"noël👩‍👨‍👩‍👧🎅"~center(10, "═")=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~center(9, "═")=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~center(8, "═")=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~center(7, "═")=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~center(6, "═")=; result~description=
sleep no prompt


-- compare
"Bundesstraße im Freiland"~compare("Bundesstraße")=        -- 14
sleep
"Bundesstraße im Freiland"~compare("Bundesstraße", "_")=   -- 13
sleep
"Bundesstraße im Freiland"~compare("Bundesstrasse")=       -- 11
sleep
"Bundesstrasse im Freiland"~compare("Bundesstraße")=       -- 11
sleep
"straßssßßssse"~compare("stra", "ß")=                      --  6
sleep no prompt


-- compareTo
"pere noel"~compareTo("père noël")=                    -- -1 (lesser)
sleep
"pere noel"~compareTo("père noël", stripMark:.true)=   --  0 (equal because the accents are ignored)
sleep no prompt


-- contains
"noel"~contains("oe")=            -- forward to String
sleep
"noel"~contains("oe")=            -- forward to String
sleep
"noel"~contains("oë")=
sleep
"noel"~contains("oë")=
sleep
"noël"~contains("oe")=
sleep
"noël"~contains("oe")=
sleep
"noël"~contains("oë")=
sleep
"noël"~contains("oë")=
sleep no prompt


-- copies
"noël👩‍👨‍👩‍👧🎅"~copies(4)=; result~description=
sleep no prompt


-- endsWith
"hello"~endsWith("")=                  -- false
sleep
"hello"~endsWith("o")=                 -- true
sleep
"hello"~endsWith("ô")=                 -- false
sleep
"hello"~endsWith("ô", stripMark:)=     -- true
sleep
"noël👩‍👨‍👩‍👧🎅"~endsWith("🎅")=                -- true
sleep
"noël👩‍👨‍👩‍👧🎅"~endsWith("👧🎅")=              -- false (not aligned with a grapheme)
sleep
"noël👩‍👨‍👩‍👧🎅"~endsWith("‍👧🎅")=             -- false (not aligned with a grapheme)
sleep
"noël👩‍👨‍👩‍👧🎅"~endsWith("👩‍👧🎅")=           -- false (not aligned with a grapheme)
sleep
"noël👩‍👨‍👩‍👧🎅"~endsWith("ël👩‍👨‍👩‍👧🎅")=   -- true
sleep
"noël👩‍👨‍👩‍👧🎅"~endsWith("ËL👩‍👨‍👩‍👧🎅")=   -- false
sleep no prompt


-- equals
"ŒUF"~lower~equals("œuf")=             -- true
sleep
"ŒUF"~equals("œuf")=                   -- false (would be true if caseless)
sleep
"œuf"~equals("ŒUF")=                   -- false (would be true if caseless)
sleep
"Straße"~lower~equals("straße")=       -- true (U+00DF "LATIN SMALL LETTER SHARP S" remains unchanged since it's already a lower letter)
sleep
"Straße"~casefold~equals("strasse")=   -- true (U+00DF "LATIN SMALL LETTER SHARP S" becomes "ss" when casefolded)
sleep
"Straße"~equals("strasse")=            -- false (would be true if caseless)
sleep
"strasse"~equals("Straße")=            -- false (would be true if caseless)
sleep no prompt

-- equals (cont.) strict versus non-strict
string1 = "Le\u{IDEOGRAPHIC SPACE}Pè\u{ZERO-WIDTH-SPACE}re\u{HYPHEN}Noël"~unescape
string2 = "Le\u{OGHAM SPACE MARK}Père\u{EN DASH}No\u{ZERO-WIDTH-SPACE}ël"~unescape
sleep
string1=                                    -- T'Le　Pè​re‐Noël'
string2=                                    -- T'Le Père–No​ël'
sleep
string1~c2x=                                -- '4C 65 E38080 50 C3A8 E2808B 72 65 E28090 4E 6F C3AB 6C'
string2~c2x=                                -- '4C 65 E19A80 50 C3A8 72 65 E28093 4E 6F E2808B C3AB 6C'
sleep
string1~equals(string2)=                    -- false (strict mode by default)
sleep
-- The non-strict mode applies these transformations:
string1~nfkd(lump:, stripIgnorable:)~c2x=   -- '4C 65 20 50 65 CC80 72 65 2D 4E 6F 65 CC88 6C'
string2~nfkd(lump:, stripIgnorable:)~c2x=   -- '4C 65 20 50 65 CC80 72 65 2D 4E 6F 65 CC88 6C'
sleep
string1~equals(string2, strict:.false)=     -- true (non-strict mode)
sleep no prompt


-- hashCode
"noël👩‍👨‍👩‍👧🎅"~hashCode~class=
sleep
"noël👩‍👨‍👩‍👧🎅"~hashCode~c2x=
sleep no prompt


-- left
do i=0 to 9; "left("i") = " || "noël👩‍👨‍👩‍👧🎅"~left(i)=; end
sleep
do i=0 to 9; "left("i", ▷) = " || "noël👩‍👨‍👩‍👧🎅"~left(i, "▷")=; end
sleep no prompt


-- length
"noël👩‍👨‍👩‍👧🎅"~length=
sleep no prompt


-- lower
"LE PÈRE NOËL EST FATIGUÉ..."~lower=       -- T'le père noël est fatigué...'


-- match
"noel"~match(2, "oe")=            -- forward to String
sleep
"noel"~match(2, "oe")=            -- forward to String
sleep
"noel"~match(2, "oë")=
sleep
"noel"~match(2, "oë")=
sleep
"noël"~match(2, "oe")=
sleep
"noël"~match(2, "oe")=
sleep
"noël"~match(2, "oë")=
sleep
"noël"~match(2, "oë")=
sleep
"noël"~match(2, "oël")=
sleep
"noël"~match(2, "oël")=
sleep
"noël"~match(3, "ë")=
sleep
"noël"~match(3, "ë")=
sleep
"noël"~match(3, "ël")=
sleep
"noël"~match(3, "ël")=
sleep
"noël"~match(4, "l")=
sleep
"noël"~match(4, "l")=
sleep no prompt


-- matchChar
"noel"~matchChar(3, "Ee")=        -- forward to String
sleep
"noel"~matchChar(3, "Ee")=        -- forward to String
sleep
"noel"~matchChar(3, "EËeë")=
sleep
"noel"~matchChar(3, "EËeë")=
sleep
"noël"~matchChar(3, "EËeë")=
sleep
"noël"~matchChar(3, "EËeë")=
sleep
"noël"~matchChar(3, "EËeë")=
sleep
"noël"~matchChar(3, "Ee", stripMark:)= -- remove the accents from the tested string
sleep
"noël"~matchChar(4, "Ll")=
sleep
"noël"~matchChar(4, "Ll")=
sleep no prompt

-- matchChar (cont.)
-- "Bundesschnellstraße"                               -- at 14: "s", at 18:"ß"
--  1234567890123456789
"Bundesschnellstraße"~matchChar(14, "s")=              -- 1
sleep
"Bundesschnellstraße"~matchChar(18, "s")=              -- 0
sleep
"Bundesschnellstraße"~matchChar(18, "ß")=              -- 1
sleep no prompt

-- matchChar (cont.)
-- The ligature disappears in NFK[CD] but not in NF[CD]
"baﬄe"~matchChar(3, "f")=                               -- 0     "ﬄ" is ONE character, doesn't match "f"
sleep
"baﬄe"~matchChar(3, "ﬄ")=                              -- 1     There is a match because "ﬄ" on both sides
sleep
"baﬄe"~matchChar(3, "ﬄ", normalization:.Unicode~NFKD)= -- 1     There is a match because "ﬄ" on both sides
sleep
"baﬄe"~matchChar(3, "f", normalization:.Unicode~NFKD)=  -- 0     The 3rd character "ﬄ" becomes "ffl" (3 characters), doesn't match "f"
sleep
"baﬄe"~matchChar(4, "f", normalization:.Unicode~NFKD)=  -- 0     The 4th character is "e", doesn't match "f"
sleep
"baﬄe"~matchChar(4, "e", normalization:.Unicode~NFKD)=  -- 1     The 4th character is "e", does match "e"
sleep no prompt


-- pos
"noel"~pos("oe")=                 -- forward to String
sleep
"noel"~pos("oe")=                 -- forward to String
sleep
"noel"~pos("oë")=
sleep
"noel"~pos("oë")=
sleep
"noël"~pos("oe")=
sleep
"noël"~pos("oe")=
sleep
"noël"~pos("oë")=
sleep
"noël"~pos("oë")=
sleep
"noël"~pos("l")=
sleep
"noël"~pos("l")=
sleep
"Père Noël Père Noël"~pos("oë")=                        -- 7
sleep
"Père Noël Père Noël"~pos("oë", 8)=                     -- 17
sleep
"Père Noël Père Noël"~pos("oë", 8, 10)=                 -- 0
sleep
"Père Noël Père Noël"~pos("oe")=                        -- 0
sleep
"Père Noël Père Noël"~pos("oe", stripMark:)=            -- 7
sleep
"noël👩‍👨‍👩‍👧🎅"~pos("🎅")=                      -- 6
sleep
"noël👩‍👨‍👩‍👧🎅"~pos("👧🎅")=                    -- 0
sleep
"noël👩‍👨‍👩‍👧🎅"~pos("👧🎅", aligned:.false)=    -- [-5.27,+7.35]
sleep
"noël👩‍👨‍👩‍👧🎅"~pos("👩‍👨‍👩‍👧🎅", aligned:.false)=   -- [+5.6,+7.35]
sleep no prompt


-- reverse (correct)
"noël"~c2x=            -- '6E 6F C3AB 6C'
sleep
"noël"~reverse~c2x=    -- '6C C3AB 6F 6E'
sleep
"noël"~reverse=        -- T'lëon'
sleep no prompt

-- reverse (correct)    (was reverse (wrong) before automatic conversion of string literals to text)
"noël"~c2x=             -- '6E6FC3AB6C'
sleep
"noël"~reverse~c2x=     -- '6C C3AB 6F 6E'  (was '6CABC36F6E' before automatic conversion of string literals to text)
sleep
"noël"~reverse=         -- T'lëon'
sleep no prompt


-- right
do i=0 to 9; "right("i") = " || "noël👩‍👨‍👩‍👧🎅"~right(i)=; end
sleep
do i=0 to 9; "right("i", ▷) = " || "noël👩‍👨‍👩‍👧🎅"~right(i, "▷")=; end
sleep no prompt


-- subchar
"noël👩‍👨‍👩‍👧🎅"~subchar(3)=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~subchar(4)=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~subchar(5)=; result~description=
sleep no prompt


-- substr
"noel"~substr(3, 3, "x")=; result~description=   -- forward to String
sleep
"noel"~substr(3, 3, "▷")=; result~description=   -- T'el▷' (was: self is a String: error because the pad character is 3 bytes)
sleep
"noel"~substr(3, 3, "▷")=; result~description=   -- T'el▷' (was: self is a String: error because the pad character is 3 bytes)
sleep
"noel"~substr(3, 3, "▷")=; result~description=   -- no error because self is a RexxText and the pad character is one character when converted to the default encoding
sleep
"noël👩‍👨‍👩‍👧🎅"~substr(3, 3, "▷")=; result~description=
sleep
"noël👩‍👨‍👩‍👧🎅"~substr(3, 6, "▷")=; result~description=
sleep no prompt


-- upper
"Le père Noël est fatigué..."~upper=       -- T'LE PÈRE NOËL EST FATIGUÉ...'




-- x2c
"F09F9180"~x2c=
sleep
"not an hexadecimal value"~x2c
sleep
"not an hexadecimal value 🤔"~x2c
sleep no prompt


---------------------------------------------------------
-- Text encoding - Functional
---------------------------------------------------------

/*
The only needed methods on RexxText are
    ~characters
    ~subwords   (still to implement)
    ~chunks     (still to implement)
*/
sleep no prompt

/*
Example inspired by https://elixir-lang.org/
Frequency of each character, ignoring the accents:
"Elixir" |> String.graphemes() |> Enum.frequencies()
%{"E" => 1, "i" => 2, "l" => 1, "r" => 1, "x" => 1}
*/
sleep no prompt

"Notre père Noël 🎅"~transform(stripMark:)~reduce(by: "characters", initial: .stem~new~~put(0)){accu[item~string] += 1}=
sleep no prompt


---------------------------------------------------------
-- Text encoding - Generator
---------------------------------------------------------

/*
The only needed methods on RexxText are
    ~characters
    ~subwords   (still to implement)
*/
sleep no prompt

g="Noël 🎅"~generateC
sleep
g~()=       -- T'N'
sleep
g~()=       -- T'o'
sleep
g~()=       -- T'ë'
sleep
g~()=       -- T'l'
sleep
g~()=       -- T' '
sleep
g~()=       -- T'🎅'
sleep
g~()=       -- [no result]
sleep no prompt


---------------------------------------------------------
-- Text encoding - Compatibility with regular expressions
---------------------------------------------------------

/*
A way to test the compatibility of RexxText with String is to pass instances of
RexxText to the regular expression engine regex.cls, and see what happens...
*/
sleep no prompt

/*
Relax the constraint "self~isCompatibleWithByteString" when converting a RexxText
to a String. That allows to go further in the tests of regular expression.
*/
unckeckedConversionToString = .Unicode~unckeckedConversionToString -- backup
.Unicode~unckeckedConversionToString = .true
sleep no prompt

pB = .Pattern~compile("a.c")
pT = .Pattern~compile("a.c")
pB~matches("abc")=                              -- 1
pT~matches("abc")=                              -- 1
pB~matches("aôc")=                              -- 1    (was 0 (KO) before automatic conversion of string literals to text)
pT~matches("aôc")=                              -- 1
pB~matches("a🎅c")=                             -- 1    (was 0 (KO) before automatic conversion of string literals to text)
pT~matches("a🎅c")=                             -- 1
sleep no prompt

pB = .Pattern~compile("🤶...🎅")
pT = .Pattern~compile("🤶...🎅")
pB~matches("🤶123🎅")=                          -- 1
pT~matches("🤶123🎅")=                          -- 1
pB~matches("🤶🐕2🐈🎅")=                        -- 1    (was 0 (KO) before automatic conversion of string literals to text)
pT~matches("🤶🐕2🐈🎅")=                        -- 1
pB~matches("🤶🐕👩‍👨‍👩‍👧🐈🎅")=          -- 1    (was 0 (KO) before automatic conversion of string literals to text)
pT~matches("🤶🐕👩‍👨‍👩‍👧🐈🎅")=          -- 1
sleep no prompt

-- "🤶" or "🎅"
pB = .Pattern~compile("🤶|🎅")
pT = .Pattern~compile("🤶|🎅")
pB~startsWith("🤶🎅c")=                        -- 1
pT~startsWith("🤶🎅c")=                        -- 1
pB~startsWith("🎅🤶c")=                        -- 1
pT~startsWith("🎅🤶c")=                        -- 1
r = pB~find("xxx🤶🎅cxxx")
r~matched=; r~start=; r~end=; r=; r~length=     -- now ok (r~end was 8 and r~length was 4 before automatic conversion of string literals to text)
r = pT~find("xxx🤶🎅cxxx")
r~matched=; r~start=; r~end=; r=; r~length=
r = pB~find("xxx🎅🤶cxxx")
r~matched=; r~start=; r~end=; r=; r~length=     -- now ok (r~end was 8 and r~length was 4 before automatic conversion of string literals to text)
r = pT~find("xxx🎅🤶cxxx")
r~matched=; r~start=; r~end=; r=; r~length=
sleep no prompt

.Unicode~unckeckedConversionToString = unckeckedConversionToString -- restore


-----------------------------------------
-- Text encoding - Compatibility with BIF
-----------------------------------------

/*
The string BIFs are polymorphic on RexxString/RexxText.
If at least one positional argument is a RexxText then the BIF forwards to
RexxText, otherwise the BIF forwards to RexxString.
*/

-- Function 'center'
"═"~description=                                -- 'UTF-8 not-ASCII (1 character, 1 codepoint, 3 bytes, 0 error)'   (was 'UTF-8 not-ASCII (3 bytes)')
sleep
"═"~description=                                -- 'UTF-8 not-ASCII (1 character, 1 codepoint, 3 bytes, 0 error)'
sleep
"═"~c2x=                                        -- 'E29590'
sleep
center("hello", 20, "═")=                       -- T'═══════hello════════'
sleep
center("hello", 20, "═")~description=           -- 'UTF-8 not-ASCII (20 characters, 20 codepoints, 50 bytes, 0 error)'
sleep no prompt

-- Function 'left'
left("hello", 20, "═")=                         -- T'hello═══════════════'
sleep
left("hello", 20, "═")~description=             -- 'UTF-8 not-ASCII (20 characters, 20 codepoints, 50 bytes, 0 error)'
sleep no prompt


/*
[ABANDONNED]
Other polymorphism: route the BIF either towards String or towards RexxText,
in function of the compatibility of the arguments with String:
BIF(str1, str2, ..., strN)
    --> forward to String (byte-oriented) if str's encoding is Byte or UTF-8 (with ASCII characters only)
    --> forward to RexxText otherwise

Abandonned because we have already the polymorphism on RexxString/RexxText which
is more easy to control and to understand.
*/
sleep no prompt

-- UTF-8 encoding

"Noel"~isCompatibleWithByteString=              -- 1
sleep
length("Noel")=                                 -- 4 because "Noel"~length = 4
sleep
"Noël"~isCompatibleWithByteString=              -- 0
sleep
length("Noël")=                                 -- 4 because "Noël" is a RexxText   (was TODO: 4 because "Noël"~text~length = 4)
sleep
"Noël"~length=                                  -- 4 because "Noël" is a RexxText   (was "5 because String remains byte-oriented, not impacted by the default encoding" before automatic conversion of string literals to text)
sleep no prompt

-- UTF-16BE encoding
s = "0041004200430044"x
s=                                              -- '[00]A[00]B[00]C[00]D'
sleep
s~isCompatibleWithByteString=                   -- 1
sleep
s~description=                                  -- 'UTF-8 ASCII (8 bytes)'
sleep
length(s)=                                      -- 8 because encoding UTF-8 ASCII is compatible with String
s~encoding = "UTF16"
s~isCompatibleWithByteString=                   -- 0
sleep
s~description=                                  -- 'UTF-16BE (8 bytes)'
sleep
s~length=                                       -- 8 because String is always byte-oriented (ignores the encoding)
sleep
length(s)=                                      -- 8    (was TODO: 4 because forwards to Text (encoding UTF-16BE is not compatible with String))
sleep
s~utf8=                                         -- T'ABCD'
sleep no prompt

-- UTF-32 encoding
s = "0000004100000042"x
s=                                              -- '[000000]A[000000]B'
sleep
s~isCompatibleWithByteString=                   -- 1
sleep
s~description=                                  -- 'UTF-8 ASCII (8 bytes)'
sleep
length(s)=                                      -- 8 because encoding UTF-8 ASCII is compatible with String
s~encoding = "UTF32"
s~isCompatibleWithByteString=                   -- 0
sleep
s~description=                                  -- 'UTF-32BE (8 bytes)'
sleep
s~length=                                       -- 8 because String is always byte-oriented (ignores the encoding)
sleep
length(s)=                                      -- 8    (was TODO: 2 because forwards to Text (encoding UTF-32 is not compatible with String))
sleep
s~utf8=                                         -- T'AB'
sleep no prompt


/*
End of demonstration.
*/
demo off
