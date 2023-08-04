prompt off directory
demo on

----------------
-- Text encoding
----------------

/*
Start working on a prototype for encoded strings.

Main ideas explored with this prototype :
- The existing String class is kept unchanged, but its semantic becomes : "byte-oriented".
- The prototype adds a layer of services working at grapheme level, provided by the RexxText class.
- The RexxText class works on the bytes managed by the String class.
- String instances are immutable, the same for RexxText instances.
- No automatic conversion to Unicode by the interpreter.
- The strings crossing the I/O barriers are kept unchanged.
- Supported encodings : byte, UTF-8, UTF-16, UTF-32.
*/
sleep 15 no prompt

/*
On my Mac, where locale returns :
LANG=""
LC_COLLATE="en_US.UTF-8"
LC_CTYPE="en_US.UTF-8"
LC_MESSAGES="en_US.UTF-8"
LC_MONETARY="en_US.UTF-8"
LC_NUMERIC="en_US.UTF-8"
LC_TIME="en_US.UTF-8"
LC_ALL="en_US.UTF-8"

I get that under ooRexxShell :
*/
sleep
s1 = "é"
s1=                                 -- 'é'
sleep
s1~length=                          -- 2
sleep
s1~c2x=                             -- C3 A9
sleep
combining_acute_accent = "cc81"x
s2 = "e" || combining_acute_accent
sleep
s2=                                 -- 'é'
sleep
s2~length=                          -- 3
sleep
s2~c2x=                             -- 65 CC 81
sleep no prompt

/*
My goal :
s1~text~length=                     -- 1 grapheme
s1~text~codepoints~count=           -- 1 codepoint
s1~text~string~length=              -- 2 bytes

s2~text~length=                     -- 1 grapheme
s2~text~codepoints~count=           -- 2 codepoints
s2~text~string~length=              -- 3 bytes
*/
sleep
.encoding~defaultEncoding = "utf8"
s1~text~length=                     -- 1 grapheme
sleep
s1~text~codepoints~count=           -- 1 codepoint
sleep
s1~text~string~length=              -- 2 bytes

s2~text~length=                     -- 1 grapheme
sleep
s2~text~codepoints~count=           -- 2 codepoints
sleep
s2~text~string~length=              -- 3 bytes
sleep no prompt

/*
A String is linked to a RexxText, which itself is linked to this String:

    a String
     ▲  text --------> a RexxText
     │                     indexer (anEncoding)
     │                          codepoints (sequential access)
     │                          characters (direct access to graphemes)
     +-<---------------------<- string

The ooRexx programmer has the choice :
- working with String at byte level
- working with RexxText at grapheme level.
- the same instance of String is used in both cases.
*/
sleep
myText = "où as tu e" || .Unicode~character("combining acute accent")~utf8 || "té ?"
myText=                         -- T'où as tu été ?'
sleep
myString = myText~string
myString=                       -- 'où as tu été ?'
sleep
myString~length=                -- 18
sleep
myText~length=                  -- 14
sleep 2 no prompt

/*
                                -- 1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18
myString                        -- 6F C3 B9 20 61 73 20 74 75 20 65 CC 81 74 C3 A9 20 3F
                                -- o. ù....  . a. s.  . t. u.  . e. acute t. é....  . ?.
*/
sleep
myString~eachC("c2x")=
sleep 5 no prompt

/*
                                -- 1  2     3  4  5  6  7  8  9  10       11 12    13 14
myText                          -- 6F C3B9  20 61 73 20 74 75 20 65 CC81  74 C3A9  20 3F
                                -- o. ù...   . a. s.  . t. u.  . e. acut  t. é...   . ?.
*/
sleep
myText~graphemes~each("c2x")=
sleep 5 no prompt

/*
CR+LF is a grapheme made of 2 codepoints.
LF+CR are 2 graphemes.
*/
sleep
"0D0A"x~text~description=
sleep
"0A0D"x~text~description=
sleep 2 no prompt

/*
More examples of encoded string
*/
sleep
"( ͡° ͜ʖ﻿ ͡°)"~text~description=
sleep
"( ͡° ͜ʖ﻿ ͡°)"~text~characters~each("c2x")=
sleep
"( ͡° ͜ʖ﻿ ͡°)"~text~codepoints~each{"U+"item~d2x}=
sleep
"(ノಠ益ಠ)ノ彡"~text~description=
sleep
"(ノಠ益ಠ)ノ彡"~text~characters~each("c2x")=
sleep
"(ノಠ益ಠ)ノ彡"~text~codepoints~each{"U+"item~d2x}=
sleep 5 no prompt

/*
U+FE0E VARIATION SELECTOR-15 (UTF-8: EF B8 8E)
https://codepoints.net/U+fe0e
This codepoint may change the appearance of the preceding character.
If that is a symbol, dingbat or emoji, U+FE0E forces it to be rendered in a
textual fashion as compared to a colorful image.

U+FE0F VARIATION SELECTOR-16 (UTF-8: EF B8 8F)
https://codepoints.net/U+fe0f
This codepoint may change the appearance of the preceding character.
If that is a symbol, dingbat or emoji, U+FE0F forces it to be rendered as a
colorful image as compared to a monochrome text variant.
In theory ❤ and ❄ (and many other emoji) should display as text style by default
without VS16, but many applications ignore that.
*/
sleep
emoji_bag = .bag~of('❤', '❤️', '❄', '❄︎', '❄️', '⚪', '⚪️', '⚫', '⚫️')
emoji_table = emoji_bag~table~map("text")
emoji_table~map("c2x")==
sleep
emoji_table~map("c2u")==
sleep no prompt
/*
The tables above are not well aligned
because the alignement is based on the length of the indexes,
which is (for the moment) a count of bytes, not a count of graphemes...
*/
sleep 9 no prompt

/*
https://www.reddit.com/r/cpp/comments/aqzu7i
👩‍👨‍👩‍👧‍👦‍👧‍👧‍👦
is one grapheme, made up of 15 codepoints
*/
sleep
family = "👩‍👨‍👩‍👧‍👦‍👧‍👧‍👦"
family=
family~text~description=                              -- 1 character, 15 codepoints, 53 bytes
sleep
family~text~c2x=
sleep
family~text~c2u=
sleep
family~text~c2g=
sleep 5 no prompt

/*
https://onlineunicodetools.com/generate-zalgo-unicode
Uses Unicode combining characters to create symbol noise.
"hello" zalgoified:
h̵᷊̟͉͔̟̲͆e̷͇̼͉̲̾l̸̨͓̭̗᷿︣︠ͦl̶̯̻̑̈ͮ͌︡̕o̵̝̬̯᷊̭̯̦᷃ͪ̆́᷈́͜͢͞
*/
sleep
helloZalgo = "h̵᷊̟͉͔̟̲͆e̷͇̼͉̲̾l̸̨͓̭̗᷿︣︠ͦl̶̯̻̑̈ͮ͌︡̕o̵̝̬̯᷊̭̯̦᷃ͪ̆́᷈́͜͢͞"
helloZalgo =
helloZalgo~text~description=                          -- 5 characters, 54 codepoints, 111 bytes
sleep
helloZalgo~text~c2x=
sleep
helloZalgo~text~c2u=
sleep
helloZalgo~text~c2g=
sleep 5 no prompt

/*
Supported encoding conversions:
Byte to UTF-8, UTF-16, UTF-32
UTF-8 to UTF-16, UTF-32
UTF-16 to UTF-8, UTF-32
UTF-32 to UTF-8, UTF-16
*/
sleep no prompt

/*
The Byte_Encoding can be specialized to add support for specific encoding conversions.
*/
sleep
.Encoding~list~table==
sleep 10 no prompt

/*
Example: CP1252 to UTF-8 (where CP1252 is an alias of Windows-1252)
"Un œuf de chez MaPoule™ coûte ±0.40€"
*/
sleep
str_cp1252 = "Un " || "9C"x || "uf de chez MaPoule" || "99"x || " co" || "FB"x || "te " || "B1"x || "0.40" || "80"x
txt_cp1252 = str_cp1252~text("cp1252")
txt_cp1252~description=
sleep
txt_cp1252~c2x=
sleep
txt_utf8 = txt_cp1252~utf8
txt_utf8=
txt_utf8~description=
sleep
txt_utf8~c2x=
sleep 5 no prompt

/*
Strings of codepoints encoded as native integers.
3 representations:
    Unicode8_Encoding
    Unicode16_Encoding
    Unicode32_Encoding.
The method ~unicode returns one of these encodings, depending on the character
with the largest Unicode codepoint (1, 2, or 4 bytes) in the source string.
Unlike the flexible representation of Python, the 3 representions are first-class.
No BOM, the endiannes is the CPU one.
Unicode32_Encoding can be used with utf8proc for the functions taking a buffer of 32-bit integers.
*/
sleep no prompt

-- Just an interpretative layer put above the string
"côté"~text("unicode8")~pipe{item~description(s:1) ":" item~c2x}=
sleep no prompt

-- UTF-8 converted to Unicode8
"côté"~text~unicode~pipe{item~description(s:1) ":" item~c2x}=
sleep
"noël‍👨‍👩‍👧"~text~maximumCodepoint~pipe{"U+"item~d2x}=   -- U+1F469 is the maximum codepoint
"noël‍👨‍👩‍👧"~text~unicode~description(t:1)=              -- For this maximum codepoint, we need Unicode32
sleep no prompt

-- The endianness of the UnicodeN_Encoding is the one of the machine.
-- With an Intel CPU, it's little-endian.
"noël‍👨‍👩‍👧"~text~unicode~c2x=
sleep no prompt

-- The default endianness for UTF32 is big-endian.
"noël‍👨‍👩‍👧"~text~utf32~c2x=
sleep no prompt

/*
Comparing the size of UTF-8 vs UTF-16 vs UTF-32 for various strings.
These strings are initially UTF-8 encoded.
The first step is to get a wrapper RexxText (default encoding is UTF-8).
The second step is to convert to UTF-16 or UTF-32.
The description includes technical informations (t:1) about the internal tables for indexation.
*/
sleep
howMuchOfStorage = "how much of storage?"
howMuchOfStorage~text~description(t:1)=         -- UTF-8:     20 characters, 20 codepoints,  20 bytes
sleep
howMuchOfStorage~text~utf16~description(t:1)=   -- UTF-16:    20 characters, 20 codepoints,  40 bytes
sleep
howMuchOfStorage~text~utf32~description(t:1)=   -- UTF-32:    20 characters, 20 codepoints,  80 bytes
sleep
howMuchOfStorage~text~unicode~description(t:1)= -- Unicode8:  20 characters, 20 codepoints,  20 bytes
sleep
rexCharacters = "'rex' in their name: ꎅ ꎜ ꏑ 🦖"
rexCharacters~text~description(t:1)=            -- UTF-8:     28 characters, 28 codepoints,  37 bytes
sleep
rexCharacters~text~utf16~description(t:1)=      -- UTF-16:    28 characters, 28 codepoints,  58 bytes
sleep
rexCharacters~text~utf32~description(t:1)=      -- UTF-32:    28 characters, 28 codepoints, 112 bytes
sleep
rexCharacters~text~unicode~description(t:1)=    -- Unicode32: 28 characters, 28 codepoints, 112 bytes
sleep
family = "👩‍👨‍👩‍👧‍👦‍👧‍👧‍👦"
family~text~description(t:1)=                   -- UTF-8:      1 character,  15 codepoints,  53 bytes
sleep
family~text~utf16~description(t:1)=             -- UTF-16:     1 character,  15 codepoints,  46 bytes
sleep
family~text~utf32~description(t:1)=             -- UTF-32:     1 character,  15 codepoints,  60 bytes
sleep
family~text~unicode~description(t:1)=           -- Unicode32:  1 character,  15 codepoints,  60 byte
sleep
helloZalgo = "h̵᷊̟͉͔̟̲͆e̷͇̼͉̲̾l̸̨͓̭̗᷿︣︠ͦl̶̯̻̑̈ͮ͌︡̕o̵̝̬̯᷊̭̯̦᷃ͪ̆́᷈́͜͢͞"
helloZalgo~text~description(t:1)=               -- UTF-8:      5 characters, 54 codepoints, 111 bytes
sleep
helloZalgo~text~utf16~description(t:1)=         -- UTF-16:     5 characters, 54 codepoints, 108 bytes
sleep
helloZalgo~text~utf32~description(t:1)=         -- UTF-32:     5 characters, 54 codepoints, 216 bytes
sleep
helloZalgo~text~unicode~description(t:1)=       -- Unicode16:  5 characters, 54 codepoints, 108 bytes
sleep no prompt


/*
It's possible to set/get an encoding on a String or a MutableBuffer
without having an associated RexxText.
It's just an annotation, there is no indexing.
*/
sleep no prompt

s = "nonsense"
s~encoding =                    -- returns the default encoding: (The UTF8_Encoding class)
sleep
s~hasText =                     -- 0
sleep
s~encoding = .UTF16BE_Encoding  -- tag the string: encoded UTF-16BE
s~encoding =                    -- (The UTF16BE_Encoding class)
sleep
s~hasText =                     -- still no associated RexxText: 0
sleep
t = s~text                      -- associates a RexxText to the string
s~hasText =                     -- the string has an associated text: 1
sleep
t~encoding =                    -- the encoding of the text is the one of the string: (The UTF16BE_Encoding class)
sleep no prompt

-- Changing the encoding of a String/RexxText has no impact on the byte sequence.
s=                              -- "nonsense"
sleep
t~string=                       -- "nonsense"
sleep no prompt

-- The impact of the encoding annotation is on the decoding of the byte sequence.
-- The english word "nonsense" in UTF-8 becomes the chinese word "soup" when interpreted as UTF-16BE and converted to UTF-8.
sleep
t~utf8 =                        -- T'湯湳敮獥'      soup
sleep no prompt

-- Setting/getting the encoding of the string will set/get the encoding of the associated RexxText
sleep
s~encoding = .UTF16LE_Encoding
t~encoding =                    -- the encoding of the text has been changed: (The UTF16LE_Encoding class)
sleep

-- The english word "nonsense" in UTF-8 becomes the chinese word "tide" when interpreted as UTF-16LE and converted to UTF-8.
sleep
t~utf8 =                        -- T'潮獮湥敳'      tide
sleep no prompt


/*
End of demonstration.
*/
demo off
