-- "UNICODE" can't be used to create a RexxText.
-- But can be used in conversion, to get the shortest possible representation
.encoding~register("UNICODE", .Unicode_Encoding)

::requires "encoding/encoding.cls"

-- ::requires "encoding/unicode.cls"    -- .Unicode

/*
Depends on
.UNICODE16_ENCODING
.UNICODE32_ENCODING
.UNICODE8_ENCODING
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
::class "Unicode_Encoding" mixinclass Object public -- private

::method analyze class
    raise syntax 23.900 array ("'UNICODE' can't be used to create a RexxText. Use 'UNICODE8' or 'UNICODE16' or 'UNICODE32'")


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

-- Optimization: the conversion to Unicode of a Unicode_Encoding instance is itself.
::method Unicode
    use strict arg -- none
    use strict named arg strict = .false, buffer(1)=.nil
    if .nil <> buffer then return buffer~~append(self~string)
                      else return self~string~text
