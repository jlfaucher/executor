::requires "encoding/unicode_common.cls"
::requires "encoding/byte_common.cls" -- for atBytePosition
::requires "encoding/stringIndexer.cls" -- for ppCodepoint


/******************************************************************************/
::class "XTF16_CommonServices" mixinclass Object public -- private
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
::class "XTF16BE_CommonServices" mixinclass Object public -- private
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
        cachedString = text~internalIndexer~getCachedString(targetEncoding~name)
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
    if memorize, .nil \== text then text~internalIndexer~cacheString(targetEncoding~name, convertedString)

    if returnBuffer then return buffer
    convertedText = .RexxText~new(convertedString, targetEncoding)
    if memorize then convertedText~internalIndexer~cacheString(string~encoding~name, string)
    return convertedText


::method UTF16BE
    use strict arg -- none
    use strict named arg strict = .false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil

    if .nil <> buffer then return self~class~append(self~string, :buffer)
    if self~class~isUTF16BE then return self~string~text

    targetEncoding = .UTF16BE_Encoding
    string = self~getCachedString(targetEncoding~name)
    if .nil \== string then return string~text

    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    text = .RexxText~new(.String~new(self~string), targetEncoding)
    if memorize then do
        self~cacheString(targetEncoding~name, text~string)
        text~internalIndexer~cacheString(self~class~name, self~string)
    end
    return text


::method WTF16BE
    use strict arg -- none
    use strict named arg strict = .false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil

    if .nil <> buffer then return self~class~append(self~string, :buffer)
    if self~class~isWTF16BE then return self~string~text

    targetEncoding = .WTF16BE_Encoding
    string = self~getCachedString(targetEncoding~name)
    if .nil \== string then return string~text

    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    text = .RexxText~new(.String~new(self~string), targetEncoding)
    if memorize then do
        self~cacheString(targetEncoding~name, text~string)
        text~internalIndexer~cacheString(self~class~name, self~string)
    end
    return text


/*
::method Unicode16
    -- todo: is there an optim possible here ?
*/


/******************************************************************************/
::class "XTF16LE_CommonServices" mixinclass Object public -- private
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
        cachedString = text~internalIndexer~getCachedString(targetEncoding~name)
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
    if memorize, .nil \== text then text~internalIndexer~cacheString(targetEncoding~name, convertedString)

    if returnBuffer then return buffer
    convertedText = .RexxText~new(convertedString, targetEncoding)
    if memorize then convertedText~internalIndexer~cacheString(string~encoding~name, string)
    return convertedText


::method UTF16LE
    use strict arg -- none
    use strict named arg strict = .false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil

    if .nil <> buffer then return buffer~~append(self~string)
    if self~class~isUTF16LE then return self~string~text

    targetEncoding = .UTF16LE_Encoding
    string = self~getCachedString(targetEncoding~name)
    if .nil \== string then return string~text

    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    text = .RexxText~new(.String~new(self~string), targetEncoding)
    if memorize then do
        self~cacheString(targetEncoding~name, text~string)
        text~internalIndexer~cacheString(self~class~name, self~string)
    end
    return text


::method WTF16LE
    use strict arg -- none
    use strict named arg strict = .false, memorize(3) = (.Unicode~memorizeConversions), buffer(1)=.nil

    if .nil <> buffer then return buffer~~append(self~string)
    if self~class~isWTF16LE then return self~string~text

    targetEncoding = .WTF16LE_Encoding
    string = self~getCachedString(targetEncoding~name)
    if .nil \== string then return string~text

    -- yes, always a new string.
    -- Don't use string~copy, because the reference to the associated text is in the copy,
    -- and that forbids to assign a new RexxText.
    text = .RexxText~new(.String~new(self~string), targetEncoding)
    if memorize then do
        self~cacheString(targetEncoding~name, text~string)
        text~internalIndexer~cacheString(self~class~name, self~string)
    end
    return text


/*
::method Unicode16
    -- todo: is there an optim possible here ?
*/


/******************************************************************************/
::class "UTF16_CommonServices" mixinclass Object public -- private

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
