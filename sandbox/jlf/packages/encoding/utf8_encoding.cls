.encoding~register("UTF8", .UTF8_Encoding)

::requires "encoding/encoding.cls"
::requires "encoding/byte_common.cls"
::requires "encoding/utf8_common.cls"
::requires "encoding/unicode_common.cls"
::requires "encoding/stringIndexer.cls"

-- ::requires "encoding/unicode.cls"    -- .Unicode


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
