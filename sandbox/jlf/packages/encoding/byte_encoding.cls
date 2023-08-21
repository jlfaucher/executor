.encoding~register("BYTE", .Byte_Encoding)
.encoding~register("BYTES", .Byte_Encoding)
.encoding~register("ASCII8BIT", .Byte_Encoding)     -- Alias defined in Ruby
.encoding~register("BINARY", .Byte_Encoding)        -- Alias defined in Ruby

--::requires "encoding/unicode_common.cls"
::requires "encoding/byte_common.cls"
::requires "encoding/stringIndexer.cls"
::requires "encoding/encoding.cls"
::requires "extension/string.cls" -- for ppHexNumber

-- ::requires "encoding/unicode.cls"    -- .Unicode
-- ::requires "extension/text.cls"      -- .RexxText

/*
Depends on
.UNICODE16_ENCODING
.UNICODE32_ENCODING
.UNICODE8_ENCODING
.UTF16BE_ENCODING
.UTF16LE_ENCODING
.UTF32BE_ENCODING
.UTF32LE_ENCODING
.UTF8_ENCODING
.WTF16BE_ENCODING
.WTF16LE_ENCODING
.WTF8_ENCODING
*/


/******************************************************************************/
::class "Byte_Encoding" public inherit Byte_CommonServices StringIndexer

::constant name "Byte"
::constant isByte 1
::constant codeUnitSizeInBytes 1
::constant codepointMaxBytes 1
::constant isCompatibleWithASCII 1  -- can be set to false by subclasses


::attribute tableTranscodingToUnicode class get
::attribute tableTranscodingFromUnicode class get


::method activate class
    expose tableTranscodingToUnicode tableTranscodingFromUnicode
    tables = createCharacterTranscodingTable(128) -- direct mapping of the first 128 characters, no need of specificTranscoding
    tableTranscodingToUnicode = tables[1]
    tableTranscodingFromUnicode = tables[2]


::method analyze class
    use strict arg string
    sizeB = string~length -- size in bytes
    case = 0
    if string~datatype("L") then case = 1
    if case == 0,  string~datatype("U") then case = 2
    -- Bytes, codepoints and characters are identical
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
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg buffer(1)=.nil
    self~checkCodepoint(codepoint, codepointIndexB, previousCodepoint, previousCodepointIndexB, checkOnlyRange: .true) -- check only range, the other errors will be detected during analysis
    if .nil <> buffer then return buffer~~append(codepoint~d2c)
                      else return .RexxText~new(codepoint~d2c, self)


::method codepointSizeInBytes class
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    self~checkCodepoint(codepoint, codepointIndexB, previousCodepoint, previousCodepointIndexB, checkOnlyRange: .true)
    return 1


::method codepointToLowerSimple class
    use strict arg codepoint
    if 65 <= codepoint, codepoint <= 90 then return codepoint + 32
    return codepoint


::method codepointToLowerFull class
    forward message "codepointToLowerSimple"


::method codepointToUpperSimple class
    use strict arg codepoint
    if 97 <= codepoint, codepoint <= 122 then return codepoint - 32
    return codepoint


::method codepointToUpperFull class
    forward message "codepointToUpperSimple"


::method codepointToTitleSimple class
    use strict arg codepoint
    if 97 <= codepoint, codepoint <= 122 then return codepoint - 32
    return codepoint


::method codepointToTitleFull class
    forward message "codepointToTitleSimple"


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


::method characterIndex
    use strict arg indexG
    if indexG < 1 then raise syntax 23.900 array (self~description "invalid character index:" indexG)
    if indexG > self~characterCount then indexG = self~string~length + 1
    return indexG


::method character
    -- 2 modes:
    -- if the buffer is passed as argument then append the character to the buffer, and return the buffer
    -- otherwise return the character as a RexxText
    use strict arg indexG
    use strict named arg buffer(1)=.nil
    startB = abs(self~characterIndex(indexG))
    if .nil <> buffer then return buffer~~append(self~string~subchar(startB))
                      else return .RexxText~new(self~string~subchar(startB), self~encoding)


::method maximumUnicodeCodepoint
    -- Needed when converting to UnicodeN_Encoding (1st pass: get the maxium codepoint)
    -- Returns -1 if unknown (because of lack of transcoding table)
    -- Raise an error if at least one character can't be converted to Unicode
    -- Otherwise returns the maximum Unicode codepoint
    expose maximumUnicodeCodepoint -- cached
    use strict arg -- none
    if var("maximumUnicodeCodepoint") then return maximumUnicodeCodepoint
    maximumUnicodeCodepoint = -1
    tableTranscodingToUnicode = self~encoding~tableTranscodingToUnicode
    if .nil <> tableTranscodingToUnicode then do
        maximumUnicodeCodepoint = 0 -- In case of empty string, to let convert to Unicode8
        sizeC = self~codepointCount -- size in codepoints
        do i=1 to sizeC
            charcode = self~codepoint(i)
            codepoint = tableTranscodingToUnicode[charcode+1] -- bof bof... 1-based array
            -- .nil means "cannot convert"
            -- An empty string means no mapping
            if .nil == codepoint | codepoint == "" then signal cannot_convert_character
            -- A negative codepoint means unused character with fallback mapping
            maximumUnicodeCodepoint = max(maximumUnicodeCodepoint, abs(codepoint))
        end
    end
    return maximumUnicodeCodepoint

    cannot_convert_character: raise syntax 23.900 array(self~encoding~name "encoding: cannot convert" self~description(short: .true) "character" charcode "("charcode~d2x") at byte-position" i "to Unicode")


/*
Remember
https://groups.io/g/rexxla-members/message/857
-- Code for translating common national-language glyphs from 0850 to 1252 codepoints
oubytes = 'c7fce9e2e4e0e5e7eaebe8efeeecc4c5c9e6c6f4f6f2fbf9ffd6dcf8a3d8d783e1edf3faf1d1aababfaeacbdbca1ab'x ,
        ||'bbc1c2c0a9a2a5e3c3a4f0d0cacbc8cdcecfa6ccd3dfd4d2f5d5b5dadbd9fdddafb4adb1beb6a7f7b8b0a8b7b9b3b2'x
inbytes = '808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadae'x ,
        ||'afb5b6b7b8bdbec6c7cfd0d1d2d3d4d6d7d8dddee0e1e2e3e4e5e6e9eaebecedeeeff0f1f3f4f5f6f7f8f9fafbfcfd'x
newline = translate(oldline,oubytes,inbytes)

*/

::method transcodeTo
    use strict arg targetEncoding
    targetEncoding = .Encoding~factory(targetEncoding, self~string)
    if targetEncoding~isUnicode then forward message "convertToUnicode"
    if targetEncoding~isByte then forward message "convertToByte"
    -- Should not reach here


::method convertToUnicode private
    use strict arg targetEncoding
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil, replacementCharacter(7)=.nil

    targetEncoding = .Encoding~factory(targetEncoding, self~string)
    if \targetEncoding~isUnicode then signal target_encoding_not_unicode

    if self~string~isASCII then return targetEncoding~encodeASCIIstring(self~string, :memorize, :buffer)

    tableTranscodingToUnicode = self~encoding~tableTranscodingToUnicode
    if .nil == tableTranscodingToUnicode then signal cannot_convert_encoding

    string = self~getCachedString(targetEncoding~name)
    if .nil \== string then do
        if .nil <> buffer then return targetEncoding~append(string, :buffer)
                          else return string~text
    end

    sizeC = self~codepointCount -- size in codepoints
    returnBuffer = .nil <> buffer

    if .nil == buffer then buffer = .MutableBuffer~new(, sizeC * targetEncoding~codepointMaxBytes)
    buffer~encoding = targetEncoding~asEncodingFor(buffer) -- raise an error if not compatible

    bufferStart = buffer~length + 1
    do i=1 to sizeC
        charcode = self~codepoint(i)
        indexB = self~codepointIndex(i)
        codepoint = tableTranscodingToUnicode[charcode+1] -- bof bof... 1-based array
        -- An empty string means no mapping
        -- A negative codepoint means unused character with fallback mapping
        if .nil == codepoint then signal cannot_convert_character
        if codepoint == "" then signal cannot_convert_character
        if strict, codepoint < 0 then signal cannot_convert_character
        targetEncoding~encode(abs(codepoint), indexB, :buffer)
    end

    string = buffer~substr(bufferStart)
    -- It's a new string, without any encoding stored on it
    string~encoding = targetEncoding
    if memorize then self~cacheString(targetEncoding~name, string)

    if returnBuffer then return buffer
    text = .RexxText~new(string, targetEncoding)
    if memorize then text~indexer~cacheString(self~encoding~name, self~string)
    return text

    target_encoding_not_unicode:    raise syntax 23.900 array("The target encoding '"targetEncoding~name"' is not a Unicode encoding")
    cannot_convert_encoding:        raise syntax 23.900 array(self~encoding~name "encoding: cannot convert" self~description(short: .true) "to" targetEncoding~name)
    cannot_convert_character:       raise syntax 23.900 array(self~encoding~name "encoding: cannot convert" self~description(short: .true) "character" charcode "("charcode~d2x") at byte-position" i "to" targetEncoding~name)


::method convertToByte private
    use strict arg targetEncoding
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil, replacementCharacter(7)=.nil

    targetEncoding = .Encoding~factory(targetEncoding, self~string)
    if \targetEncoding~isByte then signal target_encoding_not_byte

    string = .nil
    if self~encoding == targetEncoding then string = self~string
    else string = self~getCachedString(targetEncoding~name)
    if .nil \== string then do
        if .nil <> buffer then return targetEncoding~append(string, :buffer) -- buffer~~append(string)
                          else return string~text
    end
    -- Todo: if ASCII then I can transcode
    signal not_supported

    not_supported:              raise syntax 23.900 array("Direct transcoding from '"self~encoding~name"' to '"targetEncoding~name"' is not supported")
    target_encoding_not_byte:   raise syntax 23.900 array("The target encoding '"targetEncoding~name"' is not a Byte encoding")


::method UTF8
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    return self~convertToUnicode(.UTF8_Encoding, :strict, :memorize, :buffer)


::method WTF8
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    return self~convertToUnicode(.WTF8_Encoding, :strict, :memorize, :buffer)


::method UTF16
    forward message "UTF16BE"


::method UTF16BE
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    return self~convertToUnicode(.UTF16BE_Encoding, :strict, :memorize, :buffer)


::method UTF16LE
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    return self~convertToUnicode(.UTF16LE_Encoding, :strict, :memorize, :buffer)


::method WTF16
    forward message "WTF16BE"


::method WTF16BE
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    return self~convertToUnicode(.WTF16BE_Encoding, :strict, :memorize, :buffer)


::method WTF16LE
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    return self~convertToUnicode(.WTF16LE_Encoding, :strict, :memorize, :buffer)


::method UTF32
    forward message "UTF32BE"


::method UTF32BE
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    return self~convertToUnicode(.UTF32BE_Encoding, :strict, :memorize, :buffer)


::method UTF32LE
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    return self~convertToUnicode(.UTF32LE_Encoding, :strict, :memorize, :buffer)


::method Unicode
    forward message "UnicodeN"


::method UnicodeN
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    return self~convertToUnicode("UnicodeN", :strict, :memorize, :buffer)


::method Unicode8
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    return self~convertToUnicode(.Unicode8_Encoding, :strict, :memorize, :buffer)


::method Unicode16
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    return self~convertToUnicode(.Unicode16_Encoding, :strict, :memorize, :buffer)


::method Unicode32
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    return self~convertToUnicode(.Unicode32_Encoding, :strict, :memorize, :buffer)
