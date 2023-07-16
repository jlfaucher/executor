.encoding~register("WTF8", .WTF8_Encoding)

::requires "encoding/encoding.cls"
::requires "encoding/byte_common.cls"
::requires "encoding/utf8_common.cls"
::requires "encoding/unicode_common.cls"
::requires "encoding/stringIndexer.cls"

-- ::requires "encoding/unicode.cls"    -- .Unicode


/******************************************************************************/
::class "WTF8_Encoding" public inherit Byte_CommonServices XTF8_CommonServices Unicode_CommonServices StringIndexer
/*
https://simonsapin.github.io/wtf-8/#16-bit-code-unit
WTF-8 (Wobbly Transformation Format − 8-bit) is a superset of UTF-8 that encodes
surrogate code points if they are not in a pair.
It represents, in a way compatible with UTF-8, text from systems such as
JavaScript and Windows that use UTF-16 internally but don’t enforce the
well-formedness invariant that surrogates must be paired.

To convert lossily from WTF-8 to UTF-8, replace any surrogate byte sequence with
the sequence of three bytes <0xEF, 0xBF, 0xBD>, the UTF-8 encoding of the
replacement character.
Note: Since surrogate byte sequences are also three bytes long, this conversion
can be done in place.
Note: This conversion never fails but is lossy.

To convert strictly from WTF-8 to UTF-8, run these steps:
If the input contains a surrogate byte sequence, return failure.
Otherwise, return the input unchanged.

Concatenating WTF-8 strings requires extra care to preserve well-formedness.
*/

::constant name "WTF-8"
--::constant isUTF8 1 -- WTF8 is not UTF8
::constant isWTF8 1
::constant BOM "EF BB BF"x
::constant isCompatibleWithASCII 1


::method checkCodepoint class
    /*
    http://simonsapin.github.io/wtf-8/
    If the input contains a surrogate code point pair, the conversion will be
    incorrect and the resulting sequence will not represent the original code points.
    This situation should be considered an error, but this specification does not
    define how to handle it. Possibilities include aborting the conversion, or
    replacing one of the surrogate code points of the pair with a replacement character.
    */
    -- Remember : previousCodepoint can be .nil (first codepoint) or <0 (error recovery)
    --            when <0 abs(previousCodepoint) is the invalid value
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg checkOnlyRange=.false, errorInfo=.nil
    if .nil <> codepoint then do
        if codepoint < 0 | codepoint > .Unicode~maxCodepoint then signal error_range
        if checkOnlyRange then return 1 -- a positive value means "no error"
        if .nil <> previousCodepoint then do
            previousCodePointIsInvalid = (previousCodepoint < 0)
            previousCodepoint = abs(previousCodepoint)
            previousCodepointIsHighSurrogate = (previousCodepoint >= 55296 & previousCodepoint < 56320) -- U+D800 to U+DBFF high surrogates
            codepointIsLowSurrogate = (codepoint >= 56320 & codepoint < 57344)                          -- U+DC00 to U+DFFF low surrogates
            if previousCodepointIsHighSurrogate & codepointIsLowSurrogate then do
                if previousCodePointIsInvalid then signal error_low_surrogate_preceded_by_high_surrogate
                                              else signal error_high_surrogate_followed_by_low_surrogate
            end
        end
    end
    return 1 -- a positive value means "no error"

    error_range:                                    return error(0, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..".Unicode~maxCodepoint)
    error_high_surrogate_followed_by_low_surrogate: return error(-1, self~name "encoding: high surrogate" previousCodepoint "("ppCodepoint(previousCodepoint)")" || atBytePosition(previousCodepointIndexB) || " followed by low surrogate" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || " is not allowed")
    error_low_surrogate_preceded_by_high_surrogate: return error(0, self~name "encoding: low surrogate" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || " preceded by high surrogate" previousCodepoint "("ppCodepoint(previousCodepoint)")" || atBytePosition(previousCodepointIndexB) || " is not allowed")

    error:
        use strict arg whichCodepoint, errorMessage
        if .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return whichCodepoint -- -1 (previousCodepoint) or 0 (codepoint). A negative or null value means "error".
        end
        raise syntax 23.900 array (errorMessage)


/*
https://simonsapin.github.io/wtf-8/#concatenating
1. If the left input string ends with a lead surrogate byte sequence and the
   right input string starts with a trail surrogate byte sequence, run these substeps:
    1. Let lead and trail be two code points, the respective results of decoding
       from WTF-8 these two surrogate byte sequences.
    2. Let supplementary be the encoding to WTF-8 of a single code point of value
       0x10000 + ((lead - 0xD800) << 10) + (trail - 0xDC00)
    3. Let left be substring of the left input string that removes the three final bytes.
    4. Let right be substring of the right input string that removes the three initial bytes.
    5. Return the concatenation of left, supplementary, and right.
2. Otherwise, return the concatenation of the two input byte sequences

Note: This is equivalent to converting both strings to potentially ill-formed
UTF-16, concatenating the resulting 16-bit code unit sequences, then converting
the concatenation back to WTF-8.
*/
::method appendToBuffer class
    use strict arg string
    use strict named arg buffer(1)
    if buffer~length >= 3, string~length >= 3 then do
        bufferIndexB = buffer~length - 2
        if buffer~subchar(bufferIndexB)~bitand("F0"x) == "E0"x,, -- 3-byte sequence on left
           string~subchar(1)~bitand("F0"x) == "E0"x,             -- 3-byte sequence on right
        then do
            -- buffer can be UTF-8 or WTF-8, we can decode it as WTF-8
            cp1 = self~decode(buffer, bufferIndexB, 3)
            cp2 = self~decode(string, 1, 3)
            if cp1 >= 55296 & cp1 < 56320,,   -- U+D800 to U+DBFF high surrogates
               cp2 >= 56320 & cp2 < 57344,    -- U+DC00 to U+DFFF low surrogates
            then do
                h = (cp1 - 55296) * 1024 -- Take the high surrogate and subtract 0xD800, then multiply by 0x400
                l = cp2 - 56320 -- Take the low surrogate and subtract 0xDC00
                surrogate = h + l + 65536 -- Add these two results together, and finally add 0x10000
                buffer~delete(bufferIndexB)
                self~encode(surrogate, :buffer)
                return
            end
        end
    end
    buffer~append(string)
/*
"D800"x~text("wtf16")~wtf8~c2x=             -- 'EDA080' is the high surrogate U+D800 encoded in WTF-8
"DC00"x~text("wtf16")~wtf8~c2x=             -- 'EDB080' is the low surrogate U+DC00 encoded in WTF-8

                                            -- The WTF-8 encoding manages correctly the concatenation of a high surrogate with a low surrogate
("EDA080"x~text("wtf8") ||  "EDB080"x~text("wtf8"))~c2u=  -- 'U+10000'
("EDA080"x~text("wtf8") ||  "EDB080"x~text("wtf8"))~c2g=  -- 'F0908080'

                                            -- The WTF-8 concatenation of a low surrogate with a high surrogate remains two distinct codepoints/graphemes
("EDB080"x~text("wtf8") ||  "EDA080"x~text("wtf8"))~c2u=  -- 'U+DC00 U+D800'
("EDB080"x~text("wtf8") ||  "EDA080"x~text("wtf8"))~c2g=  -- 'EDB080 EDA080'

                                            -- unescape \u applied to WTF-8 manages correctly the concatenation of a high surrogate with a low surrogate
"\uD800\uDC00"~text("wtf8")~unescape~c2u=   -- 'U+10000'
"\uD800\uDC00"~text("wtf8")~unescape~c2g=   -- 'F0908080'
*/
