.encoding~register("UNICODE32", .Unicode32_Encoding)

::requires "encoding/encoding.cls"
::requires "encoding/unicodeN_encoding.cls"
::requires "encoding/unicode_common.cls"
::requires "encoding/stringIndexer.cls"
::requires "encoding/byte_common.cls" -- for atBytePosition

-- ::requires "encoding/unicode.cls"    -- .Unicode
-- ::requires "extension/text.cls"      -- .RexxText


/******************************************************************************/
::class "Unicode32_Encoding" public inherit UnicodeN_Encoding Unicode_CommonServices StringIndexer

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
        nextB = self~nextCodepointIndexB(string, startB) -- raise error if invalid, so no need to test if < 0
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


::method nextCodepointIndexB class
    use strict arg string /* or buffer */, startB
    use named arg errorInfo=.nil
    indexB = startB
    lengthB = string~length
    if indexB < 1 then return startB -- don't move because below start of string
    if indexB > lengthB then return startB -- don't move because beyond end of string
    if lengthB - indexB < 3 then signal truncated
    return indexB + 4

    -- Remember: in case of error, NEVER return nextCodepointIndexB==startB
    -- because that would create an infinite loop when scanning (see CreateIndexer)
    -- MUST always advance.

    truncated: return error(indexB + 4, self~name "encoding: byte sequence at byte-position" startB "is truncated, expected 4 bytes")

    error:
        use strict arg nextCodepointIndexB, errorMessage
        if .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return -nextCodepointIndexB -- negative value means error
        end
        raise syntax 23.900 array (errorMessage)


::method encode class
    -- 2 modes:
    -- if the buffer is passed as argument then append the encoded codepoint to the buffer, and return the buffer
    -- otherwise return the encoded codepoint as a RexxText
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    use strict named arg buffer=.nil
    self~checkCodepoint(codepoint, codepointIndexB, previousCodepoint, previousCodepointIndexB, checkOnlyRange: .true) -- check only range, the other errors will be detected during analysis
    if .nil <> buffer then return buffer~~append(self~encodeCodepoint(codepoint))
                      else return .RexxText~new(self~encodeCodepoint(codepoint), self)


::method codepointSizeInBytes class
    use strict arg codepoint, codepointIndexB=.nil, previousCodepoint=.nil, previousCodepointIndexB=.nil
    self~checkCodepoint(codepoint, codepointIndexB, previousCodepoint, previousCodepointIndexB, checkOnlyRange: .true)
    return 4


::method encodeASCIIstring class
    use strict arg string
    use strict named arg memorize = (.Unicode~memorizeConversions), buffer=.nil

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
    if memorize, .nil \== text then text~indexer~cacheString(targetEncoding~name, convertedString)

    if returnBuffer then return buffer
    convertedText = .RexxText~new(convertedString, targetEncoding)
    if memorize then convertedText~indexer~cacheString(string~encoding~name, string)
    return convertedText


/********************/
/* Instance methods */
/********************/

::method codepoint
    -- to reimplement using a byte index because codepointIndexes will be removed
    use strict arg indexC, decode=.true
    startB = self~codepointIndexB(indexC)
    if .nil == self~codepointIndexes then do
        -- This optimization is possible despite I no longer store the last index+1: the last codepoint is always 4 bytes.
        if decode then return self~encoding~decode(self~string, startB, 4)
                  else return self~string~substr(startB, 4)
    end
    nextB = self~codepointIndexB(indexC+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if decode then do
        if startB < 0 then return .Unicode~replacementCharacter~codepoint -- the current byte sequence is invalid
        return self~encoding~decode(self~string, absStartB, absNextB - absStartB)
    end
    return self~string~substr(absStartB, absNextB - absStartB) -- yes, always the current byte sequence, even if invalid


::method character
    -- 2 modes:
    -- if the buffer is passed as argument then append the character to the buffer, and return the buffer
    -- otherwise return the character as a RexxText
    use strict arg indexC
    use strict named arg buffer=.nil
    startB = self~characterIndexB(indexC)
    if .nil == self~characterIndexes, self~characterCount == self~string~length then do
        -- Careful with this optimization! Testing just .nil is not enough since I no longer store the last index+1: even in the case .nil, the last character can be more than one codepoint
        if .nil <> buffer then return buffer~~append(self~string~substr(startB, 4))
                          else return .RexxText~new(self~string~substr(startB, 4), self~encoding)
    end
    nextB = self~characterIndexB(indexC+1)
    absStartB = abs(startB) -- startB can be negative (meaning current byte sequence is invalid)
    absNextB = abs(nextB) -- nextB can be negative (meaning next byte sequence is invalid)
    if .nil <> buffer then return buffer~~append(self~string~substr(absStartB, absNextB - absStartB))
                      else return .RexxText~new(self~string~substr(absStartB, absNextB - absStartB), self~encoding) -- yes, always the current byte sequence, even if invalid
