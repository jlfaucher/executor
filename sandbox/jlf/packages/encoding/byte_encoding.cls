.encoding~register("BYTE", .Byte_Encoding)
.encoding~register("BYTES", .Byte_Encoding)

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
.UNICODE_ENCODING
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
                      else return .RexxText~new(self~string~subchar(startB), self~encoding)


::method maximumUnicodeCodepoint private
    -- Needed when converting to Unicode_Encoding (1st pass: get the maxium codepoint)
    -- Don't do any check, will be done by convertByteToUnicode (2nd pass)
    expose maximumUnicodeCodepoint -- cached
    use strict arg -- none
    if var("maximumUnicodeCodepoint") then return maximumUnicodeCodepoint
    maximumUnicodeCodepoint = 0
    tableTranscodingToUnicode = self~encoding~tableTranscodingToUnicode
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

::method convertByteToUnicode private
    use strict arg targetEncoding
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil

    tableTranscodingToUnicode = self~encoding~tableTranscodingToUnicode
    if .nil == tableTranscodingToUnicode then signal cannot_convert

    string = self~getCachedString(targetEncoding~name)
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
    if memorize then self~cacheString(targetEncoding~name, string)

    if returnBuffer then return buffer
    text = .RexxText~new(string, targetEncoding)
    if memorize then text~indexer~cacheString(self~encoding~name, self~string)
    return text

    cannot_convert:          raise syntax 23.900 array(self~encoding~name "encoding: cannot convert" self~description(short: .true) "to" targetEncoding~name)


::method UTF8
    use strict named arg strict=.false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil
    targetEncoding = .UTF8_Encoding
    if self~string~isASCII then do
        if .nil <> buffer then return targetEncoding~append(self~string, :buffer)

        string = self~getCachedString(targetEncoding~name)
        if .nil \== string then return string~text

        -- yes, always a new string. The original string is still associated to the Byte_Encoding.
        -- Don't use string~copy, because the reference to the associated text is in the copy,
        -- and that forbids to assign a new RexxText.
        text = .RexxText~new(.String~new(self~string), targetEncoding)
        if memorize then do
            self~cacheString(targetEncoding~name, text~string)
            text~indexer~cacheString(self~encoding~name, self~string)
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

        string = self~getCachedString(targetEncoding~name)
        if .nil \== string then return string~text

        -- yes, always a new string. The original string is still associated to the Byte_Encoding.
        -- Don't use string~copy, because the reference to the associated text is in the copy,
        -- and that forbids to assign a new RexxText.
        text = .RexxText~new(.String~new(self~string), targetEncoding)
        if memorize then do
            self~cacheString(targetEncoding~name, text~string)
            text~indexer~cacheString(self~encoding~name, self~string)
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

        string = self~getCachedString(targetEncoding~name)
        if .nil \== string then return string~text

        -- yes, always a new string. The original string is still associated to the Byte_Encoding.
        -- Don't use string~copy, because the reference to the associated text is in the copy,
        -- and that forbids to assign a new RexxText.
        text = .RexxText~new(.String~new(self~string), targetEncoding)
        if memorize then do
            self~cacheString(targetEncoding~name, text~string)
            text~indexer~cacheString(self~encoding~name, self~string)
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
