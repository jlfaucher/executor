prompt directory off
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
sleep 10 no prompt

/*
On my Mac, where locale returns :
*/
sleep
"locale"
sleep no prompt

/*
I get that under ooRexxShell :
*/
s1 = "é"
s1=                                 -- 'é'
s1~length=                          -- 2
s1~c2x=                             -- C3 A9
combining_acute_accent = "cc81"x
s2 = "e" || combining_acute_accent
s2=                                 -- 'é'
s2~length=                          -- 3
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
s1~text~codepoints~count=           -- 1 codepoint
s1~text~string~length=              -- 2 bytes

s2~text~length=                     -- 1 grapheme
s2~text~codepoints~count=           -- 2 codepoints
s2~text~string~length=              -- 3 bytes
sleep no prompt

/*
A String is linked to a RexxText, which itself is linked to this String:

    a String
     ▲  text --------⮸ a RexxText
     │                     indexer (anEncoding)
     │                          codepoints (sequential access)
     │                          graphemes  (direct access)
     +-----------------------⮷- string

The ooRexx programmer has the choice :
- working with String at byte level
- working with RexxText at grapheme level.
- the same instance of String is used in both cases.
*/
sleep
myText = "où as tu e" || .Unicode~character("combining acute accent")~utf8 || "té ?"
myText=                         -- T'où as tu été ?'
myString = myText~string
myString=                       -- 'où as tu été ?'
myString~length=                -- 18
myText~length=                  -- 14
sleep no prompt

/*
                                -- 1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18
myString                        -- 6F C3 B9 20 61 73 20 74 75 20 65 CC 81 74 C3 A9 20 3F
                                -- o. ù....  . a. s.  . t. u.  . e. acute t. é....  . ?.
*/
sleep
myString~eachC("c2x")=
sleep no prompt

/*
                                -- 1  2     3  4  5  6  7  8  9  10       11 12    13 14
myText                          -- 6F C3B9  20 61 73 20 74 75 20 65 CC81  74 C3A9  20 3F
                                -- o. ù...   . a. s.  . t. u.  . e. acut  t. é...   . ?.
*/
sleep
myText~graphemes~each("c2x")=
sleep no prompt

/*
CR+LF is a grapheme made of 2 codepoints.
LF+CR are 2 graphemes.
*/
sleep
"0D0A"x~text~description=
"0A0D"x~text~description=
sleep no prompt

/*
More examples of encoded string
*/
sleep
"( ͡° ͜ʖ﻿ ͡°)"~text~description=
"( ͡° ͜ʖ﻿ ͡°)"~text~graphemes~each("c2x")=
"( ͡° ͜ʖ﻿ ͡°)"~text~codepoints~each{"U+"item~d2x}=
"(ノಠ益ಠ)ノ彡"~text~description=
"(ノಠ益ಠ)ノ彡"~text~graphemes~each("c2x")=
"(ノಠ益ಠ)ノ彡"~text~codepoints~each{"U+"item~d2x}=
sleep no prompt

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
emoji_table~map("c2u")==
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
family~text~description=                              -- 1 grapheme, 15 codepoints, 53 bytes
family~text~c2x=
family~text~c2u=
family~text~c2g=
sleep no prompt

/*
https://onlineunicodetools.com/generate-zalgo-unicode
Uses Unicode combining characters to create symbol noise.
"hello" zalgoified:
h̵᷊̟͉͔̟̲͆e̷͇̼͉̲̾l̸̨͓̭̗᷿︣︠ͦl̶̯̻̑̈ͮ͌︡̕o̵̝̬̯᷊̭̯̦᷃ͪ̆́᷈́͜͢͞
*/
sleep
helloZalgo = "h̵᷊̟͉͔̟̲͆e̷͇̼͉̲̾l̸̨͓̭̗᷿︣︠ͦl̶̯̻̑̈ͮ͌︡̕o̵̝̬̯᷊̭̯̦᷃ͪ̆́᷈́͜͢͞"
helloZalgo =
helloZalgo~text~description=                          -- 5 graphemes, 54 codepoints, 111 bytes
helloZalgo~text~c2x=
helloZalgo~text~c2u=
helloZalgo~text~c2g=
sleep no prompt

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
.Encoding~supported~table==
sleep no prompt

/*
Example: CP1252 to UTF-8
"Un œuf de chez MaPoule™ coûte ±0.40€"
*/
sleep
str_cp1252 = "Un " || "9C"x || "uf de chez MaPoule" || "99"x || " co" || "FB"x || "te " || "B1"x || "0.40" || "80"x
txt_cp1252 = str_cp1252~text("cp1252")
txt_cp1252~description=
txt_cp1252~c2x=
txt_utf8 = txt_cp1252~utf8
txt_utf8=
txt_utf8~description=
txt_utf8~c2x=
sleep no prompt

/*
Strings of codepoints encoded as native integers.
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
sleep no prompt

-- Just an interpretative layer put above the string
"côté"~text("unicode8")~pipe{item~description(s:1) ":" item~c2x}=
-- UTF-8 converted to Unicode8
"côté"~text~unicode~pipe{item~description(s:1) ":" item~c2x}=
"noël‍👨‍👩‍👧"~text~maximumCodepoint~pipe{"U+"item~d2x}=   -- U+1F469 is the maximum codepoint
"noël‍👨‍👩‍👧"~text~unicode~description(t:1)=              -- For this maximum codepoint, we need Unicode32
-- The endianness of the UnicodeN_Encoding is the one of the machine.
-- With an Intel CPU, it's little-endian.
"noël‍👨‍👩‍👧"~text~unicode~c2x=
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
howMuchOfStorage~text~description(t:1)=         -- UTF-8:     20 graphemes, 20 codepoints,  20 bytes
howMuchOfStorage~text~utf16~description(t:1)=   -- UTF-16:    20 graphemes, 20 codepoints,  40 bytes
howMuchOfStorage~text~utf32~description(t:1)=   -- UTF-32:    20 graphemes, 20 codepoints,  80 bytes
howMuchOfStorage~text~unicode~description(t:1)= -- Unicode8:  20 graphemes, 20 codepoints,  20 bytes
rexCharacters = "'rex' in their name: ꎅ ꎜ ꏑ 🦖"
rexCharacters~text~description(t:1)=            -- UTF-8:     28 graphemes, 28 codepoints,  37 bytes
rexCharacters~text~utf16~description(t:1)=      -- UTF-16:    28 graphemes, 28 codepoints,  58 bytes
rexCharacters~text~utf32~description(t:1)=      -- UTF-32:    28 graphemes, 28 codepoints, 112 bytes
rexCharacters~text~unicode~description(t:1)=    -- Unicode32: 28 graphemes, 28 codepoints, 112 bytes
family = "👩‍👨‍👩‍👧‍👦‍👧‍👧‍👦"
family~text~description(t:1)=                   -- UTF-8:      1 grapheme,  15 codepoints,  53 bytes
family~text~utf16~description(t:1)=             -- UTF-16:     1 grapheme,  15 codepoints,  46 bytes
family~text~utf32~description(t:1)=             -- UTF-32:     1 grapheme,  15 codepoints,  60 bytes
family~text~unicode~description(t:1)=           -- Unicode32:  1 grapheme,  15 codepoints,  60 byte
helloZalgo = "h̵᷊̟͉͔̟̲͆e̷͇̼͉̲̾l̸̨͓̭̗᷿︣︠ͦl̶̯̻̑̈ͮ͌︡̕o̵̝̬̯᷊̭̯̦᷃ͪ̆́᷈́͜͢͞"
helloZalgo~text~description(t:1)=               -- UTF-8:      5 graphemes, 54 codepoints, 111 bytes
helloZalgo~text~utf16~description(t:1)=         -- UTF-16:     5 graphemes, 54 codepoints, 108 bytes
helloZalgo~text~utf32~description(t:1)=         -- UTF-32:     5 graphemes, 54 codepoints, 216 bytes
helloZalgo~text~unicode~description(t:1)=       -- Unicode16:  5 graphemes, 54 codepoints, 108 bytes
sleep no prompt

goto end

/*
https://andre.arko.net/2013/12/01/strings-in-ruby-are-utf-8-now/
"baﬄe".upcase == "BAFFLE"

http://xahlee.info/comp/unicode_invert_text.html
Inverted text: :ʇxǝʇ pǝʇɹǝʌuI

http://xahlee.info/comp/unicode_animals.html
T-REXX: 🦖

http://t-a-w.blogspot.com/2008/12/funny-characters-in-unicode.html
SKULL AND CROSSBONES
SNOWMAN
POSTAL MARK FACE
APL FUNCTIONAL SYMBOL TILDE DIAERESIS
ARABIC LIGATURE UIGHUR KIRGHIZ YEH WITH HAMZA ABOVE WITH ALEF MAKSURA ISOLATED FORM
ARABIC LIGATURE SALLALLAHOU ALAYHE WASALLAM
THAI CHARACTER KHOMUT
GLAGOLITIC CAPITAL LETTER SPIDERY HA
VERY MUCH GREATER-THAN
NEITHER LESS-THAN NOR GREATER-THAN
HEAVY BLACK HEART
FLORAL HEART BULLET, REVERSED ROTATED
INTERROBANG
𝄞 (U+1D11E) MUSICAL SYMBOL G CLEF
𝕥 (U+1D565) MATHEMATICAL DOUBLE-STRUCK SMALL T
𝟶 (U+1D7F6) MATHEMATICAL MONOSPACE DIGIT ZERO
𠂊 (U+2008A) Han Character

https://news.ycombinator.com/item?id=20058454
If I type anything like किमपि (“kimapi”) and hit backspace, it turns into किमप (“kimapa”).
That is, the following sequence of codepoints:
    ‎0915 DEVANAGARI LETTER KA
    ‎093F DEVANAGARI VOWEL SIGN I
    ‎092E DEVANAGARI LETTER MA
    ‎092A DEVANAGARI LETTER PA
    ‎093F DEVANAGARI VOWEL SIGN I
made of three grapheme clusters (containing 2, 1, and 2 codepoints respectively),
turns after a single backspace into the following sequence:
    ‎0915 DEVANAGARI LETTER KA
    ‎093F DEVANAGARI VOWEL SIGN I
    ‎092E DEVANAGARI LETTER MA
    ‎092A DEVANAGARI LETTER PA
This is what I expect/find intuitive, too, as a user.
Similarly अन्यच्च is made of 3 grapheme clusters but you hit backspace 7 times to delete it
(though there I'd slightly have preferred अन्यच्च→अन्यच्→अन्य→अन्→अ instead of
अन्यच्च→अन्यच्→अन्यच→अन्य→अन्→अन→अ that's seen, but one can live with this).

https://news.ycombinator.com/item?id=20056966
What does "index" mean? (hindi) "इंडेक्स" का क्या अर्थ है?

https://discourse.julialang.org/t/problems-with-deprecations-of-islower-lowercase-isupper-uppercase/7797/13
    julia> '\ub5'
    'µ': Unicode U+00b5 (category Ll: Letter, lowercase)

    julia> '\uff'
    'ÿ': Unicode U+00ff (category Ll: Letter, lowercase)

    julia> Base.Unicode.uppercase("ÿ")[1]
    'Ÿ': Unicode U+0178 (category Lu: Letter, uppercase)

    julia> Base.Unicode.uppercase("µ")[1]
    'Μ': Unicode U+039c (category Lu: Letter, uppercase)

https://mortoray.com/2013/11/27/the-string-type-is-broken/
    Objective-C’s NSString type does correctly upper-case baﬄe into BAFFLE.
    Q: What about getting the first three characters of “baﬄe”? Is “baf” the correct answer?
    A:  That’s a good question. I suspect “baf” is the correct answer, and I wonder if there is any library that does it.
        I suspect if you normalize it first (since the ffl would disappear I think).
    A:  The ligarture disappears in NFK[CD] but not in NF[CD].
        Whether normalization to NFK[CD] is a good idea depends (as always) on the situation.
        For visual grapheme cluster counting, one would convert the entire text to NFKC.
        I assume, that articles are stored in NFC (the nondestructive normalization form with smallest memory footprint).
        The Unicode standard does not treat ligatures as containing more than one grapheme cluster for that normalization forms that permits them.
        So “eﬄab” is the correct result of reversing “baﬄe”
        and “baﬄe”[2] has to return “ﬄ” even when working on the grapheme cluster level!
*/

end:
/*
End of demonstration.
*/
prompt directory on
demo off