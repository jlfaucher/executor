prompt directory off
demo on

--------------------
-- Unicode libraries
--------------------

/*
The prototype is currently using 3 libraries:
- utf8proc    https://github.com/JuliaStrings/utf8proc
- ziglyph     https://github.com/jecolon/ziglyph
- icu4x       https://github.com/unicode-org/icu4x

These 3 libraries have overlapping features.
In the end, icu4x could be the only library used by Executor.

Current usage:
- utf8proc is used for grapheme segmentation, characters properties, normalization, upper/lower/title.
- ziglyph is used for upper/lower/title. Will be used for word and sentence segmentation, collation (not locale-aware).
- icu4x will be used for locale-aware services (segmentation, collation, translation, formatting).
*/
sleep no prompt


---------------------
-- Unicode characters
---------------------

-- Unicode version
.unicode~version=               -- 15.0.0

-- Unicode character names are not loaded by default
call loadUnicodeCharacterNames
.unicode~characters=            -- (an UnicodeCharacterSupplier count=43884 size=918000)
sleep no prompt

/*
Unicode character names defined by interval are not loaded by default.
The following method gives informations about these intervals.
*/
.unicode~informations=
sleep no prompt

-- Select the characters whose category is Cc (Control)
.unicode~characters~select{item~categoryName=="Cc"}==
sleep no prompt

-- Select the characters whose name contains "rex"
-- Loose matching rule UAX44-LM2, see https://unicode.org/reports/tr44/#Matching_Names
-- Spaces are ignored (among others), that's why "LETTER EXTRA" is matching "*rex*"
.unicode~characters("*rex*")==
sleep no prompt

/*
Regular expressions are supported:
    .unicode~characters("/^math.*psi$")==
returns all the characters whose name starts with "math" and ends with "psi".
*/
.unicode~characters("/^math.*psi$")==

-- longest name
.unicode~characters~reduce{if accu~name~length < item~name~length then item }=
result~name~length=
sleep no prompt

/*
Escape characters can be used in literal strings, they are unescaped at run-time.
    \u{Unicode name}    Character name in the Unicode database
    \U{Unicode name}    same as \u{Unicode name}
    \u{X..X}            Unicode character denoted by 1-8 hex digits. The first character must be a digit 0..9
    \U{X..X}            same as \u{X..X}
    \uXXXX              Unicode character denoted by 4 hex digits ('u' lowercase)
    \UXXXXXXXX          Unicode character denoted by 8 hex digits ('U' uppercase)
*/
sleep no prompt

-- Character by name
"hello\u{space}John\n"~text~unescape=                           -- T'hello John[0A]'
sleep
"The \u{t-rex} shows his \u{flexed biceps}!"~text~unescape=     -- T'The 🦖 shows his 💪!'
sleep no prompt

-- Character by codepoint
"hello\u{20}John\n"~text~unescape=                              -- T'hello John[0A]'
sleep
"hello\u0020John\n"~text~unescape=                              -- T'hello John[0A]'
sleep
"hello\U00000020John\n"~text~unescape=                          -- T'hello John[0A]'
sleep no prompt

-- Name versus codepoint
"\u{bed} is different from \u{0bed}"~text~unescape=             -- T'🛏 is different from ௭'
sleep
.unicode~character("bed")=                                      -- ( "🛏"   U+1F6CF So 1 "BED" )
sleep
.unicode~character("bed", hexadecimal:.true)=                   -- ( "௭"   U+0BED Nd 1 "TAMIL DIGIT SEVEN" )
sleep
.unicode~character("U+0bed")=                                   -- ( "௭"   U+0BED Nd 1 "TAMIL DIGIT SEVEN" )
sleep no prompt

-- High surrogate followed by low surrogate is invalid UTF-8
"\uD83D\uDE3F"~text~unescape=                                   -- T'??????'
sleep no prompt

-- High surrogate followed by low surrogate is valid WTF-8
"\uD83D\uDE3F"~text("wtf8")~unescape=                           -- T'😿'
sleep no prompt

-- \u is not supported for Byte encoding, you can use \x{X..X}
"hello\u{20}John\n"~text("byte")~unescape=                      -- Byte encoding: \u not supported.
"hello\x{20}John\n"~text("byte")~unescape=                      -- T'hello John[0A]'
sleep no prompt

-- The method unescape is available only for Byte, UTF-8 and WTF-8.
-- No implementation for UTF-16, WTF-16, UTF-32.
"hello\u{U+20}John\n"~text~utf16~unescape=                      -- Method UNESCAPE is ABSTRACT and cannot be directly invoked.
sleep no prompt


--------------------------------
-- Unicode characters properties
--------------------------------

-- Category
-- http://www.unicode.org/reports/tr44/#General_Category_Values
.unicode~codepointCategoryNames=
sleep no prompt

-- First character of each category
seen = .directory~new; .unicode~characters~each{expose seen; v = item~categoryName; if seen[v] == .nil then seen[v] = item}; seen=
sleep no prompt

-- Combining class
-- http://www.unicode.org/reports/tr44/#Canonical_Combining_Class_Values
-- Canonical combining classes are defined in the Unicode Standard as integers in the range 0...254.
-- For convenience, the standard assigns symbolic names to a subset of these combining classes.
-- First character of each combining class
seen = .directory~new; .unicode~characters~each{expose seen; v = item~combiningClass; if seen[cv] == .nil then seen[v] = item}; seen=
sleep no prompt

-- Bidirectionnal class
-- http://www.unicode.org/reports/tr44/#Bidi_Class_Values
.unicode~codepointBidiClassNames=
sleep no prompt

-- First character of each bidirectionnal class
seen = .directory~new; .unicode~characters~each{expose seen; v = item~bidiClassName; if seen[v] == .nil then seen[v] = item}; seen=
sleep no prompt

-- Bidi mirrored (boolean)
-- https://unicode.org/reports/tr9/
-- First 10 characters such as bidiMirrored == .true
.unicode~characters~pipe(.select {item~bidiMirrored} | .take 10 | .console)
sleep no prompt

-- Decomposition type
-- https://unicode.org/reports/tr15/
.unicode~codepointDecompositionTypeNames=
sleep no prompt

-- First character of each decomposition type
seen = .directory~new; .unicode~characters~each{expose seen; v = item~decompositionTypeName; if seen[v] == .nil then seen[v] = item}; seen=
sleep no prompt

-- Ignorable (boolean)
-- http://www.unicode.org/review/pr-5.html
-- http://unicode.org/L2/L2002/02368-default-ignorable.html
-- First 10 characters such as bidiMirrored == .true
.unicode~characters~pipe(.select {item~ignorable} | .take 10 | .console)
sleep no prompt

-- Boundary (boolean)
-- http://unicode.org/reports/tr29/tr29-6.html
-- First 10 characters such as bidiMirrored == .true
.unicode~characters~pipe(.select {item~controlBoundary} | .take 10 | .console)
sleep no prompt

-- Char width
-- First character of each width value
seen = .directory~new; .unicode~characters~each{expose seen; v = item~charWidth; if seen[v] == .nil then seen[v] = item}; seen=
sleep no prompt

-- Bound class
-- https://unicode.org/reports/tr29/
.unicode~codepointBoundClassNames=
sleep no prompt

-- First character of each bound class
seen = .directory~new; .unicode~characters~each{expose seen; v = item~boundClassName; if seen[v] == .nil then seen[v] = item}; seen=
sleep no prompt

-- isLower
-- Forty-first to fifthieth characters such as isLower == .true
.unicode~characters~pipe(.select {item~isLower} | .take 50 | .take "last" 10 | .console)
sleep no prompt

-- isUpper
-- Forty-first to fifthieth characters such as isUpper == .true
.unicode~characters~pipe(.select {item~isUpper} | .take 50 | .take "last" 10 | .console)
sleep no prompt

-----------------------
-- Unicode case folding
-----------------------

/*
See https://www.w3.org/TR/charmod-norm/
Case folding is the process of making two texts which differ only in case identical for comparison purposes.
*/
sleep

("sTrasse", "straße", "STRASSE")~each{item~text~casefold}==
sleep no prompt

/*
utf8proc doesn't support language-sensitive case-folding.
The Julia developers, who use utf8proc, have decided to remain locale-independent.
See https://github.com/JuliaLang/julia/issues/7848

Example:
The name of the second largest city in Turkey is "Diyarbakır", which contains both the dotted and dotless letters i.
*/
sleep

"DİYARBAKIR"~text~casefold=     -- T'di̇yarbakir'   should be diyarbakır
sleep no prompt

----------------------
-- Unicode upper lower
----------------------

/*
For one character, utf8proc and ziglyph provide different results for upper/title:
( "ß"   U+00DF Ll 1 "LATIN SMALL LETTER SHARP S" )
*/
smallSharpS = .unicode~character("LATIN SMALL LETTER SHARP S")                              --  ( "ß"   U+00DF Ll 1 "LATIN SMALL LETTER SHARP S" )
.unicode~utf8proc_codepointToUpper(smallSharpS~codepoint)~pipe{.unicode~character(item)}=   --  ( "ẞ"   U+1E9E Lu 1 "LATIN CAPITAL LETTER SHARP S" )
.Unicode~ziglyph_stringToUpper(smallSharpS~utf8~string)~text~characters=                    -- [( "ß"   U+00DF Ll 1 "LATIN SMALL LETTER SHARP S" )]
sleep no prompt

/*
Both are wrong, should be "SS".
Unicode standard 15 section 5.18 Case Mappings:
    Default casing                                         Tailored casing
    (small sharp) ß <--- ß (capital sharp)                 (small sharp) ß <--> ẞ (capital sharp)
    (small sharp) ß ---> SS
                 ss <--> SS                                             ss <--> SS
When using the default Unicode casing operations, capital sharp s will lowercase
to small sharp s, but not vice versa: small sharp s uppercases to “SS”.
A tailored casing operation is needed in circumstances requiring small sharp s
to uppercase to capital sharp s.
*/

/*
For some characters, utf8proc and ziglyph provide the same wrong results for upper/lower
TODO: plug ICU4X and see if the result is ok with Locale “Turkish (Turkey)” (tr_TR)
*/
sleep no prompt

"Diyarbakır"~text~upper=                            -- T'DIYARBAKIR'   should be DİYARBAKIR
.Unicode~ziglyph_stringToUpper("Diyarbakır")=       --  'DIYARBAKIR'
"DİYARBAKIR"~text~casefold=                         -- T'di̇yarbakir'   should be diyarbakır
.Unicode~ziglyph_stringToCaseFold("DİYARBAKIR")=    --  'di̇yarbakir'
"DİYARBAKIR"~text~lower=                            -- T'diyarbakir'
.Unicode~ziglyph_stringToLower("DİYARBAKIR")=       --  'diyarbakir'


--------------------------
-- Unicode transformations
--------------------------

/*
Method .Unicode~utf8proc_transform
The purpose of this method is to support all the transformations provided by utf8proc.
Takes a byte string as input (UTF-8 encoded), returns a new transformed byte string as output (UTF-8).

TODO: Add support for UTF-16, UTF-32
*/
sleep no prompt

string = "\u{BEL}Le\u{IDEOGRAPHIC SPACE}\u{OGHAM SPACE MARK}\u{ZERO-WIDTH-SPACE}Père\t\u{HYPHEN}\u{SOFT-HYPHEN}\u{EN DASH}\u{EM DASH}Noël\x{EFB790}\r\n"
text = string~text~unescape
text~characters==
sleep no prompt

/*
Possible transformations:

 1  : ( ""    U+0007 Cc 0 "", "ALERT", "BEL" )                      <-- removable with STRIPCC:.true
 2  : ( "L"   U+004C Lu 1 "LATIN CAPITAL LETTER L" )
 3  : ( "e"   U+0065 Ll 1 "LATIN SMALL LETTER E" )
 4  : ( "　"  U+3000 Zs 2 "IDEOGRAPHIC SPACE" )                     <-- replaceable by " " with LUMP:.true
 5  : ( " "   U+1680 Zs 1 "OGHAM SPACE MARK" )                      <-- replaceable by " " with LUMP:.true
 6  : ( "​"    U+200B Cf 0 "ZERO WIDTH SPACE", "ZWSP" )              <-- removable by STRIPIGNORABLE:.TRUE
 7  : ( "P"   U+0050 Lu 1 "LATIN CAPITAL LETTER P" )
 8  : ( "è"   U+00E8 Ll 1 "LATIN SMALL LETTER E WITH GRAVE" )       <-- replaceable by "e" with normalization + STRIPMARK:.true
 9  : ( "r"   U+0072 Ll 1 "LATIN SMALL LETTER R" )
 10 : ( "e"   U+0065 Ll 1 "LATIN SMALL LETTER E" )
 11 : ( ""    U+0009 Cc 0 "", "CHARACTER TABULATION" )              <-- replaceable by " " with STRIPCC:.true
 12 : ( "‐"   U+2010 Pd 1 "HYPHEN" )                                <-- replaceable by "-" with LUMP:.true
 13 : ( "­"   U+00AD Cf 1 "SOFT HYPHEN", "SHY" )                    <-- removable by STRIPIGNORABLE:.true
 14 : ( "–"   U+2013 Pd 1 "EN DASH" )                               <-- replaceable by "-" with LUMP:.true
 15 : ( "—"   U+2014 Pd 1 "EM DASH" )                               <-- replaceable by "-" with LUMP:.true
 16 : ( "N"   U+004E Lu 1 "LATIN CAPITAL LETTER N" )
 17 : ( "o"   U+006F Ll 1 "LATIN SMALL LETTER O" )
 18 : ( "ë"   U+00EB Ll 1 "LATIN SMALL LETTER E WITH DIAERESIS" )   <-- replaceable by "e" with normalization + STRIPMARK:.true
 19 : ( "l"   U+006C Ll 1 "LATIN SMALL LETTER L" )
 20 : ( "﷐"   U+FDD0 Cn 1 "" )                                     <-- removeable with STRIPNA:.true
 21 : ( ""    U+000D Cc 0 "", "CARRIAGE RETURN", "CR" )
 22 : ( ""    U+000A Cc 0 "", "LINE FEED" )                         <-- CR+LF replaceable by " " with STRIPCC:.true
*/
sleep 10 no prompt

text=                                                               -- T'[07]Le　 ​Père[09]‐­–—Noël﷐[0D0A]'
sleep no prompt

-- Performs unicode case folding, to be able to do a case-insensitive string comparison.
.Unicode~utf8proc_transform(text~string, casefold:.true)=           --  '[07]le　 ​père[09]‐­–—noël﷐[0D0A]'
sleep no prompt

-- Strip "default ignorable characters" such as SOFT-HYPHEN or ZERO-WIDTH-SPACE
.Unicode~utf8proc_transform(text~string, stripIgnorable:.true)=     --  '[07]Le　 Père[09]‐–—Noël﷐[0D0A]'
sleep no prompt

-- Lumps certain characters together. See lump.md for details:
-- https://github.com/JuliaStrings/utf8proc/blob/master/lump.md
-- E.g. HYPHEN U+2010 and MINUS U+2212 to ASCII "-"
-- jlf: I was expecting to have only one space and one "-" but that's not the case
-- Seems working as designed...
-- All the concerned characters become the same character, but still remain distinct characters.
.Unicode~utf8proc_transform(text~string, lump:.true)=               --  '[07]Le  ​Père[09]-­--Noël﷐[0D0A]'
sleep no prompt

-- NLF2LF: Convert LF, CRLF, CR and NEL into LF
.Unicode~utf8proc_transform(text~string, NLF:1)=                    --  '[07]Le　 ​Père[09]‐­–—Noël﷐[0A]'
sleep no prompt

-- NLF2LS: Convert LF, CRLF, CR and NEL into LS (U+2028 Zl 0 "LINE SEPARATOR")
.Unicode~utf8proc_transform(text~string, NLF:2)=                    --  '[07]Le　 ​Père[09]‐­–—Noël﷐'
sleep no prompt

-- NLF2PS: convert LF, CRLF, CR and NEL into PS (U+2029 Zp 0 "PARAGRAPH SEPARATOR")
.Unicode~utf8proc_transform(text~string, NLF:3)=                    --  '[07]Le　 ​Père[09]‐­–—Noël﷐ '
sleep no prompt

-- Strips and/or converts control characters.
.Unicode~utf8proc_transform(text~string, stripCC:.true)=            --  'Le　 ​Père ‐­–—Noël﷐ '
sleep no prompt

-- Strips all character markings.
-- This includes non-spacing, spacing and enclosing (i.e. accents).
-- This option works only with normalization.
.Unicode~utf8proc_transform(text~string, stripMark:.true, normalization:1)=  --  '[07]Le　 ​Pere[09]‐­–—Noel﷐[0D0A]'
sleep no prompt

-- Strips unassigned codepoints.
.Unicode~utf8proc_transform(text~string, stripNA:.true)=            --  '[07]Le　 ​Père[09]‐­–—Noël[0D0A]'
sleep no prompt

-- Application of several options (abbreviated names)
.Unicode~utf8proc_transform(text~string, casef:.true, lump:.true, norm:1, stripi:.true, stripc:.true, stripm:.true, stripn:.true)= --  'le  pere ---noel '
sleep no prompt

/*
Some comments about the transformations:

 1  : ( "l"   U+006C Ll 1 "LATIN SMALL LETTER L" )
 2  : ( "e"   U+0065 Ll 1 "LATIN SMALL LETTER E" )
 3  : ( " "   U+0020 Zs 1 "SPACE", "SP" )               <-- LUMP (was IDEOGRAPHIC SPACE)
 4  : ( " "   U+0020 Zs 1 "SPACE", "SP" )               <-- LUMP (was OGHAM SPACE MARK)
 5  : ( "p"   U+0070 Ll 1 "LATIN SMALL LETTER P" )
 6  : ( "e"   U+0065 Ll 1 "LATIN SMALL LETTER E" )
 7  : ( "r"   U+0072 Ll 1 "LATIN SMALL LETTER R" )
 8  : ( "e"   U+0065 Ll 1 "LATIN SMALL LETTER E" )
 9  : ( " "   U+0020 Zs 1 "SPACE", "SP" )               <-- STRIPCC (was TAB)
 10 : ( "-"   U+002D Pd 1 "HYPHEN-MINUS" )              <-- LUMP (was HYPHEN)
 11 : ( "-"   U+002D Pd 1 "HYPHEN-MINUS" )              <-- LUMP (was EN DASH)
 12 : ( "-"   U+002D Pd 1 "HYPHEN-MINUS" )              <-- LUMP (was EM DASH)
 13 : ( "n"   U+006E Ll 1 "LATIN SMALL LETTER N" )
 14 : ( "o"   U+006F Ll 1 "LATIN SMALL LETTER O" )
 15 : ( "e"   U+0065 Ll 1 "LATIN SMALL LETTER E" )
 16 : ( "l"   U+006C Ll 1 "LATIN SMALL LETTER L" )
 17 : ( " "   U+0020 Zs 1 "SPACE", "SP" )               <-- STRIPCC (was CR+LF)
*/
sleep 10 no prompt


-------------------------
-- Unicode normalizations
-------------------------

/*
Normalization NFC, NFD, NFKC, NFKD.
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
sleep no prompt

"only ASCII"~text~isNFC=                        -- 1
"only ASCII"~text~isNFD=                        -- 1
"only ASCII"~text~isNFKC=                       -- 1
"only ASCII"~text~isNFKD=                       -- 1
sleep
text = "Noël"~text
text~isNFC=                                     -- -1
text~isNFD=                                     -- -1
sleep
textNFC = text~NFC
textNFD = text~NFD
text~isNFC=                                     -- 1
text~isNFD=                                     -- 0
textNFC~isNFC=                                  -- 1
textNFD~isNFD=                                  -- 1
sleep no prompt

/*
The normalized text can be memorized on the original text:
    text = "père Noël"~text
    textNFD = text~nfd(memorize:.true)      -- abbreviation mem:.true
From now, the returned NFD is always the memorized text:
    text~nfd == textNFD                     -- .true
*/
sleep no prompt

text = xrange("0", "FF"x)~text("cp1252")~utf8(strict: .false)
text=
text~isNFD=
sleep
infos next
do 500; textNFD = text~NFD; end
sleep
infos next
do 500; textNFD = text~NFD(mem: .true); end
sleep no prompt
text~nfd~"==":.object( textNFD)=                -- 1 (this is really the same object)

/*
Some remarks about the string used in the next demo:
- the first "äöü" is NFC, the second "äöü" is NFD
- "x̂" is two codepoints in any normalization.
- "ϔ" normalization forms are all different.
- "ﷺ" is one of the worst cases regarding the expansion factor in NFKS/NFKS: 18x
- "baﬄe"~text~subchar(3)=     -- T'ﬄ'
  "baﬄe"~text~upper=          -- T'BAﬄE', not BAFFLE
  The ligature disappears in NFK[CD] but not in NF[CD]
*/
sleep no prompt

"äöü äöü x̂ ϔ ﷺ baﬄe"~text~characters==
sleep
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~description=      -- 'UTF-8 not-ASCII (18 graphemes, 22 codepoints, 34 bytes, 0 error)'
sleep
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~upper=            -- T'ÄÖÜ ÄÖÜ X̂ ϔ ﷺ BAﬄE
sleep no prompt

/*
NFD
Normalization Form D
Canonical Decomposition
Characters are decomposed by canonical equivalence, and multiple combining characters are arranged in a specific order.
*/
sleep no prompt

"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfd~characters==
sleep
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfd~description=  -- 'UTF-8 not-ASCII (18 graphemes, 26 codepoints, 39 bytes, 0 error)'
sleep
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfd~upper=        -- T'ÄÖÜ ÄÖÜ X̂ ϔ ﷺ BAﬄE'
sleep no prompt

/*
NFC
Normalization Form C
Canonical Decomposition, followed by Canonical Composition
Characters are decomposed and then recomposed by canonical equivalence.
*/
sleep no prompt

"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfc~characters==
sleep
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfc~description=  -- 'UTF-8 not-ASCII (18 graphemes, 19 codepoints, 31 bytes, 0 error)'
sleep
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfc~upper=        -- T'ÄÖÜ ÄÖÜ X̂ ϔ ﷺ BAﬄE'
sleep no prompt

/*
NFKD
Normalization Form KD
Compatibility Decomposition (K is used to stand for compatibility to avoid confusion with the C standing for composition)
Characters are decomposed by compatibility, and multiple combining characters are arranged in a specific order.
*/
sleep no prompt

"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfkd~characters==
sleep
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfkd~description= -- 'UTF-8 not-ASCII (37 graphemes, 45 codepoints, 69 bytes, 0 error)'
sleep
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfkd~upper=       -- T'ÄÖÜ ÄÖÜ X̂ Ϋ صلى الله عليه وسلم BAFFLE
sleep no prompt

/*
NFKC
Normalization Form KC
Compatibility Decomposition, followed by Canonical Composition
Characters are decomposed by compatibility, then recomposed by canonical equivalence.
*/
sleep no prompt

"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfkc~characters==
sleep
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfkc~description= -- 'UTF-8 not-ASCII (37 graphemes, 38 codepoints, 61 bytes, 0 error)'
sleep
"äöü äöü x̂ ϔ ﷺ baﬄe"~text~nfkc~upper=       -- T'ÄÖÜ ÄÖÜ X̂ Ϋ صلى الله عليه وسلم BAFFLE'
sleep no prompt

-- The normalization forms are implemented only for UTF-8 and WTF-8.
"D800 DC01"x~text("utf16")~nfd~characters==    -- Method NFD is ABSTRACT and cannot be directly invoked.
sleep
"D800 DC01"x~text("utf16")~utf8~nfd~characters==
sleep
"\uD800\uDC01"~text("wtf8")~unescape~nfd~characters==
sleep no prompt


/*
End of demonstration.
*/
prompt directory on
demo off
