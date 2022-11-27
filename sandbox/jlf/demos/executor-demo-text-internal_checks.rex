prompt directory off
demo on

----------------------------------
-- Text encoding - Internal checks
----------------------------------

/*
Creation of a RexxText
*/
sleep

s = "hello"
s~text = .RexxText~new("hello")          -- The counterpart must be a RexxText linked to this String
s~text = .RexxText~new(s)                -- ok, the RexxText is linked to s, now can be assigned to s~text
"é"~text("byte") || "è"~text("utf8")=    -- Cannot concatenate Byte with UTF-8
"é"~text("byte") || "é"~text("utf8")=    -- T'éé' encoded UTF-8
/*
No error because the 2 occurences of the string "é" are the same interned string.
So both texts are in fact the same instance of RexxText.
The last encoding selection wins, the result is UTF-8.
*/
sleep no prompt

/*
Byte encoding
*/
sleep

s = "63 C3 B4 74 65 CC 81 F0 9F 91 8D"x  -- An UTF-8 string. The Byte encoding works at byte level, as the String class
s=                                       -- 'côté👍'
.byte_encoding~decode(s, 1)=             -- 99 (63)
.byte_encoding~decode(s, 2)=             -- 195 (C3)
.byte_encoding~decode(s, 12)=            -- .nil (end of string)
.byte_encoding~decode(s, 1, 2)=          -- 2 is an invalid codepoint size
.byte_encoding~encode(65)=               -- T'A'
.byte_encoding~encode(256)=              -- 256 is an invalid codepoint (range 0..255)
sleep no prompt

/*
UTF-8 encoding
*/
sleep no prompt

-- If you don't pass a size to ~decode then the method calculates it, while checking the validity of the encoding
s = "63 C3 B4 74 65 CC 81 F0 9F 91 8D"x  -- An UTF-8 string: 'côté👍'
.utf8_encoding~decode(s, 1)=             -- 99
.utf8_encoding~nextCodepointIndex(s, 1)= -- 2
.utf8_encoding~decode(s, 2)=             -- 244
.utf8_encoding~nextCodepointIndex(s, 2)= -- 4
.utf8_encoding~decode(s, 8)=             -- 128077
.utf8_encoding~nextCodepointIndex(s, 8)= -- 12
.utf8_encoding~decode(s, 12)=            -- .nil (end of string)
sleep no prompt

-- Example of check
"63 C3 B4 74 65 CC 81 F0 9F 91 8D"x~text("utf8")=           -- T'côté👍'
      "B4 74 65 CC 81 F0 9F 91 8D"x~text("utf8")~errors=    -- Invalid start byte
"63 C3    74 65 CC 81 F0 9F 91 8D"x~text("utf8")~errors=    -- Invalid continuation byte
"63 C3 B4 74 65 CC 81 F0 9F 91"x~text("utf8")~errors=       -- UTF-8 character is truncated
sleep no prompt

-- If you pass a size to ~decode, the method assumes you know what you do, there is no check
.utf8_encoding~decode(s, 2, 1)=          -- 67      invalid size, the result is wrong
.utf8_encoding~decode(s, 2, 2)=          -- 244     correct
.utf8_encoding~decode(s, 2, 3)=          -- 15668   invalid size, the result is wrong
.utf8_encoding~decode(s, 2, 4)=          -- 1002789  invalid size, the result is wrong
.utf8_encoding~decode(s, 2, 5)=          -- UTF-8 encoding: 5 is an invalid codepoint size
sleep no prompt

-- Encoding
.utf8_encoding~encode(65)=               -- T'A'
.utf8_encoding~encode(650)=              -- T'ʊ'
.utf8_encoding~encode(6500)=             -- T'ᥤ'
.utf8_encoding~encode(65000)=            -- T'﷨'
.utf8_encoding~encode(650000)=           -- T'򞬐'
.utf8_encoding~encode(6500000)=          -- 6500000 is an invalid codepoint (range 0..1114111)
.utf8_encoding~encode(55296)~errors==    -- 55296 is an invalid codepoint (high surrogate)
.utf8_encoding~encode(56320)~errors==    -- 56320 is an invalid codepoint (low surrogate)

/*
UTF-16 encoding
*/
sleep

s = "63 C3 B4 74 65 CC 81 F0 9F 91 8D"x         -- An UTF-8 string: 'côté👍'
t16 = s~text("utf8")~utf16                      -- interpret the bytes as UTF-8 and convert them to UTF-16
s16 = t16~string                                -- internal UTF-16 bytes
t16~string~c2x=                                 -- view raw internal bytes
t16~c2x=                                        -- view encoded codepoints
t16~c2u=                                        -- view decoded codepoints
t16~c2g=                                        -- view encoded graphemes
sleep no prompt

-- If you don't pass a size to ~decode then the method calculates it, while checking the validity of the encoding
.utf16be_encoding~decode(s16, 1)=               -- 99
.utf16be_encoding~nextCodepointIndex(s16, 1)=   -- 3
.utf16be_encoding~decode(s16, 3)=               -- 244
.utf16be_encoding~nextCodepointIndex(s16, 3)=   -- 5
.utf16be_encoding~decode(s16, 11)=              -- 128077
.utf16be_encoding~nextCodepointIndex(s16, 11)=  -- 15
.utf16be_encoding~decode(s16, 15)=              -- .nil (end of string)
sleep no prompt

-- Example of checks
"D800 DC00 D801 DC01"x~text("utf16")~utf8=          -- T'𐀀𐐁'
     "DC00 D801 DC01"x~text("utf16")~errors=        -- Unpaired low surrogate
     "DC00 D801 DC01"x~text("wtf16")~errors=        -- acceptable when WTF-16
     "DC00 D801 DC01"x~text("wtf16")~utf8~errors==  -- but cannot be converted to UTF-8: invalid codepoint DC00x
"D800 1000 D801 DC01"x~text("utf16")~errors=        -- Invalid low surrogate
"D800 1000 D801 DC01"x~text("wtf16")~errors=        -- acceptable when WTF-16
"D800 DC00 D801 DC"x~text("utf16")~errors==         -- character is truncated. 2 errors reported because try with 4 bytes and then 2 bytes
"D800 DC00 D801 DC"x~text("wtf16")~errors==         -- this is also an error when WTF-16
sleep no prompt

-- If you pass a size to ~decode, the method assumes you know what you do, there is no check
.utf16be_encoding~decode(s16, 3, 1)=            -- 1 is an invalid codepoint size
.utf16be_encoding~decode(s16, 3, 2)=            -- 244         correct
.utf16be_encoding~decode(s16, 3, 3)=            -- 3 is an invalid codepoint size
.utf16be_encoding~decode(s16, 3, 4)=            -- invalid size, the result is wrong
.utf16be_encoding~decode(s16, 3, 5)=            -- 5 is an invalid codepoint size
sleep no prompt

-- Encoding
.utf16be_encoding~encode(65)~c2x=               -- 0041
.utf16be_encoding~encode(650)~c2x=              -- 028A
.utf16be_encoding~encode(6500)~c2x=             -- 1964
.utf16be_encoding~encode(65000)~c2x=            -- FDE8
.utf16be_encoding~encode(650000)~c2x=           -- DA3ADF10
.utf16be_encoding~encode(6500000)~c2x=          -- 6500000 is an invalid codepoint
.utf16be_encoding~encode(55296)~errors=         -- 55296 is an invalid codepoint (high surrogate)
.wtf16be_encoding~encode(55296)~errors=         -- acceptable when WTF-16
.utf16be_encoding~encode(56320)~errors=         -- 56320 is an invalid codepoint (low surrogate)
.wtf16be_encoding~encode(56320)~errors=         -- acceptable when WTF-16
sleep no prompt

/*
To concatenate two WTF-8 strings: if the earlier one ends with a lead surrogate
and the latter one starts with a trail surrogate, both surrogates need to be
removed and replaced with a 4-byte sequence.
*/
sleep
"D800 DC01"x~text("utf16")~utf8~string~c2x=     -- UTF-8 encoding of character U+10001 from its UTF-16 encoding
t1 = "D800"x~text("wtf16")                      -- An invalid UTF16 encoding, but a valid WTF-16 encoding (high surrogate)
t2 = "DC01"x~text("wtf16")                      -- An invalid UTF16 encoding, but a valid WTF-16 encoding (low surrogate)
(t1 || t2)~utf16~c2x=                           -- The concatenation is valid UTF16...
(t1 || t2)~utf16~c2u=                           -- ... whose codepoint is U+10001
t1~wtf8~string~c2x=                             -- WTF-8 encoding of U+D800 (high surrogate)
t2~wtf8~string~c2x=                             -- WTF-8 encoding of U+DC01 (low surrogate)
(t1~wtf8~string || t2~wtf8~string)~c2x=         -- The concatenation of both WTF8 can't be this (2 codepoints)
(t1~wtf8 || t2~wtf8)~c2x=                       -- The correct concatenation is 1 codepoint...
(t1~wtf8 || t2~wtf8)~c2u=                       -- ... equal to U+10001
sleep no prompt

-- WTF-8 view of this invalid concatenation
(t1~wtf8~string || t2~wtf8~string)~text("wtf8")~errors==    -- High surrogate 55296 (D800x) followed by low surrogate 56321 (DC01x) is not allowed
(t1~wtf8~string || t2~wtf8~string)~text("wtf8")~c2x=        -- EDA080 EDB081
(t1~wtf8~string || t2~wtf8~string)~text("wtf8")~c2u=        -- U+FFFD U+FFFD U+FFFD U+DC01 (yes... not 6 replacement chars because the low surrogate alone is valid)

-- UTF-8 view of this invalid concatenation
(t1~wtf8~string || t2~wtf8~string)~text("utf8")~errors==    -- High surrogate is not allowed, Low surrogate is not allowed
(t1~wtf8~string || t2~wtf8~string)~text("utf8")~c2x=        -- EDA080 EDB081
(t1~wtf8~string || t2~wtf8~string)~text("utf8")~c2u=        -- U+FFFD U+FFFD U+FFFD U+FFFD U+FFFD U+FFFD

/*
Noncharaters are supported without error.
http://www.unicode.org/faq/private_use.html#noncharacters
A "noncharacter" is a code point that is permanently reserved in the Unicode Standard for internal use.
They are considered unassigned to any abstract character, and they share the General_Category value Cn (Unassigned) with unassigned reserved code points in the standard.
Unicode has exactly 66 noncharacters.
(In this table, "#" stands for either the hex digit "E" or "F".)
    UTF-32      UTF-16      UTF-8
    0000FDD0    FDD0        EF B7 90
    ...
    0000FDEF    FDEF        EF B7 AF
    0000FFF#    FFF#        EF BF B#
    0001FFF#    D83F DFF#   F0 9F BF B#
    0002FFF#    D87F DFF#   F0 AF BF B#
    0003FFF#    D8BF DFF#   F0 BF BF B#
    0004FFF#    D8FF DFF#   F1 8F BF B#
    ...
    000FFFF#    DBBF DFF#   F3 BF BF B#
    0010FFF#    DBFF DFF#   F4 8F BF B#
*/
sleep 5
.utf16be_encoding~encode("FDD0"~x2d)~c2x=       -- FDD0
.utf8_encoding~encode("FDD0"~x2d)~c2x=          -- EFB790
sleep no prompt

/*
Create the file ill_formed_utf8.txt and check its encoding.
*/
file = .stream~new("ill_formed_utf8.txt")
file~open("write replace")
file~say("This file contains ill-formed UTF-8 characters.")
file~say(      "B4 74 65 CC 81 F0 9F 91 8D"x~text("utf8")~string    "Invalid start byte")
file~say("63 C3    74 65 CC 81 F0 9F 91 8D"x~text("utf8")~string    "Invalid continuation byte")
file~say("Next line, UTF-8 character is truncated")
file~say("63 C3 B4 74 65 CC 81 F0 9F 91"x~text("utf8")~string)    -- Don't add text, the purpose is to raise a 'truncated' error
t1 = "D800"x~text("wtf16")                                        -- An invalid UTF16 encoding, but a valid WTF-16 encoding (high surrogate)
t2 = "DC01"x~text("wtf16")                                        -- An invalid UTF16 encoding, but a valid WTF-16 encoding (low surrogate)
file~say(t1~wtf8~string                                             "invalid UTF-8 but valid WTF8 (high surrogate)")
file~say(t2~wtf8~string                                             "invalid UTF-8 but valid WTF8 (low surrogate)")
file~say( (t1~wtf8~string || t2~wtf8~string)~string                 "The concatenation of both WTF8 can't be this (2 codepoints)")
file~say( (t1~wtf8 || t2~wtf8)~string                               "The correct concatenation is 1 codepoint")
file~close
system rexx unicode/scripts/check_encoding utf8 ill_formed_utf8.txt
system rexx unicode/scripts/check_encoding wtf8 ill_formed_utf8.txt
sleep no prompt

/*
*/
file = .stream~new("ill_formed_utf16.txt")
file~open("write replace")
file~say("This file contains ill-formed UTF-16 characters.")
file~say(     "DC00 D801 DC01"x~text("utf16")~string        "Unpaired low surrogate (acceptable when WTF-16)")
file~say("D800 1000 D801 DC01"x~text("utf16")~string        "Invalid low surrogate (acceptable when WTF-16)")
file~say("Next line, character is truncated. 2 errors reported because try with 4 bytes and then 2 bytes (this is also an error when WTF-16)")
file~say("D800 DC00 D801 DC"x~text("utf16")~string)       -- Don't add text, the purpose is to raise a 'truncated' error
file~close
system rexx unicode/scripts/check_encoding utf16 ill_formed_utf16.txt
system rexx unicode/scripts/check_encoding wtf16 ill_formed_utf16.txt
sleep no prompt

/*
End of demonstration.
*/
prompt directory on
demo off
RC = 0 -- clear RC to not have an error reported by the non-regresion tests
