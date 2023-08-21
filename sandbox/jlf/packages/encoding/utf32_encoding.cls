.encoding~register("UTF32", .UTF32BE_Encoding)
.encoding~register("UTF32BE", .UTF32BE_Encoding)
.encoding~register("UTF32LE", .UTF32LE_Encoding)
--.encoding~register("UCS4BE", .UTF32BE_Encoding)     -- Alias defined in Ruby, but I'm not convinced it's a good alias for UTF-32BE
--.encoding~register("UCS4LE", .UTF32LE_Encoding)     -- Alias defined in Ruby, but I'm not convinced it's a good alias for UTF-32LE

::requires "encoding/encoding.cls"
::requires "encoding/unicode_common.cls"
::requires "encoding/stringIndexer.cls"
::requires "encoding/byte_common.cls" -- for atBytePosition

-- ::requires "encoding/unicode.cls"    -- .Unicode
-- ::requires "extension/text.cls"      -- .RexxText


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
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg buffer(1)=.nil
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new(, 4) -- yes, always 4, no need to use codepointMaxBytes
    self~checkCodepoint(codepoint, codepointIndexB, previousCodepoint, previousCodepointIndexB, checkOnlyRange: .true) -- check only range, the other errors will be detected during analysis
    buffer~append(self~encodeCodepoint(codepoint))
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self)


::method codepointSizeInBytes class
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    self~checkCodepoint(codepoint, codepointIndexB, previousCodepoint, previousCodepointIndexB, checkOnlyRange: .true)
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
        if decode then return self~encoding~decode(self~string, startB, 4)
                  else return self~string~substr(startB, 4)
    end
    nextB = self~codepointIndex(indexC+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if decode then do
        if startB < 0 then return .Unicode~replacementCharacter~codepoint -- the current byte sequence is invalid
        return self~encoding~decode(self~string, absStartB, absNextB - absStartB)
    end
    return self~string~substr(absStartB, absNextB - absStartB) -- yes, always the current byte sequence, even if invalid


::method characterIndex
    use strict arg indexG
    if indexG < 1 then raise syntax 23.900 array (self~description "invalid character index:" indexG)
    if indexG > self~characterCount then return self~string~length + 1
    if .nil == self~characterIndexes then return 4 * (indexG - 1) + 1
    indexB = self~characterIndexes[indexG]
    if .nil <> indexB then return indexB
    return 4 * (indexG - 1) + 1 -- sparse array: the value can be derived from the index


::method character
    -- 2 modes:
    -- if the buffer is passed as argument then append the character to the buffer, and return the buffer
    -- otherwise return the character as a RexxText
    use strict arg indexG
    use strict named arg buffer(1)=.nil
    startB = self~characterIndex(indexG)
    if .nil == self~characterIndexes, self~characterCount == self~string~length then do
        -- Careful with this optimization! Testing just .nil is not enough since I no longer store the last index+1: even in the case .nil, the last character can be more than one codepoint
        if .nil <> buffer then return buffer~~append(self~string~substr(startB, 4))
                          else return .RexxText~new(self~string~substr(startB, 4), self~encoding)
    end
    nextB = self~characterIndex(indexG+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if .nil <> buffer then return buffer~~append(self~string~substr(absStartB, absNextB - absStartB))
                      else return .RexxText~new(self~string~substr(absStartB, absNextB - absStartB), self~encoding) -- yes, always the current byte sequence, even if invalid


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
        cachedString = text~indexer~getCachedString(targetEncoding~name)
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
    if memorize, .nil \== text then text~indexer~cacheString(targetEncoding~name, convertedString)

    if returnBuffer then return buffer
    convertedText = .RexxText~new(convertedString, targetEncoding)
    if memorize then convertedText~indexer~cacheString(string~encoding~name, string)
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
        cachedString = text~indexer~getCachedString(targetEncoding~name)
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
    if memorize, .nil \== text then text~indexer~cacheString(targetEncoding~name, convertedString)

    if returnBuffer then return buffer
    convertedText = .RexxText~new(convertedString, targetEncoding)
    if memorize then convertedText~indexer~cacheString(string~encoding~name, string)
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
