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

--::options trace i


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
    tableTranscodingToUnicode = tables[1] -- an array
    tableTranscodingFromUnicode = tables[2] -- a directory


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
    use strict named arg checkOnlyRange=.false /*no impact here*/, errorInfo=.nil
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
        nextB = self~nextCodepointIndexB(string, startB) -- raise error if invalid, so no need to test if < 0
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


::method nextCodepointIndexB class
    use strict arg string /* or buffer */, startB
    -- use named arg errorInfo=.nil
    if startB < 1 then return startB -- don't move because below start of string
    if startB > string~length then return startB -- don't move because beyond end of string
    return startB + 1


::method previousCodepointIndexB class
    -- indexB is the index of the first byte of the current codepoint
    --   cp1  |cp2  |cp3...
    --   byte1|byte2|byte3...
    --   1    |2    |3
    -- For example, if indexB==3 then previousCodepointIndexB==2
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
    use strict named arg buffer=.nil
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

::method codepoint
    use strict arg indexC, decode=.true
    startB = self~codepointIndexB(indexC)
    if decode then return self~string~subchar(startB)~c2d
              else return self~string~subchar(startB)


::method character
    -- 2 modes:
    -- if the buffer is passed as argument then append the character to the buffer, and return the buffer
    -- otherwise return the character as a RexxText
    use strict arg indexC
    use strict named arg buffer=.nil
    startB = abs(self~characterIndexB(indexC))
    if .nil <> buffer then return buffer~~append(self~string~subchar(startB))
                      else return .RexxText~new(self~string~subchar(startB), self~encoding)


::method maximumUnicodeCodepoint
    -- Needed when converting to UnicodeN_Encoding (1st pass: get the maxium codepoint)
    -- Returns -1 if unknown (because of lack of transcoding table)
    -- Raise an error if at least one character can't be converted to Unicode
    -- Otherwise returns the maximum Unicode codepoint
    expose maximumUnicodeCodepoint -- cached
    use strict arg -- none
    use strict named arg replacementCodepoint=.nil -- .nil or "" or whole number
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
            if .nil == codepoint | codepoint == "" then do
                if .nil == replacementCodepoint then signal cannot_convert_character
                else if "" == replacementCodepoint then codepoint = 0 -- during the transcoding, any unsupported character is ignored (removed) when the replacement character is ""
                else codepoint = replacementCodepoint
            end
            -- A negative codepoint means unused character with fallback mapping
            maximumUnicodeCodepoint = max(maximumUnicodeCodepoint, abs(codepoint))
        end
    end
    return maximumUnicodeCodepoint

    cannot_convert_character: raise syntax 23.900 array("Cannot convert" self~description(short: .true) "character" charcode "("charcode~d2x") at byte-position" i "to Unicode")


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
    -- In case of transcoding error:
    -- if errorInfo is .nil (default) then raise the error
    -- otherwise store the error message in errorInfo and return .nil
    use strict arg targetEncoding
    use strict named arg strict=.false, memorize = (.Unicode~memorizeConversions), buffer=.nil, replacementCharacter=.nil, errorInfo=.nil

    replacementCodepoint = replacementCodepoint(replacementCharacter, targetEncoding)
    targetEncoding = .Encoding~factory(targetEncoding, self~string, :replacementCodepoint) -- replacementCodepoint is used for UnicodeN, to determine the maximumUnicodeCodepoint
    if targetEncoding~isUnicode then return self~convertToUnicode(targetEncoding, :strict, :memorize, :buffer, :replacementCodepoint, :errorInfo)
    if targetEncoding~isByte then return self~convertToByte(targetEncoding, :buffer)
    -- Should not reach here


::method convertToUnicode private
    use strict arg targetEncoding
    use strict named arg strict, memorize, buffer, replacementCodepoint, errorInfo

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
        indexB = self~codepointIndexB(i)
        codepoint = tableTranscodingToUnicode[charcode+1] -- bof bof... 1-based array
        codepoint = check_replace_codepoint()
        if .nil == codepoint then signal cannot_convert_character
        if codepoint \== "" then targetEncoding~encode(codepoint, indexB, :buffer)
    end

    string = buffer~substr(bufferStart)
    -- It's a new string, without any encoding stored on it
    string~encoding = targetEncoding
    if memorize then self~cacheString(targetEncoding~name, string)

    if returnBuffer then return buffer
    text = .RexxText~new(string, targetEncoding)
    if memorize then text~indexer~cacheString(self~encoding~name, self~string)
    return text

    cannot_convert_encoding:        return error("Cannot convert" self~description(short: .true) "to" targetEncoding~name)
    cannot_convert_character:       return error("Cannot convert" self~description(short: .true) "character" charcode "("charcode~d2x") at byte-position" i "to" targetEncoding~name)

    error:
        use strict arg errorMessage
        if .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return .nil
        end
        raise syntax 23.900 array (errorMessage)

    check_replace_codepoint:
        -- A .nil codepoint means no mapping
        -- An empty codepoint means no mapping
        -- A negative codepoint means unused character with fallback mapping
        if .nil == codepoint then return replacementCodepoint
        if codepoint == "" then return replacementCodepoint
        if strict, codepoint < 0 then return replacementCodepoint -- no fallback when strict
        return abs(codepoint)


::method convertToByte private
    use strict arg targetEncoding
    use strict named arg buffer

    string = .nil
    if self~encoding == targetEncoding then string = self~string
    else string = self~getCachedString(targetEncoding~name)
    if .nil \== string then do
        if .nil <> buffer then return targetEncoding~append(string, :buffer) -- buffer~~append(string)
                          else return string~text
    end
    -- Todo: I can transcode by using the source tableTranscodingToUnicode and the target tableTranscodingFromUnicode, without creating an intermediary text.
    signal not_supported

    not_supported:              raise syntax 23.900 array("Direct transcoding from '"self~encoding~name"' to '"targetEncoding~name"' is not supported")


::method c2u
    forward to (self~unicodeN(strict:.false, replacementCharacter:.Unicode~replacementCharacter))


::method unicodeCharacters
    forward to (self~unicodeN(strict:.false, replacementCharacter:.Unicode~replacementCharacter))


::method UTF8
    use strict arg -- none
    forward message "transcodeTo" arguments ( .array~of(.UTF8_Encoding) )


::method WTF8
    use strict arg -- none
    forward message "transcodeTo" arguments ( .array~of(.WTF8_Encoding) )


::method UTF16
    forward message "UTF16BE"


::method UTF16BE
    use strict arg -- none
    forward message "transcodeTo" arguments ( .array~of(.UTF16BE_Encoding) )


::method UTF16LE
    use strict arg -- none
    forward message "transcodeTo" arguments ( .array~of(.UTF16LE_Encoding) )


::method WTF16
    forward message "WTF16BE"


::method WTF16BE
    use strict arg -- none
    forward message "transcodeTo" arguments ( .array~of(.WTF16BE_Encoding) )


::method WTF16LE
    use strict arg -- none
    forward message "transcodeTo" arguments ( .array~of(.WTF16LE_Encoding) )


::method UTF32
    forward message "UTF32BE"


::method UTF32BE
    use strict arg -- none
    forward message "transcodeTo" arguments ( .array~of(.UTF32BE_Encoding) )


::method UTF32LE
    use strict arg -- none
    forward message "transcodeTo" arguments ( .array~of(.UTF32LE_Encoding) )


::method Unicode
    forward message "UnicodeN"


::method UnicodeN
    use strict arg -- none
    use named arg replacementCharacter
    forward message "transcodeTo" arguments ( .array~of("UnicodeN") )


::method Unicode8
    use strict arg -- none
    forward message "transcodeTo" arguments ( .array~of(.Unicode8_Encoding) )


::method Unicode16
    use strict arg -- none
    forward message "transcodeTo" arguments ( .array~of(.Unicode16_Encoding) )


::method Unicode32
    use strict arg -- none
    forward message "transcodeTo" arguments ( .array~of(.Unicode32_Encoding) )


/******************************************************************************/
-- Helper to create a table of transcoded characters, from codepoint 0 to size-1.
-- By default, a transcoded character is equal to itself.
-- The specific transcoding table lets define specific values for some characters.
::routine createCharacterTranscodingTable public -- private
    use strict arg size, specificTranscoding=(.array~new)

    -- The default mapping is equal to the character code
    tableTranscodingToUnicode = .array~new(size)
    -- Pre-fill the table for all the source-encoding characters
    -- Some of them will be replaced by a specific value
    tableTranscodingFromUnicode = .directory~new/*(size)*/
    do i = 0 to size-1
        tableTranscodingToUnicode[i+1] = i -- bof bof... 1-based
    end

    -- Now replace the mappings for which a specific value is defined
    /* Example of declaration of specific values (this is an array)
        , --    00      01      02      03      04      05      06      07      08      09      0A      0B      0C      0D      0E      0F
        "80:",  "20AC",  "-81", "201A", "0192", "201E", "2026", "2020", "2021", "02C6", "2030", "0160", "2039", "0152",  "-8D", "017D",  "-8F",,
        "90:",   "-90", "2018", "2019", "201C", "201D", "2022", "2013", "2014", "02DC", "2122", "0161", "203A", "0153",  "-9D", "017E", "0178"

       The current index is set to "80:" (ends with colon)
       Current index + "00": The code 80 is mapped to "20AC"
       Current index + "01": The code 81 is mapped to "-81" (fallback if not strict conversion, otherwise error)
       Etc...
       For convenience, these notations can be used to indicate that a mapping is equal to the code:
       , "=", ...
       ,    , ...       Omitted value
    */
    nextSpecificIndex = 0
    do i=1 to specificTranscoding~items
        item = specificTranscoding[i]
        if .nil \== item, item~right(1) == ":" then do -- Ends with colon, this is an index. For example: "80:"
            nextSpecificIndex = item~left(item~length - 1)~x2d
        end
        else do
            if .nil \== item, item \== "=" then do
                if item == "" then codepoint = "" -- no transcoding
                else if item~left(1) == "-" then codepoint = -(item~substr(2)~x2d) -- unused character with fallback transcoding. For example: "-81" --> -129
                else codepoint = item~x2d

                tableTranscodingToUnicode[nextSpecificIndex+1] = codepoint -- bof bof... 1-based array
                if \tableTranscodingFromUnicode~hasIndex(nextSpecificIndex) then tableTranscodingFromUnicode~put(.nil, nextSpecificIndex) -- explicitely put .nil, doesn't map to itself
                tableTranscodingFromUnicode~put(nextSpecificIndex * sign(codepoint), abs(codepoint))
            end
            nextSpecificIndex += 1
        end
    end
    -- Put the mapping for the characters which maps to themselves (i.e. not already in the table)
    do i = 0 to size-1
        if \tableTranscodingFromUnicode~hasIndex(i) then tableTranscodingFromUnicode~put(i, i)
    end
    return .array~of(tableTranscodingToUnicode, tableTranscodingFromUnicode)
