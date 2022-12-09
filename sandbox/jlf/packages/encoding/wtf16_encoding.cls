.encoding~register("WTF16", .WTF16BE_Encoding)
.encoding~register("WTF16BE", .WTF16BE_Encoding)
.encoding~register("WTF16LE", .WTF16LE_Encoding)

::requires "encoding/encoding.cls"
::requires "encoding/utf16_common.cls"
::requires "encoding/unicode_common.cls"
::requires "encoding/stringIndexer.cls"
::requires "encoding/byte_common.cls" -- for atBytePosition

-- ::requires "encoding/unicode.cls"    -- .Unicode


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
