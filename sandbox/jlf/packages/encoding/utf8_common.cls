::requires "extension/string.cls" -- for ppHexNumber
::requires "encoding/cachedStrings"

-- ::requires "encoding/unicode.cls"    -- .Unicode
-- ::requires "extension/text.cls"      -- .RexxText

/*
Depends on
.UNICODE8_ENCODING
.UTF8_ENCODING
.WTF8_ENCODING
*/


/******************************************************************************/
::class "XTF8_CommonServices" mixinclass Object public -- private
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
