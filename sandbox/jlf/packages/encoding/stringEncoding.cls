::extension RexxText inherit RexxTextInternalFacade

::requires "extension/string.cls"   -- for escape3

-- Circular dependency
-- no need to requires text.cls because RexxText is a predefined class.
-- ::requires "extension/text.cls"

-- Circular dependency
-- no need to requires unicode.cls because Unicode is a predefined class.
-- ::requires "extension/unicode.cls"

-- ::options trace i

/******************************************************************************/
/*
TODOs

Unicode8 16 32 : should I create common methods in Unicode_Encoding?

Remove the index for codepoints (codepointIndexes).
There is no need of direct access to a codepoint.

Grapheme indexes : see if it's possible to replace .Array by a class being really a sparse array.
This class should be ultra specialized for the management of string indexes.
For example, could manage a flexible storage in function of the size of the index.
Maybe a multi-stage table ?
Interface:
    indexTable~new(stringSizeInBytes)
    indexTable~size
    indexTable~items
    indexTable~[integer]
    indexTable~[integer]=bytePosition
    indexTable~first     --  index of the first item in the table

*/


/******************************************************************************/
::class "RexxTextInternalFacade" mixinclass Object private

-- Give access to the indexer of a RexxText
::method internalIndexer -- should be package-scope
    return self~indexer


/******************************************************************************/
::class "Encoding" public

/*
big-endian, little-endian
    0x44332211
         0  1  2  3
    BE  44 33 22 11
    LE  11 22 33 44

    ~c2x is neutral regarding big-endian vs little-endian:
    "44332211"x~c2x -- 44332211
    "11223344"x~c2x -- 11223344

    ~c2d is always big-endian, whatever the endianness of the CPU:
    "00000001"x~c2d -- 1
    "10000000"x~c2d -- 268435456


The character at code point U+FEFF is defined as the byte order mark
Its byte-reversed counterpart, U+FFFE is a noncharacter (U+FFFE) in UTF-16 ,
or outside the code space (0xFFFE0000) for UTF-32

    UTF-8 BOM: 0xEF 0xBB 0xBF

    UTF-16 BOM: 0xFEFF
    BE: FE FF
    LE: FF FE

    UTF-32 BOM: 0x0000FEFF
    BE: 0x00 0x00 0xFE 0xFF
    LE: 0xFF 0xFE 0x00 0x00


http://www.herongyang.com/Unicode//UTF-32-UTF-32BE-UTF-32LE-Encoding.html
    - Output byte streams of UTF-32 encoding may have 3 valid formats:
      Big-Endian without BOM, Big-Endian with BOM, and Little-Endian with BOM.
    - UTF-32BE encoding is identical to the Big-Endian without BOM format of UTF-32 encoding.
    - UTF-32LE encoding is identical to the Little-Endian with BOM format of UTF-32 encoding without using BOM.

https://www.unicode.org/reports/tr17/
    UNICODE CHARACTER ENCODING MODEL

https://www.ietf.org/rfc/rfc2781.txt
    UTF-16, an encoding of ISO 10646
    This document contains the registration for three MIME charset parameter values:
    UTF-16BE (big-endian), UTF-16LE (little-endian), and UTF-16.

    UTF-16BE
        Text labelled "UTF-16BE" can always be interpreted as being big-endian.
        The detection of an initial BOM does not affect de-serialization of text labelled as UTF-16BE.
        Finding 0xFF followed by 0xFE is an error since there is no Unicode character 0xFFFE. (jlf: an error ? no: 0xFFFE is a noncharacter, Unicode says it's not an error)

    UTF-16LE
        Text labelled "UTF-16LE" can always be interpreted as being little-endian.
        The detection of an initial BOM does not affect de-serialization of text labelled as UTF-16LE.
        Finding 0xFE followed by 0xFF is an error since there is no Unicode character 0xFFFE, which would be the interpretation of those octets under little-endian order. (jlf: an error ? no: 0xFFFE is a noncharacter, Unicode says it's not an error)

    UTF-16
        If the first two octets of the text is 0xFE followed by 0xFF, then the text can be interpreted as being big-endian.
        If the first two octets of the text is 0xFF followed by 0xFE, then the text can be interpreted as being little-endian.
        If the first two octets of the text is not 0xFE followed by 0xFF, and is not 0xFF followed by 0xFE, then the text SHOULD be interpreted as being big-endian.

http://www.unicode.org/reports/tr19/tr19-9.html
    UTF-32
    The code units for UTF-32 correspond exactly to Unicode code points.
    3 encoding schemes: UTF-32 (possibly using BOM), UTF-32BE, and UTF-32LE.

    UTF-32BE
        (a) UTF-32BE is the Unicode Transformation Format that serializes a Unicode code point as a sequence of four bytes, in big-endian format.
            An initial sequence corresponding to U+FEFF is interpreted as a zero width no-break space.
        (b) An illegal UTF-32BE code unit sequence is any byte sequence that would correspond to a numeric value outside of the range 0 to 10FFFF.
        (c) An irregular UTF-32BE code unit sequence is an eight-byte sequence where the first four bytes correspond to a high surrogate, and the next four bytes correspond to a low surrogate.
            As a consequence of C12, these irregular UTF-32BE sequences shall not be generated by a conformant process.
        In UTF-32BE, <U+004D, U+0061, U+10000> is serialized as <00 00 00 4D 00 00 00 61 00 01 00 00>

    UTF-32LE
        (a) UTF-32LE is the Unicode Transformation Format that serializes a Unicode code point as a sequence of four bytes, in little-endian format.
            An initial sequence corresponding to U+FEFF is interpreted as a zero width no-break space.
        (b) An illegal UTF-32LE code unit sequence is any byte sequence that would correspond to a numeric value outside of the range 0 to 10FFFF.
        (c) An irregular UTF-32LE code unit sequence is an eight-byte sequence where the first four bytes correspond to a high surrogate, and the next four bytes correspond to a low surrogate.
            As a consequence of C12, these irregular UTF-32LE sequences shall not be generated by a conformant process.
        In UTF-32LE, <U+004D, U+0061, U+10000> is serialized as <4D 00 00 00 61 00 00 00 00 00 01 00>

    UTF-32
        (a) UTF-32 is the Unicode Transformation Format that serializes a Unicode code point as a sequence of four bytes, in either big-endian or little-endian format.
            An initial sequence corresponding to U+FEFF is interpreted as a byte order mark: it is used to distinguish between the two byte orders.
            The byte order mark is not considered part of the content of the text.
            A serialization of Unicode code points into UTF-32 may or may not begin with a byte order mark.
        (b) An illegal UTF-32 code unit sequence is any byte sequence that would correspond to a numeric value outside of the range 0 to 10FFFF.
        (c) An irregular UTF-32 code unit sequence is an eight-byte sequence where the first four bytes correspond to a high surrogate, and the next four bytes correspond to a low surrogate.
            As a consequence of C12, these irregular UTF-32 sequences shall not be generated by a conformant process.
        In UTF-32, <U+004D, U+0061, U+10000> is serialized as any of:
            <00 00 FE FF 00 00 00 4D 00 00 00 61 00 01 00 00>
            <FF FE 00 00 4D 00 00 00 61 00 00 00 00 00 01 00>
            <00 00 00 4D 00 00 00 61 00 01 00 00>


https://www.iana.org/assignments/character-sets/character-sets.xhtml
    Character Sets
    These are the official names for character sets that may be used in
     the Internet and may be referred to in Internet documentation.

*/

::attribute defaultEncoding class get
    expose defaultEncoding
    use strict arg -- none
    if \var("defaultEncoding") then defaultEncoding = .UTF8_Encoding
    return defaultEncoding


::attribute defaultEncoding class set
    expose defaultEncoding
    use strict arg encoding
    defaultEncoding = self~factory(encoding)


::attribute defaultInputEncoding class get
    expose defaultInputEncoding
    use strict arg -- none
    if \var("defaultInputEncoding") then defaultInputEncoding = self~defaultEncoding
    return defaultInputEncoding


::attribute defaultInputEncoding class set
    expose defaultInputEncoding
    use strict arg encoding
    defaultInputEncoding = self~factory(encoding)


::attribute defaultOutputEncoding class get
    expose defaultOutputEncoding
    use strict arg -- none
    if \var("defaultOutputEncoding") then defaultOutputEncoding = self~defaultEncoding
    return defaultOutputEncoding


::attribute defaultOutputEncoding class set
    expose defaultOutputEncoding
    use strict arg encoding
    defaultOutputEncoding = self~factory(encoding)


::method activate class
    expose encodings
    use strict arg -- none
    encodings = .directory~new

    encodings["BYTE"] = .Byte_Encoding
    encodings["BYTES"] = .Byte_Encoding

    encodings["UTF8"] = .UTF8_Encoding
    encodings["WTF8"] = .WTF8_Encoding

    encodings["UTF16"] = .UTF16BE_Encoding
    encodings["UTF16BE"] = .UTF16BE_Encoding
    encodings["UTF16LE"] = .UTF16LE_Encoding
    encodings["WTF16"] = .WTF16BE_Encoding
    encodings["WTF16BE"] = .WTF16BE_Encoding
    encodings["WTF16LE"] = .WTF16LE_Encoding

    encodings["UTF32"] = .UTF32BE_Encoding
    encodings["UTF32BE"] = .UTF32BE_Encoding
    encodings["UTF32LE"] = .UTF32LE_Encoding

    -- "UNICODE" can't be used to create a RexxText.
    -- But can be used in conversion, to get the shortest possible representation
    -- encodings["UNICODE"] = .Unicode_Encoding

    encodings["UNICODE8"] = .Unicode8_Encoding
    encodings["UNICODE16"] = .Unicode16_Encoding
    encodings["UNICODE32"] = .Unicode32_Encoding

    -- windows-1250 (Central and Eastern Europe)
    -- encodings["CP1250"] = .CP1250_Encoding
    -- encodings["WINDOWS1250"] = .CP1250_Encoding

    -- windows-1251 (Bulgarian, Byelorussian, Macedonian, Russian, Serbian)
    -- encodings["CP1251"] = .CP1251_Encoding
    -- encodings["WINDOWS1251"] = .CP1251_Encoding

    -- windows-1252 (Western Europe)
    encodings["CP1252"] = .CP1252_Encoding
    encodings["WINDOWS1252"] = .CP1252_Encoding

    -- windows-1253 (Greek)
    -- encodings["CP1253"] = .CP1253_Encoding
    -- encodings["WINDOWS1253"] = .CP1253_Encoding

    -- windows-1254 (Turkish)
    -- encodings["CP1254"] = .CP1254_Encoding
    -- encodings["WINDOWS1254"] = .CP1254_Encoding

    -- windows-1255 (Hebrew)
    -- encodings["CP1255"] = .CP1255_Encoding
    -- encodings["WINDOWS1255"] = .CP1255_Encoding

    -- windows-1256 (Arabic)
    -- encodings["CP1256"] = .CP1256_Encoding
    -- encodings["WINDOWS1256"] = .CP1256_Encoding

    -- windows-1257 (Baltic languages)
    -- encodings["CP1257"] = .CP1257_Encoding
    -- encodings["WINDOWS1257"] = .CP1257_Encoding

    -- windows-1258 (Vietnamese)
    -- encodings["CP1258"] = .CP1258_Encoding
    -- encodings["WINDOWS1258"] = .CP1258_Encoding

    -- ISO-8859-1 (Western Europe)
    -- https://en.wikipedia.org/wiki/ISO/IEC_8859-1
    --  iso-ir-100, csISOLatin1, latin1, l1, IBM819. Code page 28591 a.k.a. Windows-28591 is used for it in Windows.[9] IBM calls it code page 819 or CP819 (CCSID 819).[10][11][12][13] Oracle calls it WE8ISO8859P1.[14]
    -- https://docs.python.org/3/library/codecs.html#standard-encodings
    --  iso-8859-1, iso8859-1, 8859, cp819, latin, latin1, L1
    encodings["819"] = .ISO88591_Encoding
    encodings["8859"] = .ISO88591_Encoding
    encodings["28591"] = .ISO88591_Encoding
    encodings["CP819"] = .ISO88591_Encoding
    encodings["CSISOLATIN1"] = .ISO88591_Encoding
    encodings["IBM819"] = .ISO88591_Encoding
    encodings["ISO88591"] = .ISO88591_Encoding
    encodings["ISOIR100"] = .ISO88591_Encoding
    encodings["L1"] = .ISO88591_Encoding
    encodings["LATIN"] = .ISO88591_Encoding
    encodings["LATIN1"] = .ISO88591_Encoding
    encodings["CP819"] = .ISO88591_Encoding
    encodings["WE8ISO8859P1"] = .ISO88591_Encoding
    encodings["WINDOWS28591"] = .ISO88591_Encoding

    -- ISO-8859-2 (Central and Eastern Europe)
    -- encodings["ISO88592"] = .ISO88592_Encoding
    -- encodings["L2"] = .ISO88592_Encoding
    -- encodings["LATIN2"] = .ISO88592_Encoding

    -- ISO-8859-3 (Esperanto, Maltese)
    -- encodings["ISO88593"] = .ISO88593_Encoding
    -- encodings["L3"] = .ISO88593_Encoding
    -- encodings["LATIN3"] = .ISO88593_Encoding

    -- ISO-8859-4 (Baltic languages)
    -- encodings["ISO88594"] = .ISO88594_Encoding
    -- encodings["L4"] = .ISO88594_Encoding
    -- encodings["LATIN4"] = .ISO88594_Encoding

    -- ISO-8859-5 (Bulgarian, Byelorussian, Macedonian, Russian, Serbian)
    -- encodings["ISO88595"] = .ISO88595_Encoding
    -- encodings["CYRILLIC"] = .ISO88595_Encoding

    -- ISO-8859-6 (Arabic)
    -- encodings["ISO88596"] = .ISO88596_Encoding
    -- encodings["ARABIC"] = .ISO88596_Encoding

    -- ISO-8859-7 (Greek)
    -- encodings["ISO88597"] = .ISO88597_Encoding
    -- encodings["GREEK"] = .ISO88597_Encoding
    -- encodings["GREEK8"] = .ISO88597_Encoding

    -- ISO-8859-8 (Hebrew)
    -- encodings["ISO88598"] = .ISO88598_Encoding
    -- encodings["HEBREW"] = .ISO88598_Encoding

    -- ISO-8859-9 (Turkish)
    -- encodings["ISO88599"] = .ISO88599_Encoding
    -- encodings["L5"] = .ISO88599_Encoding
    -- encodings["LATIN5"] = .ISO88599_Encoding

    -- ISO-8859-10 (Nordic languages)
    -- encodings["ISO885910"] = .ISO885910_Encoding
    -- encodings["L6"] = .ISO885910_Encoding
    -- encodings["LATIN6"] = .ISO885910_Encoding

    -- ISO-8859-11 (Thai languages)
    -- encodings["ISO885911"] = .ISO885911_Encoding
    -- encodings["THAI"] = .ISO885910_Encoding

    -- ISO-8859-13 (Baltic languages)
    -- encodings["ISO885913"] = .ISO885913_Encoding
    -- encodings["L7"] = .ISO885913_Encoding
    -- encodings["LATIN7"] = .ISO885913_Encoding

    -- ISO-8859-14 (Celtic languages)
    -- encodings["ISO885914"] = .ISO885914_Encoding
    -- encodings["L8"] = .ISO885914_Encoding
    -- encodings["LATIN8"] = .ISO885914_Encoding

    -- ISO-8859-15 (Western Europe)
    -- encodings["ISO885915"] = .ISO885915_Encoding
    -- encodings["L9"] = .ISO885915_Encoding
    -- encodings["LATIN9"] = .ISO885915_Encoding

    -- ISO-8859-16 (South-Eastern Europe)
    -- encodings["ISO885916"] = .ISO885916_Encoding
    -- encodings["L10"] = .ISO885916_Encoding
    -- encodings["LATIN10"] = .ISO885916_Encoding

    -- Mac Roman (Western Europe)
    -- encodings["MACINTOSH"] = .MACROMAN_Encoding
    -- encodings["MACROMAN"] = .MACROMAN_Encoding


::method normalize class
    use strict arg encodingName
    -- Remove all dash, underscore and spaces: "UTF8", "UTF_8", "UTF-8", "UTF 8" are all a valid encoding name
    return encodingName~translate(, "_- "," ")~space(0)~upper


::method register class
    expose encodings
    use strict arg encodingName, encoding
    encodingName = .Encoding~normalize(encodingName)
    encodings[encodingName] = encoding


::method supported class
    expose encodings
    use strict arg -- none
    return encodings~supplier


::method factory class
    expose encodings
    use strict arg encoding, string=""
    if encoding~isA(.Class), encoding~isSubClassOf(.StringIndexer) then return encoding
    encodingName = .Encoding~normalize(encoding~string)
    if encodingName == "DEFAULT" then return .Encoding~defaultEncoding
    if encodingName == "UTF16" then do
        if string~startsWith(.UTF16BE_Encoding~BOM) then return .UTF16BE_Encoding
        if string~startsWith(.UTF16LE_Encoding~BOM) then return .UTF16LE_Encoding
        return .UTF16BE_Encoding -- The Unicode norm specifies that the default UTF-16 is big endian
    end
    if encodingName == "WTF16" then do
        if string~startsWith(.WTF16BE_Encoding~BOM) then return .WTF16BE_Encoding
        if string~startsWith(.WTF16LE_Encoding~BOM) then return .WTF16LE_Encoding
        return .WTF16BE_Encoding -- Same logic of default as UTF-16
    end
    if encodingName == "UTF32" then do
        if string~startsWith(.UTF32BE_Encoding~BOM) then return .UTF32BE_Encoding
        if string~startsWith(.UTF32LE_Encoding~BOM) then return .UTF32LE_Encoding
        return .UTF32BE_Encoding -- The Unicode norm specifies that the default UTF-32 is big endian
    end
    if encodings~hasEntry(encodingName) then return encodings[encodingName]
    raise syntax 23.900 array("Encoding: '"encoding"' is not supported")


-- If you modify this method then see if asEncodingFor must be modified as well
::method forConcatenation class
    use strict arg left, right -- text or buffer or string

    left = left~requestTextOrBufferOrString
    if .nil == left then signal left_must_have_a_text_or_buffer_or_string_value
    leftEncoding = left~encoding
    leftIsCompatibleWithASCII = left~isCompatibleWithASCII

    right = right~requestTextOrBufferOrString
    if .nil == right then signal right_must_have_a_text_or_buffer_or_string_value
    rightEncoding = right~encoding
    rightIsCompatibleWithASCII = right~isCompatibleWithASCII

    if leftEncoding == rightEncoding then return leftEncoding

    if leftEncoding~isUTF8, rightEncoding~isWTF8 then return .WTF8_Encoding
    if leftEncoding~isWTF8, rightEncoding~isUTF8 then return .WTF8_Encoding
    -- Keep the following tests after the previous tests, to keep the priority for WTF8
    -- Give priority to unicode over byte-encoding
    -- When unicode on both sides then give priority to the left encoding
    if leftIsCompatibleWithASCII, (rightEncoding~isUTF8 | rightEncoding~isWTF8 | rightEncoding~isUnicode8) then do
        if leftEncoding~isUnicode then return leftEncoding
        return rightEncoding
    end
    if (leftEncoding~isUTF8 | leftEncoding~isWTF8 | leftEncoding~isUnicode8), rightIsCompatibleWithASCII then return leftEncoding

    if leftEncoding~isUTF16BE, rightEncoding~isWTF16BE then return .WTF16BE_Encoding
    if leftEncoding~isWTF16BE, rightEncoding~isUTF16BE then return .WTF16BE_Encoding
    if leftEncoding~isUTF16LE, rightEncoding~isWTF16LE then return .WTF16LE_Encoding
    if leftEncoding~isWTF16LE, rightEncoding~isUTF16LE then return .WTF16LE_Encoding

    -- TODO Discutable?
    -- Consider that Unicode32 is never compatible with UTF-32BE or UTF-32LE
    -- even if it can be compatible in function of the CPU endianness.
    -- It's to ensure that if a program works on a little-endian CPU then it works on a big-endian CPU, and vice-versa.

    raise syntax 23.900 array("Encoding: cannot append" right~descriptionForError "to" left~descriptionForError)

    left_must_have_a_text_or_buffer_or_string_value:  raise syntax 93.900 array("Method positional argument 'left' must have a text or buffer or string value")
    right_must_have_a_text_or_buffer_or_string_value: raise syntax 93.900 array("Method positional argument 'right' must have a text or buffer or string value")


::method comparisonMode class
    -- if a byte comparison is possible then return "b"
    -- if a unicode comparision is possible then return "u"
    -- otherwise raise an error
    use strict arg left, right -- text or string or buffer
    if left~encoding~isByte, right~encoding~isByte, left~encoding == right~encoding then return "b"
    if left~isCompatibleWithASCII, right~isCompatibleWithASCII then return "b"
    if left~isCompatibleWithASCII, (right~encoding~isUTF8 | right~encoding~isWTF8) then return "u"
    if (left~encoding~isUTF8 | left~encoding~isWTF8), right~isCompatibleWithASCII then return "u"
    if left~encoding~isUnicode & right~encoding~isUnicode then return "u"
    raise syntax 23.900 array("Encoding: cannot compare" left~descriptionForError "with" right~descriptionForError)


/******************************************************************************/
::class "IndexerHelpers" mixinclass Object private

::method append class
    -- Positional arguments : zero to N text or buffer or string.
    use arg ...
    use strict named arg buffer(1)=.nil
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new
    buffer~encoding = self~asEncodingFor(buffer) -- raise an error if not compatible

    do i=1 to arg()
        text = arg(i)~requestTextOrBufferOrString
        if .nil == text then signal must_have_a_text_or_buffer_or_string_value
        encoding = .Encoding~forConcatenation(buffer, text) -- raise an error if not compatible
        buffer~encoding = encoding
        encoding~concatenate(text, :buffer)
    end
    if returnBuffer then return buffer
    else return .RexxText~new(buffer~string, buffer~encoding)

    must_have_a_text_or_buffer_or_string_value: raise syntax 93.900 array("Method positional argument "i" must have a text or buffer or string value")


::method endsWithText
    use strict arg other
    use strict named arg casefold
    -- todo
/*
    start = self~length - substr~length + 1
    if start < 1 then return .false
    return self~pos(substr, start) == start
*/


::method lower_upper_title private
    use strict arg action, startC, length
    use strict named arg buffer(1)=.nil

    if \datatype(startC, "w") then signal invalid_position
    if startC <= 0 then signal invalid_position

    if \datatype(length, "w") then signal invalid_length
    if length < 0 then signal invalid_length

    if startC > self~length then return self~string~text
    if length == 0 then return self~string~text

    endC = min(startC + length - 1, self~length)
    startB = abs(self~graphemeIndex(startC))
    endB = abs(self~graphemeIndex(endC+1))

    string = self~string
    encoding = self~class
    returnBuffer = .nil <> buffer

    -- Initialize the left not-impacted section
    if .nil == buffer then buffer = .MutableBuffer~new(string~left(startB - 1))
                      else buffer~append(string~left(startB - 1))
    codepointIndexB = startB

    -- Process the impacted section

    error = .array~new -- simulate variable by reference

    -- If the action is to title then check if the begining of the section is a begining of word
    if action == "t" then do
        -- Simple split by words using space as separator. Absolutly not Unicode compliant.
        beginOfWord = .false
        if codepointIndexB == 1 then beginOfWord = .true -- 1st character
        else do
            previousCodepointIndexB = encoding~previousCodepointIndex(string, codepointIndexB, errorInfo: error)
            if previousCodepointIndexB > 0,  previousCodepointIndexB \== codepointIndexB then do
                codepointSizeB = codepointIndexB - previousCodepointIndexB
                -- remember: don't test directly .Unicode~spaceCharacter because this method is not limited to Unicode
                if string~substr(previousCodepointIndexB, codepointSizeB) == encoding~spaceCharacter~string then beginOfWord = .true
            end
        end
    end

    do while codepointIndexB < endB
        nextCodepointIndexB = encoding~nextCodepointIndex(string, codepointIndexB, errorInfo: error)
        if nextCodepointIndexB > 0 then do -- if no error
            if nextCodepointIndexB == codepointIndexB then leave -- should not happen, but...
            codepointSizeB = nextCodepointIndexB - codepointIndexB
            codepoint = encoding~decode(string, codepointIndexB, codepointSizeB)
            if action == "l" then codepoint = encoding~codepointToLower(codepoint)
            else if action == "u" then codepoint = encoding~codepointToUpper(codepoint)
            else if action == "t" then do
                if beginOfWord then codepoint = encoding~codepointToTitle(codepoint)
                               else codepoint = encoding~codepointToLower(codepoint)
                beginOfWord = (string~substr(codepointIndexB, codepointSizeB) == encoding~spaceCharacter~string)
            end
        end
        else do
            codepoint = .Unicode~replacementCharacter~codepoint
        end
        encoding~encode(codepoint, :buffer)
        codepointIndexB = abs(nextCodepointIndexB)
    end

    -- Append the rigth not-impacted section
    buffer~append(string~right(string~length - endB + 1))
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, encoding)

    invalid_length:             raise syntax 93.923 array(length)
    invalid_position:           raise syntax 93.924 array(startC)


::method matchCharText
    use strict arg nC, chars
    -- todo


::method matchText private
    use strict arg startC, other, nC, lengthC
    -- stay limited to NFC because of the position and length
    use strict named arg casefold, lump, stripIgnorable, stripMark -- boolean

    selfIndexer = self
    call check_position startC, selfIndexer~length

    otherText = other~request("RexxText") -- not requestTextOrBufferOrString because we really need a RexxText
    if .nil == otherText then signal must_have_a_text_or_string_value

    otherIndexer = otherText~internalIndexer
    call check_position nC, otherIndexer~length

    if .nil == lengthC then lengthC = otherIndexer~length - nC + 1
    call check_length lengthC, otherIndexer~length, nC

    selfText = selfIndexer~string~text
    selfNormText = selfText~NFC(:casefold, :lump, :stripIgnorable, :stripMark)
    selfNormIndexer = selfNormText~internalIndexer

    otherNormText = otherText~NFC(:casefold, :lump, :stripIgnorable, :stripMark)
    otherNormIndexer = otherNormText~internalIndexer

    startB = abs(selfNormIndexer~graphemeIndex(startC))
    nB = abs(otherNormIndexer~graphemeIndex(nC))
    mC = nC + lengthC
    mB = abs(otherNormIndexer~graphemeIndex(mC))
    lengthB = mB - nB

    selfNormString = selfNormIndexer~string
    otherNormString = otherNormIndexer~string
    return selfNormString~match(startB, otherNormString, nB, lengthB)

    check_position: procedure
        use strict arg position, max
        if \datatype(position, "w") then signal invalid_position
        if position <= 0 then signal invalid_position
        if position > max then signal invalid_position
        return

        invalid_position: raise syntax 93.924 array(position)

    check_length: procedure
        use strict arg length, max, pos
        if \datatype(length, "w") then signal invalid_length
        if length < 0 then signal invalid_length -- 0 accepted
        if length > max then signal invalid_length
        -- rexxref.pdf: the combination of n and length must be a valid substring within the bounds of other.
        if (pos + length - 1) > max then signal invalid_length
        return

        invalid_length: raise syntax 93.923 array(length)

    must_have_a_text_or_string_value: raise syntax 93.900 /*93.938*/ array("Method positional argument 2 must have a text or string value")


::method posText private
    use strict arg needle, startC, lengthC
    use strict named arg casefold -- boolean
    -- todo


/******************************************************************************/
::class "IndexerStringInterface" mixinclass Object private

::method append
    use strict arg text -- text or string
    use strict named arg buffer(1)=.nil
    text = text~requestTextOrBufferOrString
    if .nil == text then signal must_have_a_text_or_buffer_or_string_value
    encoding = .Encoding~forConcatenation(self~string, text) -- raise an error if not compatible
    return encoding~append(self~string, text, :buffer)

    must_have_a_text_or_buffer_or_string_value: raise syntax 93.900 array("Method positional argument 1 must have a text or buffer or string value")


::method caselessEndsWith
    use strict arg other
    return self~endsWithText(other, casefold: .true)


::method caselessMatch
    use strict arg startC, other, nC=1, lengthC=.nil
    use strict named arg lump= .false, stripIgnorable= .false, stripMark=.false
    return self~matchText(startC, other, nC, lengthC, casefold: .true, :lump, :stripIgnorable, :stripMark)


::method caselessMatchChar
    use strict arg nC, chars
    return self~matchCharText(nC, chars, casefold: .true)


::method caselessPos
    use strict arg needle, startC=1, lengthC=(self~length)
    return self~posText(needle, startC, lengthC, casefold: .true)


::method center
    use strict arg length, pad=(self~class~spaceCharacter)
    use strict named arg buffer(1)=.nil

    if \datatype(length, "w") then signal invalid_length
    if length < 0 then signal invalid_length

    pad = pad~request("RexxText") -- not requestTextOrBufferOrString because we really need the pad's length in graphemes
    if .nil == pad then signal must_have_a_text_or_string_value
    if pad~length <> 1 then signal incorrect_pad

    width = length
    len = self~length

    if witdh == len then do
        if .nil <> buffer then return buffer~~append(self~string)
                          else return .RexxText~new(self~string, self~class)
    end

    if width == 0 then do
        if .nil <> buffer then return buffer -- unchanged because result of center is ""
                          else return self~class~emptyString
    end

    if width > len then do
        encoding = .Encoding~forConcatenation(self~string, pad) -- raise an error if not compatible
        leftPad = (width - len) % 2
        rightPad = (width - len) - leftPad
        space = rightPad + leftPad + len
        retval =
        if .nil <> buffer then do
            -- TODO: rework
            -- can't use encoding~concatenate for pad because pad~copies appends directly to the buffer
            -- consequence: will not detect WTF8 special concatenation, if any/
            pad~copies(leftPad, :buffer)
            encoding~concatenate(self~string, :buffer)
            pad~copies(rightPad, :buffer)
            return buffer
        end
        return encoding~concatenate(pad~copies(leftPad), self~string, pad~copies(rightPad))
    end
    else do
        leftPad = (len - width) % 2 -- integer divide
        return self~substr(leftPad + 1, width)
    end

    incorrect_pad:                    raise syntax 93.922 array(pad~descriptionForError)
    invalid_length:                   raise syntax 93.923 array(length)
    must_have_a_text_or_string_value: raise syntax 93.900 array("Method positional argument 3 must have a text or string value")


::method endsWith
    use strict arg other
    return self~endsWithText(other, casefold: .false)


::method length -- number of graphemes
    use strict arg -- none
    return self~graphemeCount


::method lower
    use strict arg startC=1, length=(max(0, self~length - startC + 1))
    use strict named arg buffer(1)=.nil
    return self~lower_upper_title("l", startC, length, :buffer)


::method match
    use strict arg startC, other, nC=1, lengthC=.nil
    use strict named arg lump= .false, stripIgnorable= .false, stripMark=.false
    return self~matchText(startC, other, nC, lengthC, casefold: .false, :lump, :stripIgnorable, :stripMark)


::method matchChar
    use strict arg nC, chars
    return self~matchCharText(nC, chars, casefold: .false)


::method pos
    use strict arg needle, startC=1, lengthC=(self~length)
    return self~posText(needle, startC, lengthC, casefold: .false)


::method reverse
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new
    do indexG = self~graphemeCount to 1 by -1
        self~grapheme(indexG, :buffer)
    end
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self~class)


::method right
    use strict arg length, pad=(self~class~spaceCharacter)
    use strict named arg buffer(1)=.nil

    if \datatype(length, "w") then signal invalid_length
    if length < 0 then signal invalid_length

    pad = pad~request("RexxText") -- not requestTextOrBufferOrString because we really need the pad's length in graphemes
    if .nil == pad then signal must_have_a_text_or_string_value
    if pad~length <> 1 then signal incorrect_pad

    encoding = .Encoding~forConcatenation(self~string, pad) -- raise an error if not compatible

    lengthPad = max(0, length - self~length)
    length = length - lengthPad

    endC = self~length + 1
    endB = abs(self~graphemeIndex(endC))
    startC = endC - length
    startB = abs(self~graphemeIndex(startC))
    right = self~string~right(endB - startB)
    if lengthPad == 0 then do
        if .nil <> buffer then return buffer~~append(right)
                          else return .RexxText~new(right, self~class)
    end
    if .nil <> buffer then do
        -- can't use encoding~concatenate for pad because pad~copies appends directly to the buffer
        -- consequence: will not detect WTF8 special concatenation, if any.
        pad~copies(lengthPad, :buffer)
        encoding~concatenate(right, :buffer)
        return buffer
    end
    return encoding~concatenate(pad~copies(lengthPad), right)

    incorrect_pad:                    raise syntax 93.922 array(pad~descriptionForError)
    invalid_length:                   raise syntax 93.923 array(length)
    must_have_a_text_or_string_value: raise syntax 93.900 array("Method positional argument 3 must have a text or string value")


::method substr
    use strict arg startC, length=(max(0, self~length - startC + 1)), pad=(self~class~spaceCharacter)
    use strict named arg buffer(1)=.nil

    if \datatype(startC, "w") then signal invalid_position
    if startC <= 0 then signal invalid_position

    if \datatype(length, "w") then signal invalid_length
    if length < 0 then signal invalid_length

    pad = pad~request("RexxText") -- not requestTextOrBufferOrString because we really need the pad's length in graphemes
    if .nil == pad then signal must_have_a_text_or_string_value
    if pad~length <> 1 then signal incorrect_pad

    encoding = .Encoding~forConcatenation(self~string, pad) -- raise an error if not compatible

    if startC > self~length then return pad~copies(length, :buffer)
    remainingLength = self~length - startC + 1 -- always >= 0
    lengthPad = max(0, length - remainingLength)
    endC = min(startC + length - 1, self~length)

    startB = abs(self~graphemeIndex(startC))
    endB = abs(self~graphemeIndex(endC+1))
    substr = self~string~substr(startB, endB - startB)
    if lengthPad == 0 then do
        if .nil <> buffer then return buffer~~append(substr)
                          else return .RexxText~new(substr, self~class)
    end
    if .nil <> buffer then do
        encoding~concatenate(substr, :buffer)
        -- TODO: rework
        -- can't use encoding~concatenate for pad because pad~copies appends directly to the buffer
        -- consequence: will not detect WTF8 special concatenation, if any.
        pad~copies(lengthPad, :buffer)
        return buffer
    end
    return encoding~concatenate(substr, pad~copies(lengthPad))

    incorrect_pad:                    raise syntax 93.922 array(pad~descriptionForError)
    invalid_length:                   raise syntax 93.923 array(length)
    invalid_position:                 raise syntax 93.924 array(startC)
    must_have_a_text_or_string_value: raise syntax 93.900 array("Method positional argument 3 must have a text or string value")


-- not a String method but maybe in the future...
::method title
    use strict arg startC=1, length=(max(0, self~length - startC + 1))
    use strict named arg buffer(1)=.nil
    return self~lower_upper_title("t", startC, length, :buffer)


::method upper
    use strict arg startC=1, length=(max(0, self~length - startC + 1))
    use strict named arg buffer(1)=.nil
    return self~lower_upper_title("u", startC, length, :buffer)


/******************************************************************************/
::class "BitKey" private


::method init class
    expose powerOfTwo keyCache
    powerOfTwo = (1, 2, 4, 8, 16, 32, 64, 128, 256, 512)
    keyCache = .array~new -- map an integer to an interned string which is usable as an index of an IdentityTable
    self~init:super


::method bitPosMask class
    expose powerOfTwo keyCache
    use strict arg bitPos -- range 0 to (array~size - 1)
    dmask = powerOfTwo[bitpos + 1]
    --return dmask~d2c
    --/*
    cmask = keyCache[dmask]
    if .nil == cmask then do
        cmask = dmask~d2c
        keyCache[dmask] = cmask
    end
    return cmask
    --*/


::method bitFlagsMask class
    -- pre-condition:  each argument is 0 or not 0 or omitted
    -- post-condition: result = arg(1) + arg(2) * 2 + arg(3) * 4 + arg(4) * 8 ...
    expose powerOfTwo keyCache
    dmask = 0
    do i=1 to arg()
        if arg(i, "e") then dmask += (arg(i) \== 0) * powerOfTwo[i] -- (2 ** (i - 1))
    end
    --return dmask~d2c
    --/*
    cmask = keyCache[dmask]
    if .nil == cmask then do
        cmask = dmask~d2c
        keyCache[dmask] = cmask
    end
    return cmask
    --*/


/******************************************************************************/
::class "CachedStrings" mixinclass Object private

/*
A same text can be transformed in several strings, each described by a set of flags.
This set of flags is used as a key to store the corresponding string in a cache.
Example of set of flags:
    Assuming that NFC is bit 0, casefold is bit 4, stripMark is bit 6:
    NFC = 1                                     key = '[01]'    01x     00000001
    NFC casefold = 1 + 16 = 17                  key = '[11]'    11x     00010001
    NFC casefold stripMark = 1 + 16 + 32 = 49   key = '1'       31x     00110001
    etc...

    Cached strings:
    stringsCache at '[01]' = NFC
    stringsCache at '[11]' = NFC casefold
    stringsCache at '1'    = NFC casefold stripMark
*/

::attribute stringsCache get -- for tuning/display only

::method init
    expose stringsCache assignedBitFlags bitFlags

    -- Usage: if the flag is set then val = flag else val = -1 (see bitFlag)
    stringsCache = /*.Directory~new --*/ .IdentityTable~new
    assignedBitFlags = 0~d2c
    bitFlags = 0~d2c
    self~init:super


::method bitFlag private
    -- If the bit is assigned then value = flag else value = -1

    -- bitPos            ...   7   6   5   4   3   2   1   0
    -- mask              ... 128  64  32  16   8   4   2   1
    -- assignedBitFlags     .  1   0   0   0   1   1   0   0
    -- bitFlags             .  1   0   0   0   0   1   0   0
    -- value                .  1  -1  -1  -1   0   1  -1  -1

    expose assignedBitFlags bitFlags
    use strict arg bitPos
    mask = .BitKey~bitPosMask(bitPos) -- interned (2 ** bitPos)~d2c
    if assignedBitFlags~bitand(mask) == mask then return bitFlags~bitand(mask) == mask
    return -1   -- unknown


::method bitFlagsAllTrue private
    -- This method return .true if all the bits selected by the mask have value 1
    expose assignedBitFlags bitFlags
    use strict arg mask -- byte encoded mask 1001...
    if assignedBitFlags~bitand(mask) == mask then return bitFlags~bitand(mask) == mask
    return .false


::method setBitFlag private
    expose assignedBitFlags bitFlags
    use strict arg bitPos
    mask = .BitKey~bitPosMask(bitPos) -- interned (2 ** bitPos)~d2c
    assignedBitFlags = assignedBitFlags~bitor(mask) -- this bit is set
    bitFlags = bitFlags~bitor(mask)                 -- this flag is 1


::method setBitFlags private
    expose assignedBitFlags bitFlags
    use strict arg mask
    assignedBitFlags = assignedBitFlags~bitor(mask) -- all these flags are set
    bitFlags = bitFlags~bitor(mask)                 -- all these flags are 1


::method getCachedString private
    expose stringsCache
    use strict arg mask
    return stringsCache~at(mask) -- .nil if not found


::method cacheString private
    expose stringsCache
    use strict arg mask, string
    stringsCache~put(string, mask)


/******************************************************************************/
::class "StringIndexer" mixinclass Object private - -- abstract
                        inherit IndexerStringInterface -
                                IndexerHelpers -
                                CachedStrings

::method name class abstract


::constant isByte 0
::constant isUnicode 0
::constant isUTF8 0
::constant isWTF8 0
::constant isUTF16 0
::constant isUTF16BE 0
::constant isUTF16LE 0
::constant isWTF16 0
::constant isWTF16BE 0
::constant isWTF16LE 0
::constant isUTF32 0
::constant isUTF32BE 0
::constant isUTF32LE 0
::constant isWTF32 0
::constant isWTF32BE 0
::constant isWTF32LE 0
::constant isUnicodeN 0
::constant isUnicode8 0
::constant isUnicode16 0
::constant isUnicode32 0


::method codeUnitSizeInBytes class abstract -- constant 1 2 or 4


::method codepointMaxBytes class abstract -- constant used for buffer allocation


/*
Analyze all the bytes of the string, create an indexer.

Return value:
    a RexxText

In case of errors, an array attached to the RexxText provides all the errors
detected during the analysis.
*/
::method analyze class abstract
    -- use strict arg string


/*
Arguments:
    previousCodepoint can be .nil (first codepoint) or <0 (error recovery).
    when <0 abs(previousCodepoint) is the invalid value.

    errorInfo is either an array or .nil
    when array, in case of error, the error description is returned in errorInfo[1]

Return value:
    A positive value means "no error"
    A negative or null value means "error"

if no error then checkCodepoint == 1.
if error then
    if errorInfo == .nil then a condition is raised
    otherwise
        errorInfo[1] = error description
        checkCodepoint == -1 if the error is about previousCodepoint
        checkCodepoint == 0  if the error is abour codepoint
*/
::method checkCodepoint class abstract
    -- use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    -- use strict named arg checkOnlyRange /*no impact here*/, errorInfo=.nil
    -- Unicode8_Encoding, Unicode16_Encoding and Unicode32_Encoding accept an additional named argument: checkingMaximumCodepoint=.false


/*
sizeB == -1 ==> this method will check the validity of the encoding
sizeB <> -1 ==> this method assumes that the encoding has been checked and is valid
if sizeB == 0 then return .nil otherwise return a string made of one codepoint
*/
::method decode class abstract
    -- use strict arg string /* or buffer */, startB=1, sizeB=(-1)


::method byteSequenceSize class abstract


/*
If end of string, then nextCodepointIndex == startB.

if errorInfo \== .nil then in case of error: nextCodepointIndex is negative and always greater than startB.
                                             errorInfo[1] == error description.
if errorInfo  == .nil  then no need to test if nextCodepointIndex is negative. In case of error, a condition is raised.
*/
::method nextCodepointIndex class abstract
    -- use strict arg string /* or buffer */, startB
    -- use strict named arg errorInfo=.nil


/*
If startB is the start of string then nextCodepointIndex is equal to startB.

If startB is beyond the end of string +1 byte then nextCodepointIndex is equal to startB.
Which means "no previous codepoint".
Not trying to walk back until a valid codepoint is found, whatever the distance.
Reason: if no error then startB - previousCodepointIndex is the length in bytes of the previous codepoint.

if errorInfo \== .nil then in case of error: nextCodepointIndex is negative and always lesser than startB.
                                             errorInfo[1] == error description.
if errorInfo  == .nil  then no need to test if nextCodepointIndex is negative. In case of error, a condition is raised.

startB is the index of the first byte of the current codepoint
  cp1        |cp2              |cp3...
  byte1|byte2|byte3|byte4|byte5|byte6...
  1    |2    |3    |4    |5    |6...
For example, if startB==6 then previousCodepointIndex==3
*/
::method previousCodepointIndex class abstract
    -- use strict arg string /* or buffer */, startB
    -- use strict named arg errorInfo=.nil


::method encode class abstract


::method codepointSizeInBytes class abstract -- how many bytes to encode this codepoint


::method codepointToLower class abstract


::method codepointToUpper class abstract


::method codepointToTitle class abstract


::method description class
    -- 'UTF-8 not-ASCII'
    use arg isASCII -- optional
    use strict named arg short(1)=.false, technical(1)=.false -- same as the instance method, not used (for the moment)
    if arg(1, "o") then return self~name
    if self~codeUnitSizeInBytes > 1 then return self~name -- doesn't make sense to include asciiness
    if isASCII then asciiness = "ASCII"
               else asciiness = "not-ASCII"
    return self~name asciiness


::method descriptionForError class
    forward message "description"


::method concatenate class
    -- Positional arguments : zero to N text or string.
    -- This method must be called from a subclass of StringIndexer
    -- Precondition: the encodings are compatible with self (you have checked that with .Encoding~forConcatenation)
    -- Remember: This method does not change the encoding of the buffer.
    --           Use .StringIndexer~append (inherited from .IndexerHelpers) to have the buffer's encoding updated.
    use arg ...
    use strict named arg buffer(1)=.nil
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new
    -- This method does not change the encoding of the buffer
    -- if \buffer~hasEncoding then buffer~encoding = self
    do i = 1 to arg()
        -- Only WTF-8 has a specific implementation of appendToBuffer.
        -- When concatenating WTF-8 with UTF-8 or ASCII, the target encoding (self) is WTF-8.
        arg(i)~encoding~appendToBuffer(arg(i)~string, :buffer)
    end
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self)


::method emptyString class
    expose emptyString
    use strict arg -- none
    if \var("emptyString") then emptyString = .RexxText~new("", self)
    return emptyString


::method spaceCharacter class
    expose spaceCharacter
    use strict arg -- none
    if \var("spaceCharacter") then spaceCharacter = self~encode(.Unicode~spaceCharacter~codepoint)
    return spaceCharacter


::method appendToBuffer class
    -- WTF-8 overrides this method
    use strict arg string
    use strict named arg buffer(1)
    buffer~append(string)


-- If you modify this method then see if forConcatenation must be modified as well
::method asEncodingFor class
    use strict arg buffer
    targetEncoding = self
    if \buffer~hasEncoding then return targetEncoding -- when no encoding then any encoding is compatible

    bufferEncoding = buffer~encoding
    bufferIsCompatibleWithASCII = buffer~isCompatibleWithASCII

    if bufferEncoding == targetEncoding then return bufferEncoding

    if bufferEncoding~isUTF8, targetEncoding~isWTF8 then return .WTF8_Encoding
    if bufferEncoding~isWTF8, targetEncoding~isUTF8 then return .WTF8_Encoding
    -- Keep the following tests after the previous tests, to keep the priority for WTF8
    -- Give priority to unicode over byte-encoding
    -- When unicode on both sides then give priority to the left encoding
    if bufferIsCompatibleWithASCII, (targetEncoding~isUTF8 | targetEncoding~isWTF8 | targetEncoding~isUnicode8) then do
        if bufferEncoding~isUnicode then return bufferEncoding
        return targetEncoding
    end
    -- I'm not sure if the next test is good...
    -- The good test is to test if the right part (here target) isCompatibleWithASCII
    -- but we have only the target encoding, not a real string to test.
    -- The implementation of isCompatibleWithASCII tests 2 things:
    --   - the encoding: (self~encoding~isByte | self~encoding~isUTF8 | self~encoding~isWTF8 | self~encoding~isUnicode8)
    --   - the asciiness of the string: self~string~isASCII
    -- Here, I test only the encoding. The asciiness will be tested elsewhere (for example in StringIndexer~append)
    if   (bufferEncoding~isUTF8 | bufferEncoding~isWTF8 | bufferEncoding~isUnicode8) -
       , (targetEncoding~isUTF8 | targetEncoding~isWTF8 | targetEncoding~isUnicode8) -
       -- , target~isASCII -
    then return bufferEncoding

    if bufferEncoding~isUTF16BE, targetEncoding~isWTF16BE then return .WTF16BE_Encoding
    if bufferEncoding~isWTF16BE, targetEncoding~isUTF16BE then return .WTF16BE_Encoding
    if bufferEncoding~isUTF16LE, targetEncoding~isWTF16LE then return .WTF16LE_Encoding
    if bufferEncoding~isWTF16LE, targetEncoding~isUTF16LE then return .WTF16LE_Encoding

    -- Consider that Unicode32 is never compatible with UTF-32BE or UTF-32LE
    -- even if it can be compatible in function of the CPU endianness.
    -- It's to ensure that if a program works on a little-endian CPU then it works on a big-endian CPU, and vice-versa.

    raise syntax 23.900 array("Encoding: cannot append" targetEncoding~description "to" buffer~descriptionForError)


/********************/
/* Instance methods */
/********************/

::attribute string get
::attribute string set private
::attribute maximumCodepoint get -- -1 if not calculated (Byte_Encoding doesn't calculate it)
::attribute codepointIndexes get private -- will be removed, no need of direct access to a codepoint
::attribute codepointCount get
::attribute graphemeIndexes get private
::attribute graphemeCount get
::attribute errors get
::attribute case get -- 1 lowercase, 2 uppercase


::method init
    expose string -
           maximumCodepoint codepointIndexes codepointCount -
           graphemeIndexes graphemeCount case errors
    use strict arg string, maximumCodepoint, codepointIndexes, codepointCount, graphemeIndexes, graphemeCount, case, errors
    self~init:super


::method copy
    -- No need to re-analyze the string, it's immutable:
    -- all the indexes are still applicable, just change the string referenced by the indexer.
    use strict arg -- none
    clone = self~copy:super
    clone~string = .string~new(clone~string) -- don't use ~copy (stack overflow)
    return clone


::method description
    /*
    "noël👩‍👨‍👩‍👧🎅"~text~description(s:1)          -- 'UTF-8 not-ASCII'
    "noël👩‍👨‍👩‍👧🎅"~text~description               -- 'UTF-8 not-ASCII (6 graphemes, 12 codepoints, 34 bytes, 0 error)'
    "noël👩‍👨‍👩‍👧🎅"~text~description(t:1)          -- 'UTF-8 not-ASCII (6 graphemes (3 indexes from index 4), 12 codepoints (9 indexes from index 4), 34 bytes, 0 error)'
    "noël👩‍👨‍👩‍👧🎅"~text~utf16~description(t:1)    -- 'UTF-16BE (6 graphemes (1 index from index 6), 12 codepoints (7 indexes from index 6), 34 bytes, 0 error)'
    "noël👩‍👨‍👩‍👧🎅"~text~utf32~description(t:1)    -- 'UTF-32BE (6 graphemes (1 index from index 6), 12 codepoints (0 index), 48 bytes, 0 error)'
    */
    use strict arg -- none
    use strict named arg short(1)=.false, technical(1)=.false
    if .nil == self~errors then errorCount = 0
                           else errorCount = self~errors~size
    techInfoCodepoints = ""
    techInfoGraphemes = ""
    if technical then do
        if .nil == self~codepointIndexes,
            then techInfoCodepoints = " (0 index)"
            else techInfoCodepoints = " ("self~codepointIndexes~items~singularPluralCount("index", "indexes")" from index "self~codepointIndexes~first")"
        if .nil == self~graphemeIndexes,
            then techInfoGraphemes = " (0 index)"
            else techInfoGraphemes = " ("self~graphemeIndexes~items~singularPluralCount("index", "indexes")" from index "self~graphemeIndexes~first")"
    end
    sizesDescription = ""
    if \short then sizesDescription = "(" ||,
                                      self~graphemes~count~singularPluralCount("grapheme", "graphemes")techInfoGraphemes",",
                                      self~codepoints~count~singularPluralCount("codepoint", "codepoints")techInfoCodepoints",",
                                      self~string~length~singularPluralCount("byte", "bytes")",",
                                      errorCount~singularPluralCount("error", "errors"),
                                      || ")"
    return " "~join(self~class~description(self~string~isASCII), sizesDescription)


::method descriptionForError
    -- Display the <length> first characters
    use strict arg length=10
    text = self~string~text
    if text~length > length then text = text~left(length - 3)"..."
    -- escape3 is needed to have a proper display for this:
    -- say "41"~text~utf16~string  -- 41
    -- say escape3("41"~text~utf16~string)  -- [00]4[00]1
    return self~description(s:1) "'"escape3(text~string)"'"


::method c2x
    use strict arg -- none
    codepoints = self~codepoints
    buffer = .MutableBuffer~new
    first = .true
    do while codepoints~available
        if \first then buffer~append(" ")
        first = .false
        codepoint = codepoints~item(.false) -- false: don't decode
        buffer~append(codepoint~c2x)
        codepoints~next
    end
    return buffer~string


::method c2u
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    codepoints = self~codepoints
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new
    first = .true
    do while codepoints~available
        if \first then buffer~append(" ")
        first = .false
        call ppCodepoint codepoints~item, :buffer
        codepoints~next
    end
    if returnBuffer then return buffer
                    else return buffer~string


::method c2g
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    graphemes = self~graphemes
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new
    first = .true
    do while graphemes~available
        if \first then buffer~append(" ")
        first = .false
        buffer~append(graphemes~item~string~c2x)
        graphemes~next
    end
    if returnBuffer then return buffer
                    else return buffer~string


::method codepoints
    use strict arg -- none
    return .CodePointSupplier~new(self)


::method codepoint abstract


::method characters
    use strict arg -- none
    return self~codepoints~each{.unicode~character(item)}


::method graphemes
    use strict arg -- none
    return .GraphemeSupplier~new(self)


::method grapheme abstract


::method isLower
    expose case
    return case == 1


::method isUpper
    expose case
    return case == 2


::method UTF8 abstract


::method WTF8 abstract


::method UTF16 abstract


::method UTF16BE abstract


::method UTF16LE abstract


::method WTF16 abstract


::method WTF16BE abstract


::method WTF16LE abstract


::method UTF32 abstract


::method UTF32BE abstract


::method UTF32LE abstract


::method Unicode abstract


::method Unicode8 abstract


::method Unicode16 abstract


::method Unicode32 abstract


/*
Executor supports
    \u{Unicode name}    Character name in the Unicode database
    \U{Unicode name}
    \u{X..X}            Unicode character denoted by 1-8 hex digits. The first character must be a digit 0..9 ('u' lowercase)
    \U{X..X}            Unicode character denoted by 1-8 hex digits. The first character must be a digit 0..9 ('U' uppercase)
    \uXXXX              Unicode character denoted by 4 hex digits ('u' lowercase)
    \UXXXXXXXX          Unicode character denoted by 8 hex digits ('U' uppercase)

How other languages are supporting escape characters for Unicode:
    \N{Unicode name}    Character name in the Unicode database (Python, Julia)
    \u{Unicode name}
    \U{Unicode name}
    \u{X..X}            Unicode character denoted by a 1–8 hex digits (Swift)
    \u{XXXXXX}          hexadecimal Unicode code point UTF-8 encoded (1 or more digits) (zig)
    \uXXXX              Unicode character denoted by four hex digits (Python, Julia, Netrexx, Java, JSON)
    \UXXXXXXXX          Unicode character denoted by eight hex digits (Python, Julia)

    https://javajee.com/unicode-escapes-in-java
    The compiler translates Unicode escapes into the characters they represent
    before it parses a program into tokens. It also does so before discarding
    comments and white space.
    System.out.println("a\u0022.length() + \u0022b".length()); // print 2
    is same as
    System.out.println("a".length() + "b".length());
*/
::method unescape abstract


::attribute isNFC get
    -- This comment is repeated in many places, update all of them!
    -- bit      9       8       7              6         5     4        3    2    1   0
    -- flag     stripNA stripCC stripIgnorable stripMark lump  casefold NFKD NFKC NFD NFC
    bitFlag = self~bitFlag(0)
    if bitFlag \== -1 then return bitFlag

    /*
    http://www.unicode.org/reports/tr15/#Implementation_Notes
    Text exclusively containing Latin-1 characters (U+0000..U+00FF) is left unaffected by NFC.
    This is effectively the same as saying that all Latin-1 text is already normalized to NFC
    ---
    Careful! The sentence above is NOT talking about ISO-8859-1 (alias Latin-1 )
    */
    if self~maximumCodepoint \== -1, self~maximumCodepoint <= 255 then do
        self~setBitFlag(0)
        return .true
    end

    return -1   -- unknown


::method NFC abstract


::attribute isNFD get
    -- This comment is repeated in many places, update all of them!
    -- bit      9       8       7              6         5     4        3    2    1   0
    -- flag     stripNA stripCC stripIgnorable stripMark lump  casefold NFKD NFKC NFD NFC
    bitFlag = self~bitFlag(1)
    if bitFlag \== -1 then return bitFlag

    -- http://www.unicode.org/reports/tr15/#Implementation_Notes
    -- Text exclusively containing ASCII characters (U+0000..U+007F) is left unaffected by all of the Normalization Forms
    if self~string~isCompatibleWithASCII then do
        self~setBitFlag(1)
        return .true
    end

    return -1   -- unknown


::method NFD abstract


::attribute isNFKC get
    -- This comment is repeated in many places, update all of them!
    -- bit      9       8       7              6         5     4        3    2    1   0
    -- flag     stripNA stripCC stripIgnorable stripMark lump  casefold NFKD NFKC NFD NFC
    bitFlag = self~bitFlag(2)
    if bitFlag \== -1 then return bitFlag

    -- http://www.unicode.org/reports/tr15/#Implementation_Notes
    -- Text exclusively containing ASCII characters (U+0000..U+007F) is left unaffected by all of the Normalization Forms
    if self~string~isCompatibleWithASCII then do
        self~setBitFlag(2)
        return .true
    end

    return -1   -- unknown


::method NFKC abstract


::attribute isNFKD get
    -- This comment is repeated in many places, update all of them!
    -- bit      9       8       7              6         5     4        3    2    1   0
    -- flag     stripNA stripCC stripIgnorable stripMark lump  casefold NFKD NFKC NFD NFC
    bitFlag = self~bitFlag(3)
    if bitFlag \== -1 then return bitFlag

    -- http://www.unicode.org/reports/tr15/#Implementation_Notes
    -- Text exclusively containing ASCII characters (U+0000..U+007F) is left unaffected by all of the Normalization Forms
    if self~string~isCompatibleWithASCII then do
        self~setBitFlag(3)
        return .true
    end

    return -1   -- unknown


::method NFKD abstract


::attribute isCasefold get
    -- This comment is repeated in many places, update all of them!
    -- bit      9       8       7              6         5     4        3    2    1   0
    -- flag     stripNA stripCC stripIgnorable stripMark lump  casefold NFKD NFKC NFD NFC
    return self~bitFlag(4)


::method casefold abstract


::attribute isLumped get
    -- This comment is repeated in many places, update all of them!
    -- bit      9       8       7              6         5     4        3    2    1   0
    -- flag     stripNA stripCC stripIgnorable stripMark lump  casefold NFKD NFKC NFD NFC
    return self~bitFlag(5)


::attribute isMarkStripped get
    -- This comment is repeated in many places, update all of them!
    -- bit      9       8       7              6         5     4        3    2    1   0
    -- flag     stripNA stripCC stripIgnorable stripMark lump  casefold NFKD NFKC NFD NFC
    return self~bitFlag(6)


::attribute isIgnorableStripped get
    -- This comment is repeated in many places, update all of them!
    -- bit      9       8       7              6         5     4        3    2    1   0
    -- flag     stripNA stripCC stripIgnorable stripMark lump  casefold NFKD NFKC NFD NFC
    return self~bitFlag(7)


::attribute isCCStripped get
    -- This comment is repeated in many places, update all of them!
    -- bit      9       8       7              6         5     4        3    2    1   0
    -- flag     stripNA stripCC stripIgnorable stripMark lump  casefold NFKD NFKC NFD NFC
    return self~bitFlag(8)


::attribute isNAStripped get
    -- This comment is repeated in many places, update all of them!
    -- bit      9       8       7              6         5     4        3    2    1   0
    -- flag     stripNA stripCC stripIgnorable stripMark lump  casefold NFKD NFKC NFD NFC
    return self~bitFlag(9)


/******************************************************************************/
::class "Byte_CommonServices" mixinclass Object private
-- Services for byte-oriented strings (byte, utf-8, wtf-8)

::method unescape
    -- The escape characters are used in literal strings, they should be managed
    -- at parse-time. Here, this method is used at run-time.
    -- This method could work for utf-16, wtf-16, utf-32 if it was rewritten
    -- to use RexxText API instead of String API. But would be way slower...
    -- Would it make sense ? Nobody is editing literal strings encoded in 16-bit
    -- or 32-bit.
    use strict named arg buffer(1)=.nil
    string = self~string
    pos = string~pos("\")
    if pos == 0 then do
        -- optim: don't create intermediate buffer if nothing to unescape
        if .nil == buffer then return self~string~text
        return buffer~~append(string)
    end
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new(, string~length)
    from = 1
    do until pos == 0
        buffer~append(string~substr(from, pos - from))
        pos += 1
        character = string~subchar(pos)
        pos += 1
        select
            when character == "\" then buffer~append("\")   -- escaped \
            when character == "a" then buffer~append("07"x) -- audible bell (BEL)
            when character == "b" then buffer~append("08"x) -- backspace (BS)
            when character == "f" then buffer~append("0C"x) -- form feed (FF)
            when character == "n" then buffer~append("0A"x) -- linefeed (LF)
            when character == "r" then buffer~append("0D"x) -- carriage return (CR)
            when character == "t" then buffer~append("09"x) -- horizontal tab (HT)
            when character == "v" then buffer~append("0B"x) -- vertical tab (VT)

            when character == "u" | character == "U" then do
                if \self~isUnicode then signal unicode_character_not_supported

                -- \u{Unicode name}    Character name in the Unicode database
                -- \u{X..X}            Unicode character denoted by 1-8 hex digits
                if string~subchar(pos) == "{" then do
                    pos += 1 -- skip {
                    first = pos
                    pos = string~pos("}", pos)
                    if pos == 0 then signal expecting_name_or_sequence_of_hexadecimal_digits
                    length = pos - first
                    if length == 0 then signal expecting_name_or_sequence_of_hexadecimal_digits
                    pos += 1 -- skip }
                    idntfr = string~substr(first, length)
                    startWithDigit = idntfr~left(1)~datatype("9")
                    character = .Unicode~character(idntfr, hexadecimal: startWithDigit)
                    character~text(self~class, :buffer)
                end

                else if character == "u" then do
                    -- \uXXXX
                    length = min(4, string~length - pos + 1)
                    codepoint = string~substr(pos, length)
                    if codepoint~length < 4 then signal expecting_4_hexadecimal_digits
                    if \codepoint~datatype("X") then signal expecting_4_hexadecimal_digits
                    character = .Unicode~character(codepoint, hexadecimal: .true)
                    character~text(self~class, :buffer)
                    pos += 4
                end

                else if character == "U" then do
                    -- \uXXXXXXXX
                    length = min(8, string~length - pos + 1)
                    codepoint = string~substr(pos, length)
                    if codepoint~length < 8 then signal expecting_8_hexadecimal_digits
                    if \codepoint~datatype("X") then signal expecting_8_hexadecimal_digits
                    character = .Unicode~character(codepoint, hexadecimal: .true)
                    character~text(self~class, :buffer)
                    pos += 8
                end

            end

            when character == "x" then do
                -- \x{X..X} sequence of 1..n hexadecimal digits
                if string~subchar(pos) \== "{" then signal expecting_sequence_of_hexadecimal_digits
                pos += 1 -- skip {
                first = pos
                pos = string~pos("}", pos)
                if pos == 0 then signal expecting_sequence_of_hexadecimal_digits
                length = pos - first
                if length == 0 then signal expecting_sequence_of_hexadecimal_digits
                pos += 1 -- skip }
                hexadecimalDigits = string~substr(first, length)
                characters = hexadecimalDigits~x2c -- 1..n bytes
                buffer~append(characters)
            end

            otherwise signal unsupported_escape_character
        end
        from = pos
        pos = string~pos("\", from)
    end
    buffer~append(string~substr(from))

    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self~class)

    unicode_character_not_supported:                  raise syntax 23.900 array(self~class~name "encoding: \"character" not supported")
    expecting_name_or_sequence_of_hexadecimal_digits: raise syntax 23.900 array(self~class~name "encoding: expecting a character name {name} or 1..8 hexadecimal digits {X..X} after \u")
    expecting_4_hexadecimal_digits:                   raise syntax 23.900 array(self~class~name "encoding: expecting 4 hexadecimal digits after \u, got '"codepoint"'")
    expecting_8_hexadecimal_digits:                   raise syntax 23.900 array(self~class~name "encoding: expecting 8 hexadecimal digits after \U, got '"codepoint"'")
    expecting_sequence_of_hexadecimal_digits:         raise syntax 23.900 array(self~class~name "encoding: expecting 1..n hexadecimal digits {X..X} after \x")
    unsupported_escape_character:                     raise syntax 23.900 array(self~class~name "encoding: escape character '"character"' not supported")


/******************************************************************************/
::class "Byte_Encoding" public inherit Byte_CommonServices StringIndexer

::constant name "Byte"
::constant isByte 1
::constant codeUnitSizeInBytes 1
::constant codepointMaxBytes 1


::method analyze class
    use strict arg string
    sizeB = string~length -- size in bytes
    case = 0
    if string~datatype("L") then case = 1
    if case == 0,  string~datatype("U") then case = 2
    -- Bytes, codepoints and graphemes are identical
    -- The string holds all the needed informations, no need to calculate indexes
    -- The maximum codepoint is not calculated: -1
    return self~new(string, -1, .nil, sizeB, .nil, sizeB, case, .nil)


::method checkCodepoint class
    -- Remember : previousCodepoint can be .nil (first codepoint) or <0 (error recovery)
    --            when <0 abs(previousCodepoint) is the invalid value
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg checkOnlyRange /*no impact here*/, errorInfo=.nil
    if .nil <> codepoint then do
        if codepoint < 0 | codepoint > 255 then signal error_range
    end
    return 1 -- a positive value means "no error"

    -- Don't use ppCodepoint here, it's not Unicode.
    error_range: return error(0, self~name "encoding: invalid codepoint" codepoint "("ppHexNumber(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..255")

    error:
        use strict arg whichCodepoint, errorMessage
        if .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return whichCodepoint -- -1 (previousCodepoint) or 0 (codepoint). A negative or null value means "error".
        end
        raise syntax 23.900 array (errorMessage)


::method decode class
    -- sizeB == -1 ==> this method will check the validity of the encoding
    -- sizeB <> -1 ==> this method assumes that the encoding has been checked and is valid
    use strict arg string /* or buffer */, startB=1, sizeB=(-1)
    if sizeB == -1 then do
        nextB = self~nextCodepointIndex(string, startB) -- raise error if invalid, so no need to test if < 0
        sizeB = nextB - startB
    end
    if sizeB == 0 then return .nil
    if sizeB == 1 then return string~subchar(startB)~c2d
    raise syntax 23.900 array (self~name "encoding:" sizeB "is an invalid size of byte sequence")


::method byteSequenceSize class
    -- Fast, minimal checks.
    -- Typical usage:
    --     encoding~decode(string, startB, encoding~byteSequenceSize(string, startB))
    -- By passing a non-negative size to ~decode, the checks are disabled.
    use strict arg string /* or buffer */, startB=1
    if startB > string~length then return 0
    return 1


::method nextCodepointIndex class
    use strict arg string /* or buffer */, startB
    -- use named arg errorInfo=.nil
    if startB < 1 then return startB -- don't move because below start of string
    if startB > string~length then return startB -- don't move because beyond end of string
    return startB + 1


::method previousCodepointIndex class
    -- indexB is the index of the first byte of the current codepoint
    --   cp1  |cp2  |cp3...
    --   byte1|byte2|byte3...
    --   1    |2    |3
    -- For example, if indexB==3 then previousCodepointIndex==2
    use strict arg string /* or buffer */, startB
    if string~length == 0 then return startB -- don't move because empty string
    if startB <= 1 then return startB -- don't move because at start of string or before
    if startB > (string~length + 1) then return startB -- don't move because beyond the end of string
    return startB - 1


::method encode class
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg codepoint
    use strict named arg buffer(1)=.nil
    self~checkCodepoint(codepoint, checkOnlyRange: .true) -- check only range, the other errors will be detected during analysis
    if .nil <> buffer then return buffer~~append(codepoint~d2c)
                      else return .RexxText~new(codepoint~d2c, self)


::method codepointSizeInBytes class
    use strict arg codepoint
    self~checkCodepoint(codepoint, checkOnlyRange: .true)
    return 1


::method codepointToLower class
    use strict arg codepoint
    if 65 <= codepoint, codepoint <= 90 then return codepoint + 32
    return codepoint


::method codepointToUpper class
    use strict arg codepoint
    if 97 <= codepoint, codepoint <= 122 then return codepoint - 32
    return codepoint


::method codepointToTitle class
    use strict arg codepoint
    if 97 <= codepoint, codepoint <= 122 then return codepoint - 32
    return codepoint


::method tableTranscodingToUnicode class
    use strict arg -- none
    return .nil


/********************/
/* Instance methods */
/********************/

::method codepointIndex
    use strict arg indexC
    if indexC < 1 then raise syntax 23.900 array (self~description "invalid codepoint index:" indexC)
    if indexC > self~codepointCount then indexC = self~codepointCount + 1
    return indexC


::method codepoint
    use strict arg indexC, decode=.true
    startB = self~codepointIndex(indexC)
    if decode then return self~string~subchar(startB)~c2d
              else return self~string~subchar(startB)


::method graphemeIndex
    use strict arg indexG
    if indexG < 1 then raise syntax 23.900 array (self~description "invalid grapheme index:" indexG)
    if indexG > self~graphemeCount then indexG = self~string~length + 1
    return indexG


::method grapheme
    -- 2 modes:
    -- if the buffer is passed as argument then append the grapheme to the buffer, and return the buffer
    -- otherwise return the grapheme as a RexxText
    use strict arg indexG
    use strict named arg buffer(1)=.nil
    startB = abs(self~graphemeIndex(indexG))
    if .nil <> buffer then return buffer~~append(self~string~subchar(startB))
                      else return .RexxText~new(self~string~subchar(startB), self~class)


::method maximumUnicodeCodepoint private
    -- Needed when converting to Unicode_Encoding (1st pass: get the maxium codepoint)
    -- Don't do any check, will be done by convertByteToUnicode (2nd pass)
    expose maximumUnicodeCodepoint -- cached
    use strict arg -- none
    if var("maximumUnicodeCodepoint") then return maximumUnicodeCodepoint
    maximumUnicodeCodepoint = 0
    tableTranscodingToUnicode = self~class~tableTranscodingToUnicode
    if .nil <> tableTranscodingToUnicode then do
        sizeC = self~codepointCount -- size in codepoints
        do i=1 to sizeC
            charcode = self~codepoint(i)
            codepoint = tableTranscodingToUnicode[charcode+1] -- bof bof... 1-based array
            -- An empty string means no mapping
            -- A negative codepoint means unused character with fallback mapping
            if codepoint <> "" then maximumUnicodeCodepoint = max(maximumUnicodeCodepoint, abs(codepoint))
        end
    end
    return maximumUnicodeCodepoint


::method convertByteToUnicode private
    use strict arg targetEncoding
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil

    tableTranscodingToUnicode = self~class~tableTranscodingToUnicode
    if .nil == tableTranscodingToUnicode then signal cannot_convert

    string = self~getCachedString(targetEncoding)
    if .nil \== string then do
        if .nil <> buffer then return targetEncoding~append(string, :buffer)
                          else return string~text
    end

    sizeC = self~codepointCount -- size in codepoints
    returnBuffer = .nil <> buffer

    if .nil == buffer then do
        buffer = .MutableBuffer~new(, sizeC * targetEncoding~codepointMaxBytes)
        buffer~encoding = targetEncoding
    end
    else do
        buffer~encoding = targetEncoding~asEncodingFor(buffer) -- raise an error if not compatible
    end

    bufferStart = buffer~length + 1
    do i=1 to sizeC
        charcode = self~codepoint(i)
        codepoint = tableTranscodingToUnicode[charcode+1] -- bof bof... 1-based array
        -- An empty string means no mapping
        -- A negative codepoint means unused character with fallback mapping
        if codepoint == "" | (codepoint < 0 & strict) then raise syntax 23.900 array(self~name "encoding: cannot convert" self~description(short: .true) "character" charcode "("charcode~d2x") at byte-position" i "to" targetEncoding~name)
        targetEncoding~encode(abs(codepoint), :buffer)
    end

    string = buffer~substr(bufferStart)
    -- It's a new string, without any encoding stored on it
    string~encoding = targetEncoding
    if memorize then self~cacheString(targetEncoding, string)

    if returnBuffer then return buffer
    text = .RexxText~new(string, targetEncoding)
    if memorize then text~internalIndexer~cacheString(self~class, self~string)
    return text

    cannot_convert:          raise syntax 23.900 array(self~class~name "encoding: cannot convert" self~description(short: .true) "to" targetEncoding~name)


::method UTF8
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    targetEncoding = .UTF8_Encoding
    if self~string~isASCII then do
        if .nil <> buffer then return targetEncoding~append(self~string, :buffer)

        string = self~getCachedString(targetEncoding)
        if .nil \== string then return string~text

        -- yes, always a new string. The original string is still associated to the Byte_Encoding.
        -- Don't use string~copy, because the reference to the associated text is in the copy,
        -- and that forbids to assign a new RexxText.
        text = .RexxText~new(.String~new(self~string), targetEncoding)
        if memorize then do
            self~cacheString(targetEncoding, text~string)
            text~internalIndexer~cacheString(self~class, self~string)
        end
        return text
    end
    else do
        return self~convertByteToUnicode(targetEncoding, :strict, :memorize, :buffer)
    end


::method WTF8
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    targetEncoding = .WTF8_Encoding
    if self~string~isASCII then do
        if .nil <> buffer then return targetEncoding~append(self~string, :buffer)

        string = self~getCachedString(targetEncoding)
        if .nil \== string then return string~text

        -- yes, always a new string. The original string is still associated to the Byte_Encoding.
        -- Don't use string~copy, because the reference to the associated text is in the copy,
        -- and that forbids to assign a new RexxText.
        text = .RexxText~new(.String~new(self~string), targetEncoding)
        if memorize then do
            self~cacheString(targetEncoding, text~string)
            text~internalIndexer~cacheString(self~class, self~string)
        end
        return text
    end
    else do
        return self~convertByteToUnicode(targetEncoding, :strict, :memorize, :buffer)
    end


::method UTF16
    forward message "UTF16BE"


::method UTF16BE
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    if self~string~isASCII then return .UTF16BE_Encoding~encodeASCIIstring(self~string, :memorize, :buffer)
                           else return self~convertByteToUnicode(.UTF16BE_Encoding, :strict, :memorize, :buffer)


::method UTF16LE
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    if self~string~isASCII then return .UTF16LE_Encoding~encodeASCIIstring(self~string, :memorize, :buffer)
                           else return self~convertByteToUnicode(.UTF16LE_Encoding, :strict, :memorize, :buffer)


::method WTF16
    forward message "WTF16BE"


::method WTF16BE
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    if self~string~isASCII then return .WTF16BE_Encoding~encodeASCIIstring(self~string, :memorize, :buffer)
                           else return self~convertByteToUnicode(.WTF16BE_Encoding, :strict, :memorize, :buffer)


::method WTF16LE
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    if self~string~isASCII then return .WTF16LE_Encoding~encodeASCIIstring(self~string, :memorize, :buffer)
                           else return self~convertByteToUnicode(.WTF16LE_Encoding, :strict, :memorize, :buffer)


::method UTF32
    forward message "UTF32BE"


::method UTF32BE
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    if self~string~isASCII then return .UTF32BE_Encoding~encodeASCIIstring(self~string, :memorize, :buffer)
                           else return self~convertByteToUnicode(.UTF32BE_Encoding, :strict, :memorize, :buffer)


::method UTF32LE
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    if self~string~isASCII then return .UTF32LE_Encoding~encodeASCIIstring(self~string, :memorize, :buffer)
                           else return self~convertByteToUnicode(.UTF32LE_Encoding, :strict, :memorize, :buffer)


::method Unicode
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    if self~string~isASCII then forward message "Unicode8"
    else do
        targetEncoding = .Unicode_Encoding~toSupport(self~maximumUnicodeCodepoint)
        return self~convertByteToUnicode(targetEncoding, :strict, :memorize, :buffer)
    end


::method Unicode8
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    targetEncoding = .Unicode8_Encoding
    if self~string~isASCII then do
        if .nil <> buffer then return targetEncoding~append(self~string, :buffer)

        string = self~getCachedString(targetEncoding)
        if .nil \== string then return string~text

        -- yes, always a new string. The original string is still associated to the Byte_Encoding.
        -- Don't use string~copy, because the reference to the associated text is in the copy,
        -- and that forbids to assign a new RexxText.
        text = .RexxText~new(.String~new(self~string), targetEncoding)
        if memorize then do
            self~cacheString(targetEncoding, text~string)
            text~internalIndexer~cacheString(self~class, self~string)
        end
        return text
    end
    else return self~convertByteToUnicode(targetEncoding, :strict, :memorize, :buffer)


::method Unicode16
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    if self~string~isASCII then return .Unicode16_Encoding~encodeASCIIstring(self~string, :memorize, :buffer)
                           else return self~convertByteToUnicode(.Unicode16_Encoding, :strict, :memorize, :buffer)


::method Unicode32
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    if self~string~isASCII then return .Unicode32_Encoding~encodeASCIIstring(self~string, :memorize, :buffer)
                           else return self~convertByteToUnicode(.Unicode32_Encoding, :strict, :memorize, :buffer)


/******************************************************************************/
::class "CP1252_Encoding" subclass Byte_Encoding public
-- alias Window-1252

::constant name "CP1252"


::attribute tableTranscodingToUnicode class get


::method activate class
    -- https://en.wikipedia.org/wiki/Windows-1252#Code_page_layout
    -- According to the information on Microsoft's and the Unicode Consortium's websites,
    -- positions 81, 8D, 8F, 90, and 9D are unused;
    -- however, the Windows API MultiByteToWideChar maps these to the corresponding C1 control codes.
    expose tableTranscodingToUnicode
    use strict arg -- none
    specificTranscoding =,
        , --        00      01      02      03      04      05      06      07      08      09      0A      0B      0C      0D      0E      0F
        "80:",  "20AC",  "-81", "201A", "0192", "201E", "2026", "2020", "2021", "02C6", "2030", "0160", "2039", "0152",  "-8D", "017D",  "-8F",,
        "90:",   "-90", "2018", "2019", "201C", "201D", "2022", "2013", "2014", "02DC", "2122", "0161", "203A", "0153",  "-9D", "017E", "0178"
    tableTranscodingToUnicode = createCharacterTranscodingTable(256, specificTranscoding)


/******************************************************************************/
::class "ISO88591_Encoding" subclass Byte_Encoding public
-- many aliases

::constant name "ISO-8859-1"


::attribute tableTranscodingToUnicode class get


::method activate class
    -- https://en.wikipedia.org/wiki/ISO/IEC_8859-1#Code_page_layout
    -- TODO: It's not clear to me if I should follow the rule below, i.e. returning the CP1252 characters 128 to 159.
    /*
        https://www.w3schools.com/charsets/
            When a browser detects ISO-8859-1 it normally defaults to Windows-1252, because
            Windows-1252 has 32 more international characters.
        https://www.w3schools.com/charsets/ref_html_8859.asp
            ISO-8859-1 is very similar to Windows-1252.
            In ISO-8859-1, the characters from 128 to 159 are not defined.
            In Windows-1252, the characters from 128 to 159 are used for some useful symbols.
            Since many web sites declare ISO-8859-1 and use the values from 128 to 159 as if
            they were using Windows-1252, most browsers will display these characters from
            the Windows-1252 character set instead of nothing.
    */
    expose tableTranscodingToUnicode
    use strict arg -- none
    specificTranscoding =,
        , --        00      01      02      03      04      05      06      07      08      09      0A      0B      0C      0D      0E      0F
        "00:",      "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",,
        "10:",      "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",,
        "7F:",                                                                                                                              "",,
        "80:",      "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",,
        "90:",      "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     "",     ""
    tableTranscodingToUnicode = createCharacterTranscodingTable(256, specificTranscoding)


/******************************************************************************/
::class "Unicode_CommonServices" mixinclass Object private

::constant isUnicode 1


::method analyze class
    forward message "createIndexer"


::method createIndexer class
    use strict arg string
    maximumCodepoint = 0
    codepointIndexes = .array~new -- sparse array: only the string indexes different from the array index are stored
    graphemeIndexes = .array~new -- idem
    codepointCount = 0
    graphemeCount = 0
    errors = .nil
    indexB = 1
    previousCodepoint = .nil
    previousCodepointIndexB = .nil
    graphemeBreakArgs = (.nil, .nil, 0) -- codepoint1, codepoint2, state. Will use the same array at each iteration.
    case = 3 -- bitor(2,1) both isUpper isLower

    encoding = self
    errorInfo = .array~new(1) -- simulate a variable reference: errorInfo[1] = errorMessage
    forever:
        codepoint = .nil
        nextB = encoding~nextCodepointIndex(string, indexB, :errorInfo)
        if nextB < 0 then signal error
        codepoint = encoding~decode(string, indexB, nextB - indexB) -- codepoint can be .nil if nextB == indexB

        -- Remember : previousCodepoint can be .nil (first codepoint) or <0 (error recovery)
        checkResult = encoding~checkCodepoint(codepoint, indexB, previousCodepoint, previousCodepointIndexB, :errorInfo)
        if checkResult == -1 then do
            -- The byte-sequence starting at previousCodepointIndexB is invalid,
            -- undo the last index
            -- currently, that can happen only for WTF-8 in case of high-surrogate followed by a low-surrogate
            codepointCount -= 1
            graphemeCount -= 1
            indexB = previousCodepointIndexB
            nextB = indexB + self~codeUnitSizeInBytes -- add 1 or 2 or 4
            signal error
        end
        else if checkResult == 0 then do
            -- The byte-sequence starting at indexB is invalid,
            nextB = indexB + self~codeUnitSizeInBytes -- add 1 or 2 or 4
            signal error
        end

        -- From here, we know that the current codepoint is valid
        if .nil == codepoint then signal leave -- End of string
        call indexCodepoint
        if .nil == previousCodepoint then call indexGrapheme -- First codepoint
        else if previousCodepoint < 0 then call indexGrapheme -- Error recovery
        else do
            graphemeBreakArgs[1] = previousCodepoint
            graphemeBreakArgs[2] = codepoint
            if .Unicode~utf8proc_graphemeBreak(graphemeBreakArgs) then call indexGrapheme
        end
        call checkCase
        previousCodepoint = codepoint
        previousCodepointIndexB = indexB
        indexB = nextB
    signal forever
    leave:

    -- Optimization if no need of indexes (when direct access is possible)
    if codepointIndexes~size == 0 then codepointIndexes = .nil
    if graphemeIndexes~size == 0 then graphemeIndexes = .nil
    return encoding~new(string, maximumCodepoint, codepointIndexes, codepointCount, graphemeIndexes, graphemeCount, case, errors)

    /*
        No need to store the string indexes which can be calculated from the array index.
        All the string indexes below can be calculated:
        index   UTF-8   UTF-16  UTF-32
          1       1       1       1
          2       2       3       5
          3       3       5       9
          ...
    */
    indexCodepoint:
        codepointCount += 1
        if indexB <> self~codeUnitSizeInBytes * (codepointCount -1) + 1 then do
            codepointIndexes[codepointCount] = indexB
        end
        maximumCodepoint = max(maximumCodepoint, codepoint)
        return

    indexGrapheme:
        graphemeCount += 1
        if indexB <> self~codeUnitSizeInBytes * (graphemeCount -1) + 1 then do
            graphemeIndexes[graphemeCount] = indexB
        end
        return

    checkCase:
        if case <> 0 then do
            if case == 1, \.Unicode~utf8proc_codepointIsLower(codepoint) then case = 0
            else if case == 2, \.Unicode~utf8proc_codepointIsUpper(codepoint) then case = 0
            else do -- case == 3
                if .Unicode~utf8proc_codepointIsLower(codepoint) then case = 1 -- can no longer be upper
                else if .Unicode~utf8proc_codepointIsUpper(codepoint) then case = 2 -- can no longer be lower
                else case = 0 -- can no longer be lower or upper
            end
        end
        return

    error:
        if .nil == errors then errors = .array~new
        errors~append(errorInfo[1])
        -- follow the recommendation of W3C : U+FFFD Substitution of Maximal Subparts
        nextB = abs(nextB)
        codepointCount += 1
        codepointIndexes[codepointCount] = -indexB -- a negative index means "error", a replacement character will be returned
        maximumCodepoint = max(maximumCodepoint, .Unicode~replacementCharacter~codepoint)
        graphemeCount += 1
        graphemeIndexes[graphemeCount] = -indexB -- idem
        graphemeBreakArgs[3] = 0 -- reset the extended grapheme state
        previousCodepoint = codepoint
        if .nil <> codepoint then previousCodepoint = -codepoint -- Negative codepoint allows to get the original value, if needed, while knowing it's invalid
        previousCodepointIndexB = indexB
        indexB = nextB -- resume at the next valid code unit
        signal forever


::method codepointToLower class
    use strict arg codepoint
    return .Unicode~utf8proc_codepointToLower(codepoint)


::method codepointToUpper class
    use strict arg codepoint
    return .Unicode~utf8proc_codepointToUpper(codepoint)


::method codepointToTitle class
    use strict arg codepoint
    return .Unicode~utf8proc_codepointToTitle(codepoint)


/********************/
/* Instance methods */
/********************/

::method convertUnicodeToUnicode
    /*
    D93 Encoding form conversion:
    A conversion defined directly between the code unit sequences of one Unicode
    encoding form and the code unit sequences of another Unicode encoding form.
    - In implementations of the Unicode Standard, a typical API will logically
      convert the input code unit sequence into Unicode scalar values (code points)
      and then convert those Unicode scalar values into the output code unit sequence.
      Proper analysis of the encoding forms makes it possible to convert the code units
      directly, thereby obtaining the same results but with a more efficient process.
    - A conformant encoding form conversion will treat any ill-formed code unit
      sequence as an error condition. (See conformance clause C10.) This guarantees
      that it will neither interpret nor emit an ill-formed code unit sequence.
      Any implementation of encoding form conversion must take this requirement
      into account, because an encoding form conversion implicitly involves a
      verification that the Unicode strings being converted do, in fact, contain
      well-formed code unit sequences.
    */
    use strict arg targetEncoding
    use strict named arg strict = .false, memorize(3) = (.Unicode~memorizeConversions), buffer(1) = .nil

    string = .nil
    if self~class == targetEncoding then string = self~string
    else string = self~getCachedString(targetEncoding)
    if .nil \== string then do
        if .nil <> buffer then return targetEncoding~append(string, :buffer) -- buffer~~append(string)
                          else return string~text
    end

/*
    if self~class == targetEncoding then do
        if .nil <> buffer then return self~class~concatenate(self~string, buffer) -- buffer~~append(self~string)
                          else return self~string~text
    end
*/

    sizeC = self~codepointCount -- size in codepoints
    returnBuffer = .nil \== buffer
    if .nil == buffer then buffer = .MutableBuffer~new(, sizeC * targetEncoding~codepointMaxBytes)
    buffer~encoding = targetEncoding~asEncodingFor(buffer) -- raise an error if not compatible
    bufferStart = buffer~length + 1
    do i=1 to sizeC
        codepoint = self~codepoint(i)
        targetEncoding~encode(codepoint, :buffer) -- WTF-8 is correctly managed (use appendToBuffer)
    end
    string = buffer~substr(bufferStart)
    -- It's a new string, without any encoding stored on it
    string~encoding = targetEncoding
    if memorize then self~cacheString(targetEncoding, string)

    if returnBuffer then return buffer
    text = .RexxText~new(string, targetEncoding)
    if memorize then text~internalIndexer~cacheString(self~class, self~string)
    return text


::method UTF8
    use strict arg -- none
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    return self~convertUnicodeToUnicode(.UTF8_Encoding, :strict, :memorize, :buffer)


::method WTF8
    use strict arg -- none
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    return self~convertUnicodeToUnicode(.WTF8_Encoding, :strict, :memorize, :buffer)


::method UTF16
    forward message "UTF16BE"


::method UTF16BE
    use strict arg -- none
    use strict named arg strict = .false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    return self~convertUnicodeToUnicode(.UTF16BE_Encoding, :strict, :memorize, :buffer)


::method UTF16LE
    use strict arg -- none
    use strict named arg strict = .false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    return self~convertUnicodeToUnicode(.UTF16LE_Encoding, :strict, :memorize, :buffer)


::method WTF16
    forward message "WTF16BE"


::method WTF16BE
    use strict arg -- none
    use strict named arg strict = .false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    return self~convertUnicodeToUnicode(.WTF16BE_Encoding, :strict, :memorize, :buffer)


::method WTF16LE
    use strict arg -- none
    use strict named arg strict = .false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    return self~convertUnicodeToUnicode(.WTF16LE_Encoding, :strict, :memorize, :buffer)


::method UTF32
    forward message "UTF32BE"


::method UTF32BE
    use strict arg -- none
    use strict named arg strict = .false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    return self~convertUnicodeToUnicode(.UTF32BE_Encoding, :strict, :memorize, :buffer)


::method UTF32LE
    use strict arg -- none
    use strict named arg strict = .false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    return self~convertUnicodeToUnicode(.UTF32LE_Encoding, :strict, :memorize, :buffer)


::method Unicode
    use strict arg -- none
    use strict named arg strict = .false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    targetEncoding = .Unicode_Encoding~toSupport(self~maximumCodepoint)
    return self~convertUnicodeToUnicode(targetEncoding, :strict, :memorize, :buffer)


::method Unicode8
    use strict arg -- none
    use strict named arg strict = .false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    .Unicode8_Encoding~checkCodepoint(self~maximumCodepoint, checkingMaximumCodepoint: .true)
    return self~convertUnicodeToUnicode(.Unicode8_Encoding, :strict, :memorize, :buffer)


::method Unicode16
    use strict arg -- none
    use strict named arg strict = .false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    .Unicode16_Encoding~checkCodepoint(self~maximumCodepoint, checkingMaximumCodepoint: .true)
    return self~convertUnicodeToUnicode(.Unicode16_Encoding, :strict, :memorize, :buffer)


::method Unicode32
    use strict arg -- none
    use strict named arg strict = .false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    .Unicode32_Encoding~checkCodepoint(self~maximumCodepoint, checkingMaximumCodepoint: .true)
    return self~convertUnicodeToUnicode(.Unicode32_Encoding, :strict, :memorize, :buffer)


/******************************************************************************/
::class "XTF8_CommonServices" mixinclass Object private
-- where X stands for U or W

::constant codeUnitSizeInBytes 1
::constant codepointMaxBytes 4 -- In UTF-8, a codepoint can be from 1 to 4 bytes


/*
::method analyze class
    use strict arg string
    -- Bad idea! Must always analyze because CR+LF is a grapheme.
    -- sizeB = string~length -- size in bytes
    -- if string~isASCII then return self~new(string, .nil, sizeB, .nil, sizeB) -- no indexation needed
    return self~createIndexer(string)
*/


::method decode class
    -- sizeB == -1 ==> this method will check the validity of the encoding
    -- sizeB <> -1 ==> this method assumes that the encoding has been checked and is valid
    use strict arg string /* or buffer */, startB=1, sizeB=(-1)
    if sizeB == -1 then do
        nextB = self~nextCodepointIndex(string, startB) -- raise error if invalid, so no need to test if < 0
        sizeB = nextB - startB
    end
    -- numeric digits 10 -- not needed, the greatest possible value is .utf8_encoding~decode("FF FF FF FF"x, 1, 4) = 2 097 151 (7 digits)
    if sizeB == 0 then return .nil -- end of string
    if sizeB == 1 then return decodeByte(0, "7F"x)
    if sizeB == 2 then return decodeByte(0, "1F"x)  *     64 + decodeByte(1, "3F"x)
    if sizeB == 3 then return decodeByte(0, "0F"x)  *   4096 + decodeByte(1, "3F"x) *   64 +  + decodeByte(2, "3F"x)
    if sizeB == 4 then return decodeByte(0, "07"x)  * 262144 + decodeByte(1, "3F"x) * 4096 +  + decodeByte(2, "3F"x) * 64 + decodeByte(3, "3F"x)
    raise syntax 23.900 array (self~name "encoding:" sizeB "is an invalid size of byte sequence")

    decodeByte: procedure expose string startB
        use strict arg offset, mask
        return string~subchar(startB + offset)~bitand(mask)~c2d


::method byteSequenceSize class
    -- Fast, minimal checks.
    -- Typical usage:
    --     encoding~decode(string, startB, encoding~byteSequenceSize(string, startB))
    -- By passing a non-negative size to ~decode, the checks are disabled.
    -- CAREFUL! The returned size can be different from the size that would be derived from nextCodepointIndex
    use strict arg string /* or buffer */, startB=1
    startByte = string~subchar(startB)
    if startByte == "" then return 0
    if startByte < "80"x then return 1                     -- 1-byte sequence 0xxxxxxx
    else if startByte~bitand("E0"x) == "C0"x then return 2 -- 2-byte sequence 110xxxxx (C0..DF but only C2..DF is valid)
    else if startByte~bitand("F0"x) == "E0"x then return 3 -- 3-byte sequence 1110xxxx
    else if startByte~bitand("F8"x) == "F0"x then return 4 -- 4-byte sequence 11110xxx
    return -1


::method nextCodepointIndex class
    /*
        Table 3-7. Well-Formed UTF-8 Byte Sequences
            Code Points         First Byte  Second Byte     Third Byte      Fourth Byte
            U+0000..U+007F      00..7F
            U+0080..U+07FF      C2..DF      80..BF                                  CAREFUL! 1st byte C0 and C1 are invalid (non-shortest form)
            U+0800..U+0FFF      E0          A0..BF          80..BF                  CAREFUL! 2nd byte 80..9F are invalid
            U+1000..U+CFFF      E1..EC      80..BF          80..BF
            U+D000..U+D7FF      ED          80..9F          80..BF                  CAREFUL! 2nd byte A0..BF are invalid (high/low surrogate)
            U+E000..U+FFFF      EE..EF      80..BF          80..BF
            U+10000..U+3FFFF    F0          90..BF          80..BF          80..BF  CAREFUL! 2nd byte 80..8F are invalid (non-shortest form)
            U+40000..U+FFFFF    F1..F3      80..BF          80..BF          80..BF
            U+100000..U+10FFFF  F4          80..8F          80..BF          80..BF  CAREFUL! 2nd byte 90..BF are invalid (codepoint > U+10FFFF)
        As a consequence of the well-formedness conditions specified in Table 3-7,
        the following byte values are disallowed in UTF-8:
        C0–C1, F5–FF.

        If the converter encounters an ill-formed UTF-8 code unit sequence which
        starts with a valid first byte, but which does not continue with valid
        successor bytes (see Table 3-7), it must not consume the successor bytes
        as part of the ill-formed subsequence whenever those successor bytes
        themselves constitute part of a well-formed UTF-8 code unit subsequence.
        For example, with the input UTF-8 code unit sequence <C2 41 42>, such a
        UTF-8 conversion process must not return <U+FFFD> or <U+FFFD, U+0042>,
        because either of those outputs would be the result of misinterpreting a
        well-formed subsequence as being part of the ill-formed subsequence. The
        expected return value for such a process would instead be <U+FFFD, U+0041, U+0042>.

        Although a UTF-8 conversion process is required to never consume well-
        formed subsequences as part of its error handling for ill-formed
        subsequences, such a process is not otherwise constrained in how it
        deals with any ill-formed subsequence itself. An ill-formed subsequence
        consisting of more than one code unit could be treated as a single error
        or as multiple errors.
        For example, in processing the UTF-8 code unit sequence <F0 80 80 41>,
        the only formal requirement mandated by Unicode conformance for a
        converter is that the <41> be processed and correctly interpreted as
        <U+0041>. The converter could return <U+FFFD, U+0041>, handling <F0 80 80>
        as a single error, or <U+FFFD, U+FFFD, U+FFFD, U+0041>, handling each
        byte of <F0 80 80> as a separate error, or could take other approaches
        to signalling <F0 80 80> as an ill-formed code unit subsequence.

        U+FFFD Substitution of Maximal Subparts

        An increasing number of implementations are adopting the handling of
        ill-formed subsequences as specified in the W3C standard for encoding to
        achieve consistent U+FFFD replacements. See:
            http://www.w3.org/TR/encoding/
        The Unicode Standard does not require this practice for conformance. The
        following text describes this practice and gives detailed examples.

        ------------------------------------------------------------------------
        Je pige que dalle aux définitions suivantes...
        ------------------------------------------------------------------------
        D93a Unconvertible offset: An offset in a code unit sequence for which
             no code unit subsequence starting at that offset is well-formed.
        D93b Maximal subpart of an ill-formed subsequence: The longest code unit
        subsequence starting at an unconvertible offset that is either:
            a. the initial subsequence of a well-formed code unit sequence, or
            b. a subsequence of length one.

        This practice can be stated simply as:
        Whenever an unconvertible offset is reached during conversion of a code
        unit sequence:
            1. The maximal subpart at that offset is replaced by a single U+FFFD.
            2. The conversion proceeds at the offset immediately after the maximal
                subpart.
        ------------------------------------------------------------------------
        This practice replaces almost every byte of an ill-formed UTF-8 sequence
        with one U+FFFD. For example:

        Every byte of a “non-shortest form” sequence (see Definition D92),
        or of a truncated version thereof, is replaced, as shown in Table 3-8.
        (The interpretation of “non-shortest form” sequences has been forbidden
        since the publication of Corrigendum #1.)
            Table 3-8. U+FFFD for Non-Shortest Form Sequences
            Bytes  C0   AF   E0   80   BF   F0   81   82   41
            Output FFFD FFFD FFFD FFFD FFFD FFFD FFFD FFFD 0041

        Also, every byte of a sequence that would correspond to a surrogate code
        point,or of a truncated version thereof, is replaced with one U+FFFD, as
        shown in Table 3-9. (The interpretation of such byte sequences has been
        forbidden since Unicode 3.2.)
            Table 3-9. U+FFFD for Ill-Formed Sequences for Surrogates
            Bytes  ED   A0   80   ED   BF   BF   ED   AF   41
            Output FFFD FFFD FFFD FFFD FFFD FFFD FFFD FFFD 0041

        Finally, every byte of a sequence that would correspond to a code point
        beyond U+10FFFF, and any other byte that does not contribute to a valid
        sequence, is also replaced with one U+FFFD, as shown in Table 3-10
            Table 3-10. U+FFFD for Other Ill-Formed Sequences
            Bytes  F4   91   92   93   FF   41   80   BF   42
            Output FFFD FFFD FFFD FFFD FFFD 0041 FFFD FFFD 0042

        Only when a sequence of two or three bytes is a truncated version of a
        sequence which is otherwise well-formed to that point, is more than one
        byte replaced with a single U+FFFD, as shown in Table 3-11.
            Table 3-11. U+FFFD for Truncated Sequences
            Bytes  E1   80   E2   F0   91 92 F1 BF 41
            Output FFFD      FFFD FFFD       FFFD  0041
    */
    use strict arg string /* or buffer */, startB
    use strict named arg errorInfo=.nil
    if startB < 1 then return startB -- don't move because below start of string
    indexB = startB
    startByte = string~subchar(indexB)
    if startByte == "" then return indexB -- don't move because beyond end of string
    if startByte < "80"x then byteCount = 1                     -- 1-byte sequence 0xxxxxxx
    else if startByte < "C2"x then signal start_non_shortest_form
    else if startByte > "F4"x then signal start_error_range
    else if startByte~bitand("E0"x) == "C0"x then byteCount = 2 -- 2-byte sequence 110xxxxx (C0..DF but only C2..DF is valid)
    else if startByte~bitand("F0"x) == "E0"x then byteCount = 3 -- 3-byte sequence 1110xxxx
    else if startByte~bitand("F8"x) == "F0"x then byteCount = 4 -- 4-byte sequence 11110xxx
    else signal invalid_start_byte
    indexB += 1
    do i=2 to byteCount
        continuationByte = string~subchar(indexB)
        if continuationByte == "" then signal truncated
        if i == 2 then do
            if startByte == "E0"x, continuationByte < "A0"x then signal non_shortest_form
            if \self~isWTF8, startByte == "ED"x then do
                -- high/low surrogates are not an error if WTF-8 (wobbly)
                if continuationByte >= "A0"x, continuationByte <= "AF"x then signal high_surrogate
                if continuationByte >= "B0"x, continuationByte <= "BF"x then signal low_surrogate
            end
            if startByte == "F0"x, continuationByte < "90"x then signal non_shortest_form
            if startByte == "F4"x, continuationByte >= "90"x then signal error_range
        end
        if continuationByte~bitand("C0"x) <> "80"x then signal invalid_continuation_byte -- Must be 10xxxxxx
        indexB += 1
    end
    return indexB

    -- Remember: in case of error, NEVER return nextCodepointIndex==startB
    -- because that would create an infinite loop when scanning (see CreateIndexer)
    -- MUST always advance.

    invalid_start_byte:        return error(startB + 1, self~name "encoding: byte sequence at byte-position" startB "has an invalid start byte" startByte~c2d "("ppHexNumber(startByte~c2d)")")
    start_non_shortest_form:   return error(startB + 1, self~name "encoding: byte sequence at byte-position" startB "has an invalid start byte" startByte~c2d "("ppHexNumber(startByte~c2d)") (non-shortest form)")
    start_error_range:         return error(startB + 1, self~name "encoding: byte sequence at byte-position" startB "has an invalid start byte" startByte~c2d "("ppHexNumber(startByte~c2d)") (codepoint > U+".Unicode~maxCodepoint~d2x")")
    invalid_continuation_byte: return error(indexB, self~name "encoding: byte sequence at byte-position" startB "has an invalid continuation byte" continuationByte~c2d "("ppHexNumber(continuationByte~c2d)") at byte-position" indexB)
    non_shortest_form:         return error(indexB, self~name "encoding: byte sequence at byte-position" startB "has an invalid continuation byte" continuationByte~c2d "("ppHexNumber(continuationByte~c2d)") at byte-position" indexB "(non-shortest form)")
    high_surrogate:            return error(indexB, self~name "encoding: byte sequence at byte-position" startB "has an invalid continuation byte" continuationByte~c2d "("ppHexNumber(continuationByte~c2d)") at byte-position" indexB "(high surrogate)")
    low_surrogate:             return error(indexB, self~name "encoding: byte sequence at byte-position" startB "has an invalid continuation byte" continuationByte~c2d "("ppHexNumber(continuationByte~c2d)") at byte-position" indexB "(low surrogate)")
    error_range:               return error(indexB, self~name "encoding: byte sequence at byte-position" startB "has an invalid continuation byte" continuationByte~c2d "("ppHexNumber(continuationByte~c2d)") at byte-position" indexB "(codepoint > U+".Unicode~maxCodepoint~d2x")")
    truncated:                 return error(indexB, self~name "encoding: byte sequence at byte-position" startB "is truncated, expected" byteCount "bytes")

    error:
        use strict arg nextCodepointIndex, errorMessage
        if .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return -nextCodepointIndex
        end
        raise syntax 23.900 array (errorMessage)


::method previousCodepointIndex class
    -- indexB is the index of the first byte of the current codepoint
    --   cp1        |cp2              |cp3...
    --   byte1|byte2|byte3|byte4|byte5|byte6...
    --   1    |2    |3    |4    |5    |6...
    -- For example, if indexB==6 then previousCodepointIndex==3
    use strict arg string /* or buffer */, startB
    use strict named arg errorInfo=.nil
    if string~length == 0 then return startB -- don't move because empty string
    if startB <= 1 then return startB -- don't move because at start of string or before
    if startB > (string~length + 1) then return startB -- don't move because beyond the end of string
    do indexB = startB - 1 to 1 by -1 for self~codepointMaxBytes
        byte = string~subchar(indexB)
        if byte~bitand("C0"x) == "80"x then iterate                         -- 10xxxxxx continuation character
        else do -- test if this is a valid start byte
            /*
            error = .array~new(1)
            next = self~nextCodepointIndex(string, indexB, errorInfo: error)
            if next == startB then return indexB
            */
            startByte = byte
            if startByte < "80"x then return indexB                         -- 1-byte sequence 0xxxxxxx
            else if startByte < "C2"x then leave                            -- signal start_non_shortest_form
            else if startByte > "F4"x then leave                            -- signal start_error_range
            else if startByte~bitand("E0"x) == "C0"x then return indexB     -- 2-byte sequence 110xxxxx (C0..DF but only C2..DF is valid)
            else if startByte~bitand("F0"x) == "E0"x then return indexB     -- 3-byte sequence 1110xxxx
            else if startByte~bitand("F8"x) == "F0"x then return indexB     -- 4-byte sequence 11110xxx
            else leave                                                      -- signal invalid_start_byte
        end
    end
    signal start_byte_not_found

    -- Remember: in case of error, NEVER return nextCodepointIndex==startB
    -- MUST always move back.

    start_byte_not_found: return error(startB - 1 /* not indexB */, self~name "encoding: No start byte found when searching previous codepoint of codepoint at byte-position" startB)

    error:
        use strict arg previousCodepointIndex, errorMessage
        if .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return -previousCodepointIndex -- negative value means error
        end
        raise syntax 23.900 array (errorMessage)


-- utf8proc_ssize_t utf8proc_encode_char(utf8proc_int32_t codepoint, utf8proc_uint8_t *dst);
::method encode class
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg codepoint
    use strict named arg buffer(1)=.nil
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new(, self~codepointMaxBytes)
    self~checkCodepoint(codepoint, checkOnlyRange: .true)           -- check only range, the other errors will be detected during analysis
    if codepoint < 128 then do                                      -- if (uc < 0x80) {
        buffer~append(codepoint~d2c)                                -- dst[0] = (utf8proc_uint8_t) uc;
    end                                                             -- return 1;
    else if codepoint < 2048 then do                                -- } else if (uc < 0x800) {
        buffer~append((192 + codepoint % 64)~d2c)                   -- dst[0] = (utf8proc_uint8_t)(0xC0 + (uc >> 6))
        buffer~append((128 + codepoint // 64)~d2c)                  -- dst[1] = (utf8proc_uint8_t)(0x80 + (uc & 0x3F));
    end                                                             -- return 2;
    else if codepoint < 65536 then do
        if self~isWTF8 then do
            -- Must use appendToBuffer to manage correctly the concatenation of high surrogate with low surrogate
            buffer3 = .MutableBuffer~new(, 3)
            buffer3~append((224 + codepoint % 4096)~d2c)            -- dst[0] = (utf8proc_uint8_t)(0xE0 + (uc >> 12));
            buffer3~append((128 + (codepoint % 64) // 64)~d2c)      -- dst[1] = (utf8proc_uint8_t)(0x80 + ((uc >> 6) & 0x3F));
            buffer3~append((128 + codepoint // 64)~d2c)             -- dst[2] = (utf8proc_uint8_t)(0x80 + (uc & 0x3F));
            self~appendToBuffer(buffer3~string, :buffer)
        end
        else do
            buffer~append((224 + codepoint % 4096)~d2c)             -- dst[0] = (utf8proc_uint8_t)(0xE0 + (uc >> 12));
            buffer~append((128 + (codepoint % 64) // 64)~d2c)       -- dst[1] = (utf8proc_uint8_t)(0x80 + ((uc >> 6) & 0x3F));
            buffer~append((128 + codepoint // 64)~d2c)              -- dst[2] = (utf8proc_uint8_t)(0x80 + (uc & 0x3F));
        end
    end                                                             -- return 3;
    else if codepoint <= .Unicode~maxCodepoint then do              -- } else if (uc < 0x110000) {
        buffer~append((240 + codepoint % 262144)~d2c)               -- dst[0] = (utf8proc_uint8_t)(0xF0 + (uc >> 18));
        buffer~append((128 + (codepoint % 4096) // 64)~d2c)         -- dst[1] = (utf8proc_uint8_t)(0x80 + ((uc >> 12) & 0x3F));
        buffer~append((128 + (codepoint % 64) // 64)~d2c)           -- dst[2] = (utf8proc_uint8_t)(0x80 + ((uc >> 6) & 0x3F));
        buffer~append((128 + codepoint // 64)~d2c)                  -- dst[3] = (utf8proc_uint8_t)(0x80 + (uc & 0x3F));
    end                                                             -- return 4;
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self)


::method codepointSizeInBytes class
    use strict arg codepoint
    self~checkCodepoint(codepoint, checkOnlyRange: .true)
    if codepoint < 128 then return 1
    if codepoint < 2048 then return 2
    if codepoint < 65536 then return 3
    return 4


/********************/
/* Instance methods */
/********************/

::method codepointIndex
    use strict arg indexC
    if indexC < 1 then raise syntax 23.900 array (self~description "invalid codepoint index:" indexC)
    if indexC > self~codepointCount then return self~string~length + 1
    if .nil == self~codepointIndexes then return indexC
    indexB = self~codepointIndexes[indexC]
    if .nil <> indexB then return indexB
    return indexC -- sparse array: the value is equal to the index


::method codepoint
    -- to reimplement using a byte index because codepointIndexes will be removed
    use strict arg indexC, decode=.true
    startB = self~codepointIndex(indexC)
    if .nil == self~codepointIndexes, self~codepointCount == self~string~length then do
        -- Careful with this optimization! Testing just .nil is not enough since I no longer store the last index+1: even in the case .nil, the last codepoint can be more than one byte.
        if decode then return self~string~subchar(startB)~c2d
                  else return self~string~subchar(startB)
    end
    nextB = self~codepointIndex(indexC+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if decode then do
        if startB < 0 then return .Unicode~replacementCharacter~codepoint -- the current byte sequence is invalid
        return self~class~decode(self~string, absStartB, absNextB - absStartB)
    end
    return self~string~substr(absStartB, absNextB - absStartB) -- yes, always the current byte sequence, even if invalid


::method graphemeIndex
    use strict arg indexG
    if indexG < 1 then raise syntax 23.900 array (self~description "invalid grapheme index:" indexG)
    if indexG > self~graphemeCount then return self~string~length + 1
    if .nil == self~graphemeIndexes then return indexG
    indexB = self~graphemeIndexes[indexG]
    if .nil <> indexB then return indexB
    return indexG -- sparse array: the value is equal to the index


::method grapheme
    -- 2 modes:
    -- if the buffer is passed as argument then append the grapheme to the buffer, and return the buffer
    -- otherwise return the grapheme as a RexxText
    use strict arg indexG
    use strict named arg buffer(1)=.nil
    if .nil == self~graphemeIndexes, self~graphemeCount == self~string~length then do
        -- Careful with this optimization! Testing just .nil is not enough since I no longer store the last index+1: even in the case .nil, the last grapheme can be more than one codepoint.
        if .nil <> buffer then return buffer~~append(self~string~subchar(indexG))
                          else return .RexxText~new(self~string~subchar(indexG), self~class)
    end
    startB = self~graphemeIndex(indexG)
    nextB = self~graphemeIndex(indexG+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if .nil <> buffer then return buffer~~append(self~string~substr(absStartB, absNextB - absStartB))
                      else return .RexxText~new(self~string~substr(absStartB, absNextB - absStartB), self~class) -- yes, always the current byte sequence, even if invalid


::method UTF8
    use strict arg -- none
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil

    targetEncoding = .UTF8_Encoding
    if .nil <> buffer then return targetEncoding~append(self~string, :buffer) -- done? TODO is it correct? there is no check here. WTF8 converted to UTF8 could raise errors.
    if self~class~isUTF8 then return self~string~text

    string = self~getCachedString(targetEncoding)
    if .nil \== string then return string~text

    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    text = .RexxText~new(.String~new(self~string), targetEncoding)
    if memorize then do
        self~cacheString(targetEncoding, text~string)
        text~internalIndexer~cacheString(self~class, self~string)
    end
    return text


::method WTF8
    use strict arg -- none
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil

    targetEncoding = .WTF8_Encoding
    if .nil <> buffer then return targetEncoding~append(self~string, :buffer) -- done? TODO is it correct?
    if self~class~isWTF8 then return self~string~text

    string = self~getCachedString(targetEncoding)
    if .nil \== string then return string~text

    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    text = .RexxText~new(.String~new(self~string), targetEncoding)
    if memorize then do
        self~cacheString(targetEncoding, text~string)
        text~internalIndexer~cacheString(self~class, self~string)
    end
    return text


::method Unicode
    use strict arg -- none
    use strict named arg strict = .false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    if self~class~isUnicodeN then do
        if .nil <> buffer then return self~class~append(self~string, :buffer)
                          else return self~string~text
    end
    if self~string~isASCII then do
        targetEncoding = .Unicode8_Encoding
        if .nil <> buffer then return targetEncoding~append(self~string, :buffer)

        string = self~getCachedString(targetEncoding)
        if .nil \== string then return string~text

        -- yes, always a new string. The original string is still associated to the Byte_Encoding.
        -- Don't use string~copy, because the reference to the associated text is in the copy,
        -- and that forbids to assign a new RexxText.
        text = .RexxText~new(.String~new(self~string), targetEncoding)
        if memorize then do
            self~cacheString(targetEncoding, text~string)
            text~internalIndexer~cacheString(self~class, self~string)
        end
        return text
    end
    forward class (super)


::method transform
    -- This comment is repeated in many places, update all of them!
    -- bit      9       8       7              6         5     4        3    2    1   0
    -- flag     stripNA stripCC stripIgnorable stripMark lump  casefold NFKD NFKC NFD NFC

    use strict arg -- none
    use strict named arg normalization(4) = 1, casefold(4) = .false, lump= .false, stripMark = .false, stripIgnorable= .false, stripCC = .false, stripNA = .false, returnString = .false, memorize(3) = (.Unicode~memorizeTransformations)

    .validate~wholeNumberRange("normalization", normalization, 0, 4)
    .validate~logical("casefold", casefold)
    .validate~logical("lump", lump)
    .validate~logical("stripMark", stripMark)
    .validate~logical("stripIgnorable", stripIgnorable)
    .validate~logical("stripCC", stripCC)
    .validate~logical("stripNA", stripNA)
    .validate~logical("returnString", returnString)
    .validate~logical("memorize", memorize)

    -- normalization: 1=NFC, 2=NFD, 3=NFKC, 4=NFKD

    -- preset the bitFlags (these indicators have optimization rules)
    if normalization == 1 then self~isNFC
    else if normalization == 2 then self~isNFD
    else if normalization == 3 then self~isNFKC
    else if normalization == 4 then self~isNFKD

    mask = .BitKey~bitFlagsMask(normalization == 1, normalization == 2, normalization == 3, normalization == 4, casefold, lump, stripMark, stripIgnorable, stripCC, stripNA)
    string = self~getCachedString(mask)
    if .nil \== string then return string~makeRexxTextOrString(returnString) -- already memorized
    if self~bitFlagsAllTrue(mask) then string = self~string -- already in the requested form
    else do
        string = .Unicode~utf8proc_transform(self~string, :normalization, :casefold, :lump, :stripMark, :stripIgnorable, :stripCC, :stripNA)
        if (string == self~string) then do
            self~setBitFlags(mask) -- all these flags are set to true
        end
        else nop -- CAREFUL! don't store 0 (keep -1) because maybe one of the indicators could be 1
        if returnString then do
            -- It's a new string, without any encoding stored on it
            string~encoding = self~class
        end
        else do
            text = .RexxText~new(string, self~class)
            text~internalIndexer~setBitFlags(mask)
            -- Remember: string is automatically linked to text so the final makeRexxTextOrString will return this text
        end
    end
    if memorize then self~cacheString(mask, string)
    return string~makeRexxTextOrString(returnString)


::method NFC
    forward message "transform" namedArguments (.context~namedArgs~~setEntry("normalization", 1))


::method NFD
    forward message "transform" namedArguments (.context~namedArgs~~setEntry("normalization", 2))


::method NFKC
    forward message "transform" namedArguments (.context~namedArgs~~setEntry("normalization", 3))


::method NFKD
    forward message "transform" namedArguments (.context~namedArgs~~setEntry("normalization", 4))


::method casefold
    forward message "transform" namedArguments (.context~namedArgs~~setEntry("normalization", 0)~~setEntry("casefold", .true))


/******************************************************************************/
::class "UTF8_Encoding" public inherit Byte_CommonServices XTF8_CommonServices Unicode_CommonServices StringIndexer

::constant name "UTF-8"
::constant isUTF8 1
::constant BOM "EF BB BF"x


::method checkCodepoint class
    -- Remember : previousCodepoint can be .nil (first codepoint) or <0 (error recovery)
    --            when <0 abs(previousCodepoint) is the invalid value
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg checkOnlyRange=.false, errorInfo=.nil
    if .nil <> codepoint then do
        if codepoint < 0 | codepoint > .Unicode~maxCodepoint then signal error_range
        if checkOnlyRange then return 1 -- a positive value means "no error"
        if codepoint >= 55296 & codepoint < 56320 then signal error_high_surrogate -- U+D800 to U+DBFF high surrogates
        if codepoint >= 56320 & codepoint < 57344 then signal error_low_surrogate  -- U+DC00 to U+DFFF low surrogates
    end
    return 1 -- a positive value means "no error"

    -- Every byte of the byte-sequence must be considered as invalid,
    -- and must not be consumed, except the first byte.
    -- The 2nd byte will be a new start byte.
    error_range:          return error(0, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..".Unicode~maxCodepoint)
    error_high_surrogate: return error(0, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". High surrogate is not allowed")
    error_low_surrogate:  return error(0, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Low surrogate is not allowed")

    error:
        use strict arg whichCodepoint, errorMessage
        if .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return whichCodepoint -- -1 (previousCodepoint) or 0 (codepoint). A negative or null value means "error".
        end
        raise syntax 23.900 array (errorMessage)


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


/******************************************************************************/
::class "XTF16_CommonServices" mixinclass Object private
-- where X stands for U or W

::constant codeUnitSizeInBytes 2
::constant codepointMaxBytes 4  -- In UTF-16, a codepoint can be 2 or 4 bytes


::method decode class
    -- sizeB == -1 ==> this method will check the validity of the encoding
    -- sizeB <> -1 ==> this method assumes that the encoding has been checked and is valid
    use strict arg string /* or buffer */, startB=1, sizeB=(-1)
    if sizeB == -1 then do
        nextB = self~nextCodepointIndex(string, startB) -- raise error if invalid, so no need to test if < 0
        sizeB = nextB - startB
    end
    -- numeric digits 10 not needed, the greatest possible value is .utf16be_encoding~decode("FF FF FF FF"x, 1, 4) = 10 559 487 (8 digits)
    if sizeB == 0 then return .nil
    if sizeB == 2 then return self~decodeCodepoint(string~substr(startB, 2))
    if sizeB == 4 then do
        high_surrogate = self~decodeCodepoint(string~substr(startB, 2))
        low_surrogate = self~decodeCodepoint(string~substr(startB + 2, 2))
        h = (high_surrogate - 55296) * 1024 -- Take the high surrogate and subtract 0xD800, then multiply by 0x400
        l = low_surrogate - 56320 -- Take the low surrogate and subtract 0xDC00
        return h + l + 65536 -- Add these two results together, and finally add 0x10000
    end
    raise syntax 23.900 array (self~name "encoding:" sizeB "is an invalid size of byte sequence")


::method byteSequenceSize class
    -- Fast, minimal checks
    -- Typical usage:
    --     indexer~decode(string, startB, indexer~byteSequenceSize(string, startB))
    -- By passing a size to ~decode, the checks are disabled, and that allows to get a codepoint even when ill-formed.
    use strict arg string /* or buffer */, startB=1
    wobbly = self~isWTF16
    indexB = startB
    lengthB = string~length
    if indexB > lengthB then return 0 -- end of string
    if lengthB - indexB < 1 then return -1 -- truncated
    codeUnit = self~codeUnitBE(string~substr(indexB, 2)) -- yes! always codeUnitBE, works for BE and LE
    indexB += 2
    if codeUnit >= "D800"x & codeUnit <= "DBFF"x then do
        -- got high surrogate, get low surrogate
        if indexB > lengthB then do -- end of string
            if wobbly then return 2
                      else return -1
        end
        if lengthB - indexB < 1 then return -1 -- truncated
        codeUnit = self~codeUnitBE(string~substr(indexB, 2)) -- yes! always codeUnitBE, works for BE and LE
        if codeUnit >= "DC00"x & codeUnit <= "DFFF"x then return 4 -- this is a valid low surrogate
        else do
            -- no valid low surrogate but it's acceptable to consider the high
            -- surrogate as a standalone codepoint, when wobbly mode
            if wobbly then return 2
                      else return -1
        end
    end
    return 2


::method nextCodepointIndex class
    use strict arg string /* or buffer */, startB
    use strict named arg errorInfo=.nil
    wobbly = self~isWTF16
    indexB = startB
    lengthB = string~length
    if indexB < 1 then return startB -- don't move because below start of string
    if indexB > lengthB then return startB -- don't move because beyond end of string
    if lengthB - indexB < 1 then signal truncated2
    -- yes! always codeUnitBE, works for BE and LE
    codeUnit = self~codeUnitBE(string~substr(indexB, 2)) -- Remember: don't optimize too much, I display this codepoint in case of error
    indexB += 2
    if codeUnit >= "D800"x & codeUnit <= "DBFF"x then do
        -- got high surrogate, get low surrogate
        if indexB > lengthB then do
            -- end of string, no low surrogate but it's acceptable to consider
            -- the high surrogate as a standalone codepoint, when wobbly mode
            if wobbly then return indexB
                      else signal unpaired_high_surrogate
        end
        if lengthB - indexB < 1 then signal truncated4
        codeUnit = self~codeUnitBE(string~substr(indexB, 2)) -- yes! always codeUnitBE, works for BE and LE
        if codeUnit >= "DC00"x & codeUnit <= "DFFF"x then indexB += 2 -- this is a valid low surrogate
        else do
            -- no valid low surrogate but it's acceptable to consider the high
            -- surrogate as a standalone codepoint, when wobbly mode
            if wobbly then return indexB
                      else signal invalid_low_surrogate
        end
    end
    else if \wobbly, codeUnit >= "DC00"x & codeUnit <= "DFFF"x then signal unpaired_low_surrogate
    -- todo: add more checks ? could test the range (currently checked later by checkCodepoint)
    return indexB

    -- Remember: in case of error, NEVER return nextCodepointIndex==startB
    -- because that would create an infinite loop when scanning (see CreateIndexer)
    -- MUST always advance.

    unpaired_high_surrogate: return error(startB + 2, self~name "encoding: unpaired high surrogate" codeUnit~c2d "("ppCodepoint(codeUnit~c2d)") at byte-position" startB)
    unpaired_low_surrogate:  return error(startB + 2, self~name "encoding: unpaired low surrogate" codeUnit~c2d "("ppCodepoint(codeUnit~c2d)") at byte-position" startB)
    invalid_low_surrogate:   return error(startB + 2, self~name "encoding: invalid low surrogate" codeUnit~c2d "("ppCodepoint(codeUnit~c2d)") at byte-position" indexB)
    truncated2:              return error(startB + 2, self~name "encoding: byte sequence at byte-position" startB "is truncated, expected 2 bytes")
    truncated4:              return error(startB + 2, self~name "encoding: byte sequence at byte-position" startB "is truncated, expected 4 bytes")

    error:
        use strict arg nextCodepointIndex, errorMessage
        if .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return -nextCodepointIndex -- negative value means error
        end
        raise syntax 23.900 array (errorMessage)


::method previousCodepointIndex class
    -- indexB is the index of the first byte of the current codepoint
    --   cp1        |cp2        |cp3...
    --   byte1|byte2|byte3|byte4|byte5|byte6...
    --   1    |2    |3    |4    |5    |6...
    -- For example, if indexB==5 then previousCodepointIndex==3 (can be 1 if cp1 is a high surrogate and cp2 is a low surrogate)
    use strict arg string /* or buffer */, startB
    use strict named arg errorInfo=.nil
    lengthB = string~length
    if lengthB == 0 then return startB -- don't move because empty string
    if startB <= 1 then return startB -- don't move because at start of string or before
    if startB > (lengthB + 1) then return startB -- don't move because beyond end of string
    wobbly = self~isWTF16
    indexB = startB - 2
    /*
    if indexB < 1 then signal truncated2
    -- yes! always codeUnitBE, works for BE and LE
    codeUnit = self~codeUnitBE(string~substr(indexB, 2)) -- Remember: don't optimize too much, I display this codepoint in case of error
    if codeUnit >= "D800"x & codeUnit <= "DBFF"x then do
            -- no low surrogate but it's acceptable to consider
            -- the high surrogate as a standalone codepoint, when wobbly mode
            if wobbly then return indexB
                      else signal unpaired_high_surrogate
    end
    */
    return startB -- not yet implemented

    -- Remember: in case of error, NEVER return nextCodepointIndex==startB
    -- MUST always move back.

    unpaired_high_surrogate: return error(startB + 2, self~name "encoding: unpaired high surrogate" codeUnit~c2d "("ppCodepoint(codeUnit~c2d)") at byte-position" startB)
    truncated2:              return error(indexB, self~name "encoding: previous codepoint of codepoint at byte-position" startB "is truncated, expected 2 bytes")

    error:
        use strict arg nextCodepointIndex, errorMessage
        if .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return -nextCodepointIndex -- negative value means error
        end
        raise syntax 23.900 array (errorMessage)


::method encode class
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg codepoint
    use strict named arg buffer(1)=.nil
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new(, self~codepointMaxBytes)
    self~checkCodepoint(codepoint, checkOnlyRange: .true) -- check only range, the other errors will be detected during analysis
    if codepoint < 55296 then do -- U+0000 to U+D7FF
        buffer~append(self~encodeCodepoint(codepoint))
    end
    else if codepoint < 65536 then do -- U+E000 to U+FFFF
        buffer~append(self~encodeCodepoint(codepoint))
    end
    else if codepoint <= .Unicode~maxCodepoint then do -- U+010000 to U+10FFFF
        buffer~append(self~encodeCodepoint(55296 + (codepoint - 65536) % 1024))     -- high surrogate: Subtract 0x10000, shift right by 10 (divide by 0x400), then add 0xD800
        buffer~append(self~encodeCodepoint(56320 + (codepoint - 65536) // 1024))    -- low surrogate: Subtract 0x10000, take the low 10 bits (remainder of dividing by 0x400), then add 0xDC0
    end
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self)


::method codepointSizeInBytes class
    use strict arg codepoint
    self~checkCodepoint(codepoint, checkOnlyRange: .true)
    if codepoint < 65536 then return 2
    return 4


/********************/
/* Instance methods */
/********************/

::method codepointIndex
    use strict arg indexC
    if indexC < 1 then raise syntax 23.900 array (self~description "invalid codepoint index:" indexC)
    if indexC > self~codepointCount then return self~string~length + 1
    if .nil == self~codepointIndexes then return 2 * (indexC - 1) + 1
    indexB = self~codepointIndexes[indexC]
    if .nil <> indexB then return indexB
    return 2 * (indexC - 1) + 1 -- sparse array: the value can be derived from the index


::method codepoint
    -- to reimplement using a byte index because codepointIndexes will be removed
    use strict arg indexC, decode=.true
    startB = self~codepointIndex(indexC)
    if .nil == self~codepointIndexes, self~codepointCount == self~string~length then do
        -- Careful with this optimization! Testing just .nil is not enough since I no longer store the last index+1: even in the case .nil, the last codepoint can be 4 bytes.
        if decode then return self~class~decode(self~string, startB, 2)
                  else return self~string~substr(startB, 2)
    end
    nextB = self~codepointIndex(indexC+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if decode then do
        if startB < 0 then return .Unicode~replacementCharacter~codepoint -- the current byte sequence is invalid
        return self~class~decode(self~string, absStartB, absNextB - absStartB)
    end
    return self~string~substr(absStartB, absNextB - absStartB) -- yes, always the current byte sequence, even if invalid


::method graphemeIndex
    use strict arg indexG
    if indexG < 1 then raise syntax 23.900 array (self~description "invalid grapheme index:" indexG)
    if indexG > self~graphemeCount then return self~string~length + 1
    if .nil == self~graphemeIndexes then return 2 * (indexG - 1) + 1
    indexB = self~graphemeIndexes[indexG]
    if .nil <> indexB then return indexB
    return 2 * (indexG - 1) + 1 -- sparse array: the value can be derived from the index


::method grapheme
    -- 2 modes:
    -- if the buffer is passed as argument then append the grapheme to the buffer, and return the buffer
    -- otherwise return the grapheme as a RexxText
    use strict arg indexG
    use strict named arg buffer(1)=.nil
    startB = self~graphemeIndex(indexG)
    if .nil == self~graphemeIndexes, self~graphemeCount == self~string~length then do
        -- Careful with this optimization! Testing just .nil is not enough since I no longer store the last index+1: even in the case .nil, the last grapheme can be more than one codepoint
        if .nil <> buffer then return buffer~~append(self~string~substr(startB, 2))
                          else return .RexxText~new(self~string~substr(startB, 2), self~class)
    end
    nextB = self~graphemeIndex(indexG+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if .nil <> buffer then return buffer~~append(self~string~substr(absStartB, absNextB - absStartB))
                      else return .RexxText~new(self~string~substr(absStartB, absNextB - absStartB), self~class) -- yes, always the current byte sequence, even if invalid


/******************************************************************************/
::class "XTF16BE_CommonServices" mixinclass Object private
-- where X stands for U or W

::method codeUnitBE class
    -- Ex : "B0FE"x --> "B0FE"x
    use strict arg codeUnit
    return codeUnit


::method decodeCodepoint class private
    use strict arg stringBytes
    -- numeric digits 10 -- not needed, the code unit is 2 bytes, never 4 bytes
    return stringBytes~c2d


::method encodeCodepoint class private
    use strict arg codepoint
    return codepoint~d2c(2)


::method encodeASCIIstring class
    use strict arg string
    use strict named arg memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil

    text = .nil
    if string~hasText then text = string~text

    targetEncoding = self
    if .nil \== text then do
        cachedString = text~internalIndexer~getCachedString(targetEncoding)
        if .nil \== cachedString then do
            if .nil <> buffer then return targetEncoding~append(cachedString, :buffer)
                              else return cachedString~text
        end
    end

    sizeB = string~length -- size in bytes
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new(, sizeB * 2) -- yes, always 2, no need to use codepointMaxBytes
    buffer~encoding = targetEncoding~asEncodingFor(buffer) -- raise an error if not compatible
    bufferStart = buffer~length + 1

    do i=1 to sizeB
        buffer~append("00"x) -- big endian
        buffer~append(string~subchar(i))
    end

    convertedString = buffer~substr(bufferStart)
    -- It's a new string, without any encoding stored on it
    convertedString~encoding = targetEncoding
    if memorize, .nil \== text then text~internalIndexer~cacheString(targetEncoding, convertedString)

    if returnBuffer then return buffer
    convertedText = .RexxText~new(convertedString, targetEncoding)
    if memorize then convertedText~internalIndexer~cacheString(string~encoding, string)
    return convertedText


::method UTF16BE
    use strict arg -- none
    use strict named arg strict = .false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil

    if .nil <> buffer then return self~class~append(self~string, :buffer)
    if self~class~isUTF16BE then return self~string~text

    targetEncoding = .UTF16BE_Encoding
    string = self~getCachedString(targetEncoding)
    if .nil \== string then return string~text

    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    text = .RexxText~new(.String~new(self~string), targetEncoding)
    if memorize then do
        self~cacheString(targetEncoding, text~string)
        text~internalIndexer~cacheString(self~class, self~string)
    end
    return text


::method WTF16BE
    use strict arg -- none
    use strict named arg strict = .false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil

    if .nil <> buffer then return self~class~append(self~string, :buffer)
    if self~class~isWTF16BE then return self~string~text

    targetEncoding = .WTF16BE_Encoding
    string = self~getCachedString(targetEncoding)
    if .nil \== string then return string~text

    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    text = .RexxText~new(.String~new(self~string), targetEncoding)
    if memorize then do
        self~cacheString(targetEncoding, text~string)
        text~internalIndexer~cacheString(self~class, self~string)
    end
    return text


/*
::method Unicode16
    -- todo: is there an optim possible here ?
*/


/******************************************************************************/
::class "XTF16LE_CommonServices" mixinclass Object private
-- where X stands for U or W

::method codeUnitBE class
    -- Ex : "FEB0"x --> "B0FE"x
    use strict arg codeUnit
    return codeUnit~reverse


::method decodeCodepoint class private
    use strict arg stringBytes
    -- numeric digits 10 -- not needed, the code unit is 2 bytes, never 4 bytes
    return stringBytes~reverse~c2d


::method encodeCodepoint class private
    use strict arg codepoint
    return codepoint~d2c(2)~reverse


::method encodeASCIIstring class
    use strict arg string
    use strict named arg memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil

    text = .nil
    if string~hasText then text = string~text

    targetEncoding = self
    if .nil \== text then do
        cachedString = text~internalIndexer~getCachedString(targetEncoding)
        if .nil \== cachedString then do
            if .nil <> buffer then return targetEncoding~append(cachedString, :buffer)
                              else return cachedString~text
        end
    end

    sizeB = string~length -- size in bytes
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new(, sizeB * 2) -- yes, always 2, no need to use codepointMaxBytes
    buffer~encoding = targetEncoding~asEncodingFor(buffer) -- raise an error if not compatible
    bufferStart = buffer~length + 1

    do i=1 to sizeB
        buffer~append(string~subchar(i))
        buffer~append("00"x) -- little endian
    end

    convertedString = buffer~substr(bufferStart)
    -- It's a new string, without any encoding stored on it
    convertedString~encoding = targetEncoding
    if memorize, .nil \== text then text~internalIndexer~cacheString(targetEncoding, convertedString)

    if returnBuffer then return buffer
    convertedText = .RexxText~new(convertedString, targetEncoding)
    if memorize then convertedText~internalIndexer~cacheString(string~encoding, string)
    return convertedText


::method UTF16LE
    use strict arg -- none
    use strict named arg strict = .false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil

    if .nil <> buffer then return buffer~~append(self~string)
    if self~class~isUTF16LE then return self~string~text

    targetEncoding = .UTF16LE_Encoding
    string = self~getCachedString(targetEncoding)
    if .nil \== string then return string~text

    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    text = .RexxText~new(.String~new(self~string), targetEncoding)
    if memorize then do
        self~cacheString(targetEncoding, text~string)
        text~internalIndexer~cacheString(self~class, self~string)
    end
    return text


::method WTF16LE
    use strict arg -- none
    use strict named arg strict = .false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil

    if .nil <> buffer then return buffer~~append(self~string)
    if self~class~isWTF16LE then return self~string~text

    targetEncoding = .WTF16LE_Encoding
    string = self~getCachedString(targetEncoding)
    if .nil \== string then return string~text

    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    text = .RexxText~new(.String~new(self~string), targetEncoding)
    if memorize then do
        self~cacheString(targetEncoding, text~string)
        text~internalIndexer~cacheString(self~class, self~string)
    end
    return text


/*
::method Unicode16
    -- todo: is there an optim possible here ?
*/


/******************************************************************************/
::class "UTF16_CommonServices" mixinclass Object private

::method checkCodepoint class
    /*
    Because surrogate code points are not Unicode scalar values, isolated UTF-16
    code units in the range D80016..DFFF16 are ill-formed.
    (this is also checked in nextCodepointIndex, only when not wobbly)
    */
    -- Remember : previousCodepoint can be .nil (first codepoint) or <0 (error recovery)
    --            when <0 abs(previousCodepoint) is the invalid value
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg checkOnlyRange=.false, errorInfo=.nil
    if .nil <> codepoint then do
        if codepoint < 0 | codepoint > .Unicode~maxCodepoint then signal error_range
        if checkOnlyRange then return 1 -- a positive value means "no error"
        if .nil <> previousCodepoint then do
               previousCodepointIsHighSurrogate = (previousCodepoint >= 55296 & previousCodepoint < 56320) -- U+D800 to U+DBFF high surrogates
               codepointIsLowSurrogate = (codepoint >= 56320 & codepoint < 57344)                          -- U+DC00 to U+DFFF low surrogates
               if previousCodepointIsHighSurrogate, \codepointIsLowSurrogate then signal unpaired_high_surrogate
               if \previousCodepointIsHighSurrogate, codepointIsLowSurrogate then signal unpaired_low_surrogate
        end
    end
    else do
        -- End of string
        if .nil <> previousCodepoint,,
           previousCodepoint >= 55296 & previousCodepoint < 56320,  -- U+D800 to U+DBFF high surrogates
        then signal unpaired_high_surrogate
    end
    return 1 -- a positive value means "no error"

    -- Every code unit of the byte-sequence must be considered as invalid,
    -- and must not be consumed, except the first code unit.
    -- The 2nd code unit will be the next code unit to analyze.
    error_range:             return error(0, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..".Unicode~maxCodepoint)
    unpaired_high_surrogate: return error(-1, self~name "encoding: unpaired high surrogate" previousCodepoint "("ppCodepoint(previousCodepoint)") at byte-position" previousCodepointIndexB)
    unpaired_low_surrogate:  return error(0, self~name "encoding: unpaired low surrogate" codepoint "("ppCodepoint(codepoint)") at byte-position" codepointIndexB)

    error:
        use strict arg whichCodepoint, errorMessage
        if .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return whichCodepoint -- -1 (previousCodepoint) or 0 (codepoint). A negative or null value means "error".
        end
        raise syntax 23.900 array (errorMessage)


/******************************************************************************/
::class "UTF16BE_Encoding" public inherit UTF16_CommonServices XTF16BE_CommonServices XTF16_CommonServices Unicode_CommonServices StringIndexer

::constant name "UTF-16BE"
::constant isUTF16 1
::constant isUTF16BE 1
::constant BOM "FE FF"x


/******************************************************************************/
::class "UTF16LE_Encoding" public inherit UTF16_CommonServices XTF16LE_CommonServices XTF16_CommonServices Unicode_CommonServices StringIndexer

::constant name "UTF-16LE"
::constant isUTF16 1
::constant isUTF16LE 1
::constant BOM "FF FE"x


/******************************************************************************/
::class "WTF16_CommonServices" mixinclass Object private

::method checkCodepoint class
    -- Isolated surrogates are ok, nothing to check regarding the surrogates
    -- Remember : previousCodepoint can be .nil (first codepoint) or <0 (error recovery)
    --            when <0 abs(previousCodepoint) is the invalid value
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg checkOnlyRange=.false /*no impact here*/, errorInfo=.nil
    if .nil <> codepoint then do
        if codepoint < 0 | codepoint > .Unicode~maxCodepoint then signal error_range
    end
    return 1 -- a positive value means "no error"

    -- Every code unit of the byte-sequence must be considered as invalid,
    -- and must not be consumed, except the first code unit.
    -- The 2nd code unit will be the next code unit to analyze.
    error_range: return error(0, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..".Unicode~maxCodepoint)

    error:
        use strict arg whichCodepoint, errorMessage
        if .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return whichCodepoint -- -1 (previousCodepoint) or 0 (codepoint). A negative or null value means "error".
        end
        raise syntax 23.900 array (errorMessage)


/******************************************************************************/
::class "WTF16BE_Encoding" public inherit WTF16_CommonServices XTF16BE_CommonServices XTF16_CommonServices Unicode_CommonServices StringIndexer
/*
https://simonsapin.github.io/wtf-8/#16-bit-code-unit
WTF-16 is sometimes used as a shorter name for potentially ill-formed UTF-16,
especially in the context of systems were originally designed for UCS-2 and
later upgraded to UTF-16 but never enforced well-formedness, either by neglect
or because of backward-compatibility constraints.

A sequence of 16-bit code units is potentially ill-formed UTF-16 if it is
intended to be interpreted as UTF-16, but is not necessarily well-formed in
UTF-16. It effectively encodes a sequence of code points that do not contain any
surrogate code point pair.

Concatenating WTF-16 strings is easy: no extra care, just concatenate the bytes.
*/

::constant name "WTF-16BE"
--::constant isUTF16 1 -- WTF-16 is not UTF-16
--::constant isUTF16BE 1 -- WTF16-BE is not UTF-16BE
::constant isWTF16 1
::constant isWTF16BE 1
::constant BOM "FE FF"x


/******************************************************************************/
::class "WTF16LE_Encoding" public inherit WTF16_CommonServices XTF16LE_CommonServices XTF16_CommonServices Unicode_CommonServices StringIndexer

::constant name "WTF-16LE"
--::constant isUTF16 1 -- WTF16 is not UTF16
--::constant isUTF16LE 1 -- WTF-16LE is not UTF-16LE
::constant isWTF16 1
::constant isWTF16LE 1
::constant BOM "FF FE"x


/******************************************************************************/
::class "UTF32_CommonServices" mixinclass Object private

::constant codeUnitSizeInBytes 4
::constant codepointMaxBytes 4 -- In UTF-32, a codepoint is 4 bytes


::method checkCodepoint class
    /*
    - Because surrogate code points are not included in the set of Unicode scalar values,
      UTF-32 code units in the range 0000D80016..0000DFFF16 are ill-formed.
    - Any UTF-32 code unit greater than 0010FFFF is ill-formed.
    */
    -- Remember : previousCodepoint can be .nil (first codepoint) or <0 (error recovery)
    --            when <0 abs(previousCodepoint) is the invalid value
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg checkOnlyRange=.false, errorInfo=.nil
    if .nil <> codepoint then do
        if codepoint < 0 | codepoint > .Unicode~maxCodepoint then signal error_range
        if checkOnlyRange then return 1 -- a positive value means "no error"
        if codepoint >= 55296 & codepoint < 56320 then signal error_high_surrogate -- U+D800 to U+DBFF high surrogates
        if codepoint >= 56320 & codepoint < 57344 then signal error_low_surrogate  -- U+DC00 to U+DFFF low surrogates
    end
    return 1 -- a positive value means "no error"

    error_range:          return error(0, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..".Unicode~maxCodepoint)
    error_high_surrogate: return error(0, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". High surrogate is not allowed")
    error_low_surrogate:  return error(0, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Low surrogate is not allowed")

    error:
        use strict arg whichCodepoint, errorMessage
        if .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return whichCodepoint -- -1 (previousCodepoint) or 0 (codepoint). A negative or null value means "error".
        end
        raise syntax 23.900 array (errorMessage)


::method decode class
    -- sizeB == -1 ==> this method will check the validity of the encoding
    -- sizeB <> -1 ==> this method assumes that the encoding has been checked and is valid
    use strict arg string /* or buffer */, startB=1, sizeB=(-1)
    if sizeB == -1 then do
        nextB = self~nextCodepointIndex(string, startB) -- raise error if invalid, so no need to test if < 0
        sizeB = nextB - startB
    end
    -- numeric digits 10 -- not needed here, managed by decodeCodepoint
    if sizeB == 0 then return .nil
    if sizeB == 4 then return self~decodeCodepoint(string~substr(startB, 4))
    raise syntax 23.900 array (self~name "encoding:" sizeB "is an invalid size of byte sequence")


::method byteSequenceSize class
    -- Fast, minimal checks.
    -- Typical usage:
    --     indexer~decode(string, startB, indexer~byteSequenceSize(string, startB))
    -- By passing a non-negative size to ~decode, the checks are disabled.
    use strict arg string /* or buffer */, startB
    lengthB = string~length
    if startB > lengthB then return 0 -- end of string
    if lengthB - startB < 3 then return -1 -- truncated
    return 4


::method nextCodepointIndex class
    use strict arg string /* or buffer */, startB
    use named arg errorInfo=.nil
    indexB = startB
    lengthB = string~length
    if indexB < 1 then return startB -- don't move because below start of string
    if indexB > lengthB then return startB -- don't move because beyond end of string
    if lengthB - indexB < 3 then signal truncated
    -- todo: add more checks ? could test the surrogates and the range (currently checked later by checkCodepoint)
    indexB += 4
    return indexB

    -- Remember: in case of error, NEVER return nextCodepointIndex==startB
    -- because that would create an infinite loop when scanning (see CreateIndexer)
    -- MUST always advance.

    truncated: return error(indexB + 4, self~name "encoding: byte sequence at byte-position" startB "is truncated, expected 4 bytes")

    error:
        use strict arg nextCodepointIndex, errorMessage
        if .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return -nextCodepointIndex -- negative value means error
        end
        raise syntax 23.900 array (errorMessage)


::method encode class
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg codepoint
    use strict named arg buffer(1)=.nil
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new(, 4) -- yes, always 4, no need to use codepointMaxBytes
    self~checkCodepoint(codepoint, checkOnlyRange: .true) -- check only range, the other errors will be detected during analysis
    buffer~append(self~encodeCodepoint(codepoint))
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self)


::method codepointSizeInBytes class
    use strict arg codepoint
    self~checkCodepoint(codepoint, checkOnlyRange: .true)
    return 4


/********************/
/* Instance methods */
/********************/

::method codepointIndex
    use strict arg indexC
    if indexC < 1 then raise syntax 23.900 array (self~description "invalid codepoint index:" indexC)
    if indexC > self~codepointCount then return self~string~length + 1
    if .nil == self~codepointIndexes then return 4 * (indexC - 1) + 1
    indexB = self~codepointIndexes[indexC]
    if .nil <> indexB then return indexB
    return 4 * (indexC - 1) + 1 -- sparse array: the value can be derived from the index


::method codepoint
    -- to reimplement using a byte index because codepointIndexes will be removed
    use strict arg indexC, decode=.true
    startB = self~codepointIndex(indexC)
    if .nil == self~codepointIndexes then do
        -- This optimization is possible despite I no longer store the last index+1: the last codepoint is always 4 bytes.
        if decode then return self~class~decode(self~string, startB, 4)
                  else return self~string~substr(startB, 4)
    end
    nextB = self~codepointIndex(indexC+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if decode then do
        if startB < 0 then return .Unicode~replacementCharacter~codepoint -- the current byte sequence is invalid
        return self~class~decode(self~string, absStartB, absNextB - absStartB)
    end
    return self~string~substr(absStartB, absNextB - absStartB) -- yes, always the current byte sequence, even if invalid


::method graphemeIndex
    use strict arg indexG
    if indexG < 1 then raise syntax 23.900 array (self~description "invalid grapheme index:" indexG)
    if indexG > self~graphemeCount then return self~string~length + 1
    if .nil == self~graphemeIndexes then return 4 * (indexG - 1) + 1
    indexB = self~graphemeIndexes[indexG]
    if .nil <> indexB then return indexB
    return 4 * (indexG - 1) + 1 -- sparse array: the value can be derived from the index


::method grapheme
    -- 2 modes:
    -- if the buffer is passed as argument then append the grapheme to the buffer, and return the buffer
    -- otherwise return the grapheme as a RexxText
    use strict arg indexG
    use strict named arg buffer(1)=.nil
    startB = self~graphemeIndex(indexG)
    if .nil == self~graphemeIndexes, self~graphemeCount == self~string~length then do
        -- Careful with this optimization! Testing just .nil is not enough since I no longer store the last index+1: even in the case .nil, the last grapheme can be more than one codepoint
        if .nil <> buffer then return buffer~~append(self~string~substr(startB, 4))
                          else return .RexxText~new(self~string~substr(startB, 4), self~class)
    end
    nextB = self~graphemeIndex(indexG+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if .nil <> buffer then return buffer~~append(self~string~substr(absStartB, absNextB - absStartB))
                      else return .RexxText~new(self~string~substr(absStartB, absNextB - absStartB), self~class) -- yes, always the current byte sequence, even if invalid


/******************************************************************************/
::class "UTF32BE_Encoding" public inherit UTF32_CommonServices Unicode_CommonServices StringIndexer

::constant name "UTF-32BE"
::constant isUTF32 1
::constant isUTF32BE 1
::constant BOM "00 00 FE FF"x


::method decodeCodepoint class private
    use strict arg stringBytes
    -- precondition: stringBytes~length <= 4
    -- needed, the code unit is 4 bytes.
    -- "3B9A C9FF"x~c2d = 999 999 999. The next value raises an error when 9 digits.
    -- The maximum value is "FFFF FFFF"x~c2d = 4 294 967 295 (10 digits)
    numeric digits 10
    return stringBytes~c2d


::method encodeCodepoint class private
    use strict arg codepoint
    return codepoint~d2c(4)


::method encodeASCIIstring class
    use strict arg string
    use strict named arg memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil

    text = .nil
    if string~hasText then text = string~text

    targetEncoding = self
    if .nil \== text then do
        cachedString = text~internalIndexer~getCachedString(targetEncoding)
        if .nil \== cachedString then do
            if .nil <> buffer then return targetEncoding~append(cachedString, :buffer)
                              else return cachedString~text
        end
    end

    sizeB = string~length -- size in bytes
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new(, sizeB * 4) -- yes, always 4, no need to use codepointMaxBytes
    buffer~encoding = targetEncoding~asEncodingFor(buffer) -- raise an error if not compatible
    bufferStart = buffer~length + 1

    do i=1 to sizeB
        buffer~append("000000"x) -- big endian
        buffer~append(string~subchar(i))
    end

    convertedString = buffer~substr(bufferStart)
    -- It's a new string, without any encoding stored on it
    convertedString~encoding = targetEncoding
    if memorize, .nil \== text then text~internalIndexer~cacheString(targetEncoding, convertedString)

    if returnBuffer then return buffer
    convertedText = .RexxText~new(convertedString, targetEncoding)
    if memorize then convertedText~internalIndexer~cacheString(string~encoding, string)
    return convertedText


::method UTF32BE
    use strict arg -- none
    use strict named arg strict = .false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    if .nil <> buffer then return buffer~~append(self~string)
                      else return self~string~text


/*
::method Unicode32
    -- is there an optim possible here ?
*/


/******************************************************************************/
::class "UTF32LE_Encoding" public inherit UTF32_CommonServices Unicode_CommonServices StringIndexer

::constant name "UTF-32LE"
::constant isUTF32 1
::constant isUTF32LE 1
::constant BOM "FF FE 00 00"x


::method decodeCodepoint class private
    use strict arg stringBytes
    -- precondition: stringBytes~length <= 4
    -- needed, the code unit is 4 bytes.
    -- "3B9A C9FF"x~c2d = 999 999 999. The next value raises an error when 9 digits.
    -- The maximum value is "FFFF FFFF"x~c2d = 4 294 967 295 (10 digits)
    numeric digits 10
    return stringBytes~reverse~c2d


::method encodeCodepoint class private
    use strict arg codepoint
    return codepoint~d2c(4)~reverse


::method encodeASCIIstring class
    use strict arg string
    use strict named arg memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil

    text = .nil
    if string~hasText then text = string~text

    targetEncoding = self
    if .nil \== text then do
        cachedString = text~internalIndexer~getCachedString(targetEncoding)
        if .nil \== cachedString then do
            if .nil <> buffer then return targetEncoding~append(cachedString, :buffer)
                              else return cachedString~text
        end
    end

    sizeB = string~length -- size in bytes
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new(, sizeB * 4) -- yes, always 4, no need to use codepointMaxBytes
    buffer~encoding = targetEncoding~asEncodingFor(buffer) -- raise an error if not compatible
    bufferStart = buffer~length + 1

    do i=1 to sizeB
        buffer~append(string~subchar(i))
        buffer~append("000000"x) -- little endian
    end

    convertedString = buffer~substr(bufferStart)
    -- It's a new string, without any encoding stored on it
    convertedString~encoding = targetEncoding
    if memorize, .nil \== text then text~internalIndexer~cacheString(targetEncoding, convertedString)

    if returnBuffer then return buffer
    convertedText = .RexxText~new(convertedString, targetEncoding)
    if memorize then convertedText~internalIndexer~cacheString(string~encoding, string)
    return convertedText


::method UTF32LE
    use strict arg -- none
    use strict named arg strict = .false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    if .nil <> buffer then return buffer~~append(self~string)
                      else return self~string~text


/*
::method Unicode32
    -- todo: is there an optim possible here ?
*/


/******************************************************************************/
/*
Strings of codepoints encoded as native integers.
Support 3 representations, depending on the character with the largest Unicode codepoint (1, 2, or 4 bytes).
Unlike the flexible representation of Python, the 3 representions are first-class, not internal.
No BOM, the endiannes is the CPU one. This is for internal use only.
Unicode32_Encoding can be used with utf8proc for theses functions taking a 32-bit buffer:

    Decompose a codepoint into an array of codepoints.
    UTF8PROC_DLLEXPORT utf8proc_ssize_t utf8proc_decompose_char(
      utf8proc_int32_t codepoint, utf8proc_int32_t *dst, utf8proc_ssize_t bufsize,
      utf8proc_option_t options, int *last_boundclass
    );

    The same as @ref utf8proc_decompose_char, but acts on a whole UTF-8
    string and orders the decomposed sequences correctly.
    UTF8PROC_DLLEXPORT utf8proc_ssize_t utf8proc_decompose(
      const utf8proc_uint8_t *str, utf8proc_ssize_t strlen,
      utf8proc_int32_t *buffer, utf8proc_ssize_t bufsize, utf8proc_option_t options
    );

    Normalizes the sequence of `length` codepoints pointed to by `buffer`
    in-place (i.e., the result is also stored in `buffer`).
    UTF8PROC_DLLEXPORT utf8proc_ssize_t utf8proc_normalize_utf32(
      utf8proc_int32_t *buffer, utf8proc_ssize_t length, utf8proc_option_t options);

    Reencodes the sequence of `length` codepoints pointed to by `buffer`
    UTF-8 data in-place (i.e., the result is also stored in `buffer`).
    Can optionally normalize the UTF-32 sequence prior to UTF-8 conversion.
    UTF8PROC_DLLEXPORT utf8proc_ssize_t utf8proc_reencode(
      utf8proc_int32_t *buffer, utf8proc_ssize_t length, utf8proc_option_t options);
*/
::class "Unicode_Encoding" mixinclass Object private

::method isUnicodeN class
    use strict arg -- none
    return .true


::method toSupport class
    use strict arg codepoint
    if codepoint < 256 then return .Unicode8_Encoding
    if codepoint < 65536 then return .Unicode16_Encoding
    return .Unicode32_Encoding


::method decodeCodepoint class private
    -- Will reach this method only once.
    -- After the first call, the message "decodeCodepoint" will be sent directly to the method specialized for this endianness
    if .Unicode~systemIsLittleEndian then self~setMethod("decodeCodepoint", self~instanceMethod("decodeCodepointLE"), "Object")
                                     else self~setMethod("decodeCodepoint", self~instanceMethod("decodeCodepointBE"), "Object")
    forward message "decodeCodepoint"


::method decodeCodepointBE class private
    use strict arg stringBytes
    -- precondition: stringBytes~length <= 4
    -- needed, the code unit is from 1 to 4 bytes.
    -- "3B9A C9FF"x~c2d = 999 999 999. The next value raises an error when 9 digits.
    -- The maximum value is "FFFF FFFF"x~c2d = 4 294 967 295 (10 digits)
    numeric digits 10
    return stringBytes~c2d


::method decodeCodepointLE class private
    use strict arg stringBytes
    -- precondition: stringBytes~length <= 4
    -- needed, the code unit is from 1 to 4 bytes.
    -- "3B9A C9FF"x~c2d = 999 999 999. The next value raises an error when 9 digits.
    -- The maximum value is "FFFF FFFF"x~c2d = 4 294 967 295 (10 digits)
    numeric digits 10
    return stringBytes~reverse~c2d


::method encodeCodepoint class private
    -- Will reach this method only once.
    -- After the first call, the message "encodeCodepoint" will be sent directly to the method specialized for this endianness
    if .Unicode~systemIsLittleEndian then self~setMethod("encodeCodepoint", self~instanceMethod("encodeCodepointLE"), "Object")
                                     else self~setMethod("encodeCodepoint", self~instanceMethod("encodeCodepointBE"), "Object")
    forward message "encodeCodepoint"


::method encodeCodepointBE class private
    use strict arg codepoint
    return codepoint~d2c(self~codeUnitSizeInBytes)


::method encodeCodepointLE class private
    use strict arg codepoint
    return codepoint~d2c(self~codeUnitSizeInBytes)~reverse


/********************/
/* Instance methods */
/********************/

::method Unicode
    use strict arg -- none
    use strict named arg strict = .false, buffer(1)=.nil
    if .nil <> buffer then return buffer~~append(self~string)
                      else return self~string~text


/******************************************************************************/
::class "Unicode8_Encoding" public inherit Unicode_Encoding Unicode_CommonServices StringIndexer

::constant name "Unicode8"
::constant isUnicode8 1
::constant codeUnitSizeInBytes 1
::constant codepointMaxBytes 1


::method checkCodepoint class
    -- All the codepoints in the range 0..255 are ok
    -- Remember : previousCodepoint can be .nil (first codepoint) or <0 (error recovery)
    --            when <0 abs(previousCodepoint) is the invalid value
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg checkOnlyRange=.false /*no impact here*/, errorInfo=.nil, checkingMaximumCodepoint=.false
    if .nil <> codepoint then do
        if codepoint < 0 | codepoint > 255 then signal error_range
    end
    return 1 -- a positive value means "no error"

    error_range: if checkingMaximumCodepoint then return error(0, self~name "encoding: invalid maximum codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..255")
                                             else return error(0, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..255")

    error:
        use strict arg whichCodepoint, errorMessage
        -- Ignore the argument errorInfo. If the codepoint is out of range then raise immediatly an error.
        -- I don't want to have thousands of errors recorded because someone try to get a Unicode8 string from a string containing thousands codepoint > 255.
        if .false then do -- .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return whichCodepoint -- -1 (previousCodepoint) or 0 (codepoint). A negative or null value means "error".
        end
        raise syntax 23.900 array (errorMessage)


::method decode class
    -- sizeB == -1 ==> this method will check the validity of the encoding
    -- sizeB <> -1 ==> this method assumes that the encoding has been checked and is valid
    use strict arg string /* or buffer */, startB=1, sizeB=(-1)
    if sizeB == -1 then do
        nextB = self~nextCodepointIndex(string, startB) -- raise error if invalid, so no need to test if < 0
        sizeB = nextB - startB
    end
    if sizeB == 0 then return .nil
    if sizeB == 1 then return string~subchar(startB)~c2d
    raise syntax 23.900 array (self~name "encoding:" sizeB "is an invalid size of byte sequence")


::method byteSequenceSize class
    -- Fast, minimal checks.
    -- Typical usage:
    --     indexer~decode(string, startB, indexer~byteSequenceSize(string, startB))
    -- By passing a non-negative size to ~decode, the checks are disabled.
    use strict arg string /* or buffer */, startB
    lengthB = string~length
    if startB > lengthB then return 0 -- end of string
    return 1


::method nextCodepointIndex class
    use strict arg string /* or buffer */, startB
    -- use named arg errorInfo=.nil
    if startB < 1 then return startB -- don't move because below start of string
    if startB > string~length then return startB -- don't move because below end of string
    return startB + 1


::method encode class
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg codepoint
    use strict named arg buffer(1)=.nil
    self~checkCodepoint(codepoint, checkOnlyRange: .true) -- check only range, the other errors will be detected during analysis
    if .nil <> buffer then return buffer~~append(codepoint~d2c)
                      else return .RexxText~new(codepoint~d2c, self)


::method codepointSizeInBytes class
    use strict arg codepoint
    self~checkCodepoint(codepoint, checkOnlyRange: .true)
    return 1


/********************/
/* Instance methods */
/********************/

::method codepointIndex
    use strict arg indexC
    if indexC < 1 then raise syntax 23.900 array (self~description "invalid codepoint index:" indexC)
    if indexC > self~codepointCount then indexC = self~codepointCount + 1
    return indexC


::method codepoint
    use strict arg indexC, decode=.true
    startB = self~codepointIndex(indexC)
    if decode then return self~string~subchar(startB)~c2d
              else return self~string~subchar(startB)


::method graphemeIndex
    use strict arg indexG
    if indexG < 1 then raise syntax 23.900 array (self~description "invalid grapheme index:" indexG)
    if indexG > self~graphemeCount then return self~string~length + 1
    if .nil == self~graphemeIndexes then return indexG
    indexB = self~graphemeIndexes[indexG]
    if .nil <> indexB then return indexB
    return indexG -- sparse array: the value is equal to the index


::method grapheme
    -- 2 modes:
    -- if the buffer is passed as argument then append the grapheme to the buffer, and return the buffer
    -- otherwise return the grapheme as a RexxText
    use strict arg indexG
    use strict named arg buffer(1)=.nil
    startB = self~graphemeIndex(indexG)
    if .nil == self~graphemeIndexes, self~graphemeCount == self~string~length then do
        -- Careful with this optimization! Testing just .nil is not enough since I no longer store the last index+1: even in the case .nil, the last grapheme can be more than one codepoint.
        if .nil <> buffer then return buffer~~append(self~string~subchar(indexG))
                          else return .RexxText~new(self~string~subchar(indexG), self~class)
    end
    nextB = self~graphemeIndex(indexG+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if .nil <> buffer then return buffer~~append(self~string~substr(absStartB, absNextB - absStartB))
                      else return .RexxText~new(self~string~substr(absStartB, absNextB - absStartB), self~class) -- yes, always the current byte sequence, even if invalid


/******************************************************************************/
::class "Unicode16_Encoding" public inherit Unicode_Encoding Unicode_CommonServices StringIndexer

::constant name "Unicode16"
::constant isUnicode16 1
::constant codeUnitSizeInBytes 2
::constant codepointMaxBytes 2


::method checkCodepoint class
    -- Isolated surrogates are ok, nothing to check regarding the surrogates
    -- Remember : previousCodepoint can be .nil (first codepoint) or <0 (error recovery)
    --            when <0 abs(previousCodepoint) is the invalid value
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg checkOnlyRange=.false /*no impact here*/, errorInfo=.nil, checkingMaximumCodepoint=.false
    if .nil <> codepoint then do
        if codepoint < 0 | codepoint > 65535 then signal error_range
    end
    return 1 -- a positive value means "no error"

    error_range: if checkingMaximumCodepoint then return error(0, self~name "encoding: invalid maximum codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..65535")
                                             else return error(0, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..65535")

    error:
        use strict arg whichCodepoint, errorMessage
        -- Ignore the argument errorInfo. If the codepoint is out of range then raise immediatly an error.
        -- I don't want to have thousands of errors recorded because someone try to get a Unicode8 string from a string containing thousands codepoint > 255.
        if .false then do -- .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return whichCodepoint -- -1 (previousCodepoint) or 0 (codepoint). A negative or null value means "error".
        end
        raise syntax 23.900 array (errorMessage)


::method decode class
    -- sizeB == -1 ==> this method will check the validity of the encoding
    -- sizeB <> -1 ==> this method assumes that the encoding has been checked and is valid
    use strict arg string /* or buffer */, startB=1, sizeB=(-1)
    if sizeB == -1 then do
        nextB = self~nextCodepointIndex(string, startB) -- raise error if invalid, so no need to test if < 0
        sizeB = nextB - startB
    end
    if sizeB == 0 then return .nil
    if sizeB == 2 then return self~decodeCodepoint(string~substr(startB, 2))
    raise syntax 23.900 array (self~name "encoding:" sizeB "is an invalid size of byte sequence")


::method byteSequenceSize class
    -- Fast, minimal checks.
    -- Typical usage:
    --     indexer~decode(string, startB, indexer~byteSequenceSize(string, startB))
    -- By passing a non-negative size to ~decode, the checks are disabled.
    use strict arg string /* or buffer */, startB
    lengthB = string~length
    if startB > lengthB then return 0 -- end of string
    if lengthB - startB < 1 then return -1 -- truncated
    return 2


::method nextCodepointIndex class
    use strict arg string /* or buffer */, startB
    use named arg errorInfo=.nil
    indexB = startB
    lengthB = string~length
    if indexB < 1 then return startB -- don't move because below start of string
    if indexB > lengthB then return startB -- don't move because beyond end of string
    if lengthB - indexB < 1 then signal truncated
    return indexB + 2

    -- Remember: in case of error, NEVER return nextCodepointIndex==startB
    -- because that would create an infinite loop when scanning (see CreateIndexer)
    -- MUST always advance.

    truncated: return error(indexB + 2, self~name "encoding: byte sequence at byte-position" startB "is truncated, expected 2 bytes")

    error:
        use strict arg nextCodepointIndex, errorMessage
        if .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return -nextCodepointIndex -- negative value means error
        end
        raise syntax 23.900 array (errorMessage)


::method encode class
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg codepoint
    use strict named arg buffer(1)=.nil
    self~checkCodepoint(codepoint, checkOnlyRange: .true) -- check only range, the other errors will be detected during analysis
    if .nil <> buffer then return buffer~~append(self~encodeCodepoint(codepoint))
                      else return .RexxText~new(self~encodeCodepoint(codepoint), self)


::method codepointSizeInBytes class
    use strict arg codepoint
    self~checkCodepoint(codepoint, checkOnlyRange: .true)
    return 2


::method encodeASCIIstring class
    use strict arg string
    use strict named arg memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil

    text = .nil
    if string~hasText then text = string~text

    targetEncoding = self
    if .nil \== text then do
        cachedString = text~internalIndexer~getCachedString(targetEncoding)
        if .nil \== cachedString then do
            if .nil <> buffer then return targetEncoding~append(cachedString, :buffer)
                              else return cachedString~text
        end
    end

    sizeB = string~length -- size in bytes
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new(, sizeB * 2)
    buffer~encoding = targetEncoding~asEncodingFor(buffer) -- raise an error if not compatible
    bufferStart = buffer~length + 1

    if .Unicode~systemIsLittleEndian then do
        loop i=1 to sizeB
            buffer~append(string~subchar(i))
            buffer~append("00"x) -- little endian
        end
    end
    else do
        loop i=1 to sizeB
            buffer~append("00"x) -- big endian
            buffer~append(string~subchar(i))
        end
    end

    convertedString = buffer~substr(bufferStart)
    -- It's a new string, without any encoding stored on it
    convertedString~encoding = targetEncoding
    if memorize, .nil \== text then text~internalIndexer~cacheString(targetEncoding, convertedString)

    if returnBuffer then return buffer
    convertedText = .RexxText~new(convertedString, targetEncoding)
    if memorize then convertedText~internalIndexer~cacheString(string~encoding, string)
    return convertedText


/********************/
/* Instance methods */
/********************/

::method codepointIndex
    use strict arg indexC
    if indexC < 1 then raise syntax 23.900 array (self~description "invalid codepoint index:" indexC)
    if indexC > self~codepointCount then return self~string~length + 1
    if .nil == self~codepointIndexes then return 2 * (indexC - 1) + 1
    indexB = self~codepointIndexes[indexC]
    if .nil <> indexB then return indexB
    return 2 * (indexC - 1) + 1 -- sparse array: the value can be derived from the index


::method codepoint
    -- to reimplement using a byte index because codepointIndexes will be removed
    use strict arg indexC, decode=.true
    startB = self~codepointIndex(indexC)
    if .nil == self~codepointIndexes, self~codepointCount == self~string~length then do
        -- Careful with this optimization! Testing just .nil is not enough since I no longer store the last index+1: even in the case .nil, the last codepoint can be 4 bytes.
        if decode then return self~class~decode(self~string, startB, 2)
                  else return self~string~substr(startB, 2)
    end
    nextB = self~codepointIndex(indexC+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if decode then do
        if startB < 0 then return .Unicode~replacementCharacter~codepoint -- the current byte sequence is invalid
        return self~class~decode(self~string, absStartB, absNextB - absStartB)
    end
    return self~string~substr(absStartB, absNextB - absStartB) -- yes, always the current byte sequence, even if invalid


::method graphemeIndex
    use strict arg indexG
    if indexG < 1 then raise syntax 23.900 array (self~description "invalid grapheme index:" indexG)
    if indexG > self~graphemeCount then return self~string~length + 1
    if .nil == self~graphemeIndexes then return 2 * (indexG - 1) + 1
    indexB = self~graphemeIndexes[indexG]
    if .nil <> indexB then return indexB
    return 2 * (indexG - 1) + 1 -- sparse array: the value can be derived from the index


::method grapheme
    -- 2 modes:
    -- if the buffer is passed as argument then append the grapheme to the buffer, and return the buffer
    -- otherwise return the grapheme as a RexxText
    use strict arg indexG
    use strict named arg buffer(1)=.nil
    startB = self~graphemeIndex(indexG)
    if .nil == self~graphemeIndexes, self~graphemeCount == self~string~length then do
        -- Careful with this optimization! Testing just .nil is not enough since I no longer store the last index+1: even in the case .nil, the last grapheme can be more than one codepoint
        if .nil <> buffer then return buffer~~append(self~string~substr(startB, 2))
                          else return .RexxText~new(self~string~substr(startB, 2), self~class)
    end
    nextB = self~graphemeIndex(indexG+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if .nil <> buffer then return buffer~~append(self~string~substr(absStartB, absNextB - absStartB))
                      else return .RexxText~new(self~string~substr(absStartB, absNextB - absStartB), self~class) -- yes, always the current byte sequence, even if invalid


/******************************************************************************/
::class "Unicode32_Encoding" public inherit Unicode_Encoding Unicode_CommonServices StringIndexer

::constant name "Unicode32"
::constant isUnicode32 1
::constant codeUnitSizeInBytes 4
::constant codepointMaxBytes 4


::method checkCodepoint class
    -- Surrogates are ok, nothing to check regarding the surrogates
    -- Remember : previousCodepoint can be .nil (first codepoint) or <0 (error recovery)
    --            when <0 abs(previousCodepoint) is the invalid value
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg checkOnlyRange=.false, errorInfo=.nil, checkingMaximumCodepoint=.false
    if .nil <> codepoint then do
        if codepoint < 0 | codepoint > .Unicode~maxCodepoint then signal error_range
    end
    return 1 -- a positive value means "no error"

    error_range: if checkingMaximumCodepoint then return error(0, self~name "encoding: invalid maximum codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..".Unicode~maxCodepoint)
                                             else return error(0, self~name "encoding: invalid codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(codepointIndexB) || ". Allowed range is 0..".Unicode~maxCodepoint)

    error:
        use strict arg whichCodepoint, errorMessage
        -- Ignore the argument errorInfo. If the codepoint is out of range then raise immediatly an error.
        -- I don't want to have thousands of errors recorded because someone try to get a Unicode8 string from a string containing thousands codepoint > 255.
        if .false then do -- .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return whichCodepoint -- -1 (previousCodepoint) or 0 (codepoint). A negative or null value means "error".
        end
        raise syntax 23.900 array (errorMessage)


::method decode class
    -- sizeB == -1 ==> this method will check the validity of the encoding
    -- sizeB <> -1 ==> this method assumes that the encoding has been checked and is valid
    use strict arg string /* or buffer */, startB=1, sizeB=(-1)
    if sizeB == -1 then do
        nextB = self~nextCodepointIndex(string, startB) -- raise error if invalid, so no need to test if < 0
        sizeB = nextB - startB
    end
    -- numeric digits 10 -- not needed, managed by decodeCodepoint
    if sizeB == 0 then return .nil
    if sizeB == 4 then return self~decodeCodepoint(string~substr(startB, 4))
    raise syntax 23.900 array (self~name "encoding:" sizeB "is an invalid size of byte sequence")


::method byteSequenceSize class
    -- Fast, minimal checks.
    -- Typical usage:
    --     indexer~decode(string, startB, indexer~byteSequenceSize(string, startB))
    -- By passing a non-negative size to ~decode, the checks are disabled.
    use strict arg string /* or buffer */, startB
    lengthB = string~length
    if startB > lengthB then return 0 -- end of string
    if lengthB - startB < 3 then return -1 -- truncated
    return 4


::method nextCodepointIndex class
    use strict arg string /* or buffer */, startB
    use named arg errorInfo=.nil
    indexB = startB
    lengthB = string~length
    if indexB < 1 then return startB -- don't move because below start of string
    if indexB > lengthB then return startB -- don't move because beyond end of string
    if lengthB - indexB < 3 then signal truncated
    return indexB + 4

    -- Remember: in case of error, NEVER return nextCodepointIndex==startB
    -- because that would create an infinite loop when scanning (see CreateIndexer)
    -- MUST always advance.

    truncated: return error(indexB + 4, self~name "encoding: byte sequence at byte-position" startB "is truncated, expected 4 bytes")

    error:
        use strict arg nextCodepointIndex, errorMessage
        if .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return -nextCodepointIndex -- negative value means error
        end
        raise syntax 23.900 array (errorMessage)


::method encode class
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg codepoint
    use strict named arg buffer(1)=.nil
    self~checkCodepoint(codepoint, checkOnlyRange: .true) -- check only range, the other errors will be detected during analysis
    if .nil <> buffer then return buffer~~append(self~encodeCodepoint(codepoint))
                      else return .RexxText~new(self~encodeCodepoint(codepoint), self)


::method codepointSizeInBytes class
    use strict arg codepoint
    self~checkCodepoint(codepoint, checkOnlyRange: .true)
    return 4


::method encodeASCIIstring class
    use strict arg string
    use strict named arg memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil

    text = .nil
    if string~hasText then text = string~text

    targetEncoding = self
    if .nil \== text then do
        cachedString = text~internalIndexer~getCachedString(targetEncoding)
        if .nil \== cachedString then do
            if .nil <> buffer then return targetEncoding~append(cachedString, :buffer)
                              else return cachedString~text
        end
    end

    sizeB = string~length -- size in bytes
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new(, sizeB * 4)
    buffer~encoding = targetEncoding~asEncodingFor(buffer) -- raise an error if not compatible
    bufferStart = buffer~length + 1

    if .Unicode~systemIsLittleEndian then do
        loop i=1 to sizeB
            buffer~append(string~subchar(i))
            buffer~append("000000"x) -- little endian
        end
    end
    else do
        loop i=1 to sizeB
            buffer~append("000000"x) -- big endian
            buffer~append(string~subchar(i))
        end
    end

    convertedString = buffer~substr(bufferStart)
    -- It's a new string, without any encoding stored on it
    convertedString~encoding = targetEncoding
    if memorize, .nil \== text then text~internalIndexer~cacheString(targetEncoding, convertedString)

    if returnBuffer then return buffer
    convertedText = .RexxText~new(convertedString, targetEncoding)
    if memorize then convertedText~internalIndexer~cacheString(string~encoding, string)
    return convertedText


/********************/
/* Instance methods */
/********************/

::method codepointIndex
    use strict arg indexC
    if indexC < 1 then raise syntax 23.900 array (self~description "invalid codepoint index:" indexC)
    if indexC > self~codepointCount then return self~string~length + 1
    if .nil == self~codepointIndexes then return 4 * (indexC - 1) + 1
    indexB = self~codepointIndexes[indexC]
    if .nil <> indexB then return indexB
    return 4 * (indexC - 1) + 1 -- sparse array: the value can be derived from the index


::method codepoint
    -- to reimplement using a byte index because codepointIndexes will be removed
    use strict arg indexC, decode=.true
    startB = self~codepointIndex(indexC)
    if .nil == self~codepointIndexes then do
        -- This optimization is possible despite I no longer store the last index+1: the last codepoint is always 4 bytes.
        if decode then return self~class~decode(self~string, startB, 4)
                  else return self~string~substr(startB, 4)
    end
    nextB = self~codepointIndex(indexC+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if decode then do
        if startB < 0 then return .Unicode~replacementCharacter~codepoint -- the current byte sequence is invalid
        return self~class~decode(self~string, absStartB, absNextB - absStartB)
    end
    return self~string~substr(absStartB, absNextB - absStartB) -- yes, always the current byte sequence, even if invalid


::method graphemeIndex
    use strict arg indexG
    if indexG < 1 then raise syntax 23.900 array (self~description "invalid grapheme index:" indexG)
    if indexG > self~graphemeCount then return self~string~length + 1
    if .nil == self~graphemeIndexes then return 4 * (indexG - 1) + 1
    indexB = self~graphemeIndexes[indexG]
    if .nil <> indexB then return indexB
    return 4 * (indexG - 1) + 1 -- sparse array: the value can be derived from the index


::method grapheme
    -- 2 modes:
    -- if the buffer is passed as argument then append the grapheme to the buffer, and return the buffer
    -- otherwise return the grapheme as a RexxText
    use strict arg indexG
    use strict named arg buffer(1)=.nil
    startB = self~graphemeIndex(indexG)
    if .nil == self~graphemeIndexes, self~graphemeCount == self~string~length then do
        -- Careful with this optimization! Testing just .nil is not enough since I no longer store the last index+1: even in the case .nil, the last grapheme can be more than one codepoint
        if .nil <> buffer then return buffer~~append(self~string~substr(startB, 4))
                          else return .RexxText~new(self~string~substr(startB, 4), self~class)
    end
    nextB = self~graphemeIndex(indexG+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if .nil <> buffer then return buffer~~append(self~string~substr(absStartB, absNextB - absStartB))
                      else return .RexxText~new(self~string~substr(absStartB, absNextB - absStartB), self~class) -- yes, always the current byte sequence, even if invalid


/******************************************************************************/
::class "CodePointSupplier" public subclass Supplier

::method init
    expose indexer indexC
    use strict arg indexer
    empty = .array~new(0) -- No need to create a copy, the string is immutable
    self~init:super(empty, empty)
    indexC = 1
    -- will add a byte index
    -- self~init:super -- Don't forward, would raise error "argument 1 is required"


::method count
    expose indexer
    use strict arg -- none
    return indexer~codepointCount


::method available
    expose indexer indexC
    use strict arg -- none
    return indexC <= indexer~codepointCount


::method index
    expose indexC
    use strict arg -- none
    if self~available then return indexC


::method item
    expose indexer indexC
    use strict arg decode=.true
    if self~available then return indexer~codepoint(indexC, decode)


::method next
    expose indexC
    use strict arg -- none
    indexC += 1
    -- will also manage a byte index


/******************************************************************************/
::class "GraphemeSupplier" public subclass Supplier

::method init
    expose indexer indexG
    use strict arg indexer
    empty = .array~new(0) -- No need to create a copy, the string is immutable
    self~init:super(empty, empty)
    indexG = 1
    -- self~init:super -- Don't forward, would raise error "argument 1 is required"


::method count
    expose indexer
    use strict arg -- none
    return indexer~graphemeCount


::method available
    expose indexer indexG
    use strict arg -- none
    return indexG <= indexer~graphemeCount


::method index
    expose indexG
    use strict arg -- none
    if self~available then return indexG


::method item
    expose indexer indexG
    use strict arg -- none
    if self~available then return indexer~grapheme(indexG)


::method next
    expose indexG
    use strict arg -- none
    indexG += 1


/******************************************************************************/
-- Helper to create a table of transcoded characters, from codepoint 0 to size-1.
-- By default, a transcoded character is equal to itself.
-- The specific transcoding table lets define specific values for some characters.
::routine createCharacterTranscodingTable private
    use strict arg size, specificTranscoding
    tableTranscodingToUnicode = .array~new(size)
    do i = 0 to size-1
        tableTranscodingToUnicode[i+1] = i -- bof bof... 1-based
    end
    nextSpecificIndex = 0
    do i=1 to specificTranscoding~items
        item = specificTranscoding[i]
        if item~right(1) == ":" then do -- Ends with colon, this is an index. For example: "80:"
            nextSpecificIndex = item~left(item~length - 1)~x2d
        end
        else do
            if item == "" then codepoint = "" -- no transcoding
            else if item~left(1) == "-" then codepoint = -(item~substr(2)~x2d) -- unused character with fallback transcoding. For example: "-81" --> -129
            else codepoint = item~x2d
            tableTranscodingToUnicode[nextSpecificIndex+1] = codepoint -- bof bof... 1-based array
            nextSpecificIndex += 1
        end
    end
    return tableTranscodingToUnicode


/******************************************************************************/
::routine ppCodepoint public
    /*
    Appendix A - Notational conventions
    In running text, an individual Unicode code point is expressed as U+n, where n is four to
    six hexadecimal digits, using the digits 0–9 and uppercase letters A–F (for 10 through 15,
    respectively). Leading zeros are omitted, unless the code point would have fewer than four
    hexadecimal digits—for example, U+0001, U+0012, U+0123, U+1234, U+12345, U+102345
    */
    use strict arg codepoint
    use strict named arg buffer(1)=.nil
    if \datatype(codepoint, "W") then return "not a whole number"
    if codepoint < 0 then return "-" || ppCodepoint(-codepoint)
    if .nil == buffer then do
        if codepoint < 65536 then return "U+" || codepoint~d2x(4)
        return "U+" || codepoint~d2x
    end
    else do
        buffer~append("U+")
        if codepoint < 65536 then buffer~append(codepoint~d2x(4))
        else buffer~append(codepoint~d2x)
        return buffer
    end


/******************************************************************************/
::routine ppHexNumber public
    -- Helper to display an hexadecimal value: 0 --> 00x, 255 --> FFx
    -- The value can be negative: -1 --> -01x
    use strict arg number
    if \datatype(number, "W") then return "not a whole number"
    sign = ""
    if sign(number) < 0 then sign = "-"
    number = abs(number)
    if number < 256 then size = 2
    else if number < 65536 then size = 4
    else if number < 16777216 then size = 6
    else size = 8
    return sign || number~d2x(size) || "x"


/******************************************************************************/
-- Helper to build error messages.
-- Sometimes, the byte index is not available.
::routine atBytePosition
    use strict arg byteIndex
    if .nil == byteIndex then return ""
    return " at byte-position" byteIndex -- Keep the space at the begining!
