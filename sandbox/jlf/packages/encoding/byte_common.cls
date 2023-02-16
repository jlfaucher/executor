-- ::requires "encoding/unicode.cls"    -- .Unicode
-- ::requires "extension/text.cls"      -- .RexxText

/******************************************************************************/
::class "Byte_CommonServices" mixinclass Object public -- private
-- Services for byte-oriented strings (byte, utf-8, wtf-8)

::method unescape
    -- The escape characters are used in literal strings, they should be managed
    -- at parse-time. Here, this method is used at run-time.
    -- This method could work for utf-16, wtf-16, utf-32 if it was rewritten
    -- to use RexxText API instead of String API. But would be way slower...
    -- Would it make sense ? Nobody is editing literal strings encoded in 16-bit
    -- or 32-bit.
    use strict named arg buffer(1)=.nil
    string = self~string
    pos = string~pos("\")
    if pos == 0 then do
        -- optim: don't create intermediate buffer if nothing to unescape
        if .nil == buffer then return self~string~text
        return buffer~~append(string)
    end
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new(, string~length)
    from = 1
    do until pos == 0
        buffer~append(string~substr(from, pos - from))
        pos += 1
        character = string~subchar(pos)
        pos += 1
        select
            when character == "\" then buffer~append("\")   -- escaped \
            when character == "a" then buffer~append("07"x) -- audible bell (BEL)
            when character == "b" then buffer~append("08"x) -- backspace (BS)
            when character == "f" then buffer~append("0C"x) -- form feed (FF)
            when character == "n" then buffer~append("0A"x) -- linefeed (LF)
            when character == "r" then buffer~append("0D"x) -- carriage return (CR)
            when character == "t" then buffer~append("09"x) -- horizontal tab (HT)
            when character == "v" then buffer~append("0B"x) -- vertical tab (VT)

            when character == "u" | character == "U" then do
                if \self~isUnicode then signal unicode_character_not_supported

                -- \u{Unicode name}    Character name in the Unicode database
                -- \u{X..X}            Unicode character denoted by 1-8 hex digits
                if string~subchar(pos) == "{" then do
                    pos += 1 -- skip {
                    first = pos
                    pos = string~pos("}", pos)
                    if pos == 0 then signal expecting_name_or_sequence_of_hexadecimal_digits
                    length = pos - first
                    if length == 0 then signal expecting_name_or_sequence_of_hexadecimal_digits
                    pos += 1 -- skip }
                    idntfr = string~substr(first, length)
                    startWithDigit = idntfr~left(1)~datatype("9")
                    character = .Unicode~character(idntfr, hexadecimal: startWithDigit)
                    character~text(self~encoding, :buffer)
                end

                else if character == "u" then do
                    -- \uXXXX
                    length = min(4, string~length - pos + 1)
                    codepoint = string~substr(pos, length)
                    if codepoint~length < 4 then signal expecting_4_hexadecimal_digits
                    if \codepoint~datatype("X") then signal expecting_4_hexadecimal_digits
                    character = .Unicode~character(codepoint, hexadecimal: .true)
                    character~text(self~encoding, :buffer)
                    pos += 4
                end

                else if character == "U" then do
                    -- \uXXXXXXXX
                    length = min(8, string~length - pos + 1)
                    codepoint = string~substr(pos, length)
                    if codepoint~length < 8 then signal expecting_8_hexadecimal_digits
                    if \codepoint~datatype("X") then signal expecting_8_hexadecimal_digits
                    character = .Unicode~character(codepoint, hexadecimal: .true)
                    character~text(self~encoding, :buffer)
                    pos += 8
                end

            end

            when character == "x" then do
                -- \x{X..X} sequence of 1..n hexadecimal digits
                if string~subchar(pos) \== "{" then signal expecting_sequence_of_hexadecimal_digits
                pos += 1 -- skip {
                first = pos
                pos = string~pos("}", pos)
                if pos == 0 then signal expecting_sequence_of_hexadecimal_digits
                length = pos - first
                if length == 0 then signal expecting_sequence_of_hexadecimal_digits
                pos += 1 -- skip }
                hexadecimalDigits = string~substr(first, length)
                characters = hexadecimalDigits~x2c -- 1..n bytes
                buffer~append(characters)
            end

            otherwise signal unsupported_escape_character
        end
        from = pos
        pos = string~pos("\", from)
    end
    buffer~append(string~substr(from))

    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self~encoding)

    unicode_character_not_supported:                  raise syntax 23.900 array(self~encoding~name "encoding: \"character" not supported")
    expecting_name_or_sequence_of_hexadecimal_digits: raise syntax 23.900 array(self~encoding~name "encoding: expecting a character name {name} or 1..8 hexadecimal digits {X..X} after \u")
    expecting_4_hexadecimal_digits:                   raise syntax 23.900 array(self~encoding~name "encoding: expecting 4 hexadecimal digits after \u, got '"codepoint"'")
    expecting_8_hexadecimal_digits:                   raise syntax 23.900 array(self~encoding~name "encoding: expecting 8 hexadecimal digits after \U, got '"codepoint"'")
    expecting_sequence_of_hexadecimal_digits:         raise syntax 23.900 array(self~encoding~name "encoding: expecting 1..n hexadecimal digits {X..X} after \x")
    unsupported_escape_character:                     raise syntax 23.900 array(self~encoding~name "encoding: escape character '"character"' not supported")


/******************************************************************************/
-- Helper to create a table of transcoded characters, from codepoint 0 to size-1.
-- By default, a transcoded character is equal to itself.
-- The specific transcoding table lets define specific values for some characters.
::routine createCharacterTranscodingTable public -- private
    use strict arg size, specificTranscoding
    tableTranscodingToUnicode = .array~new(size)
    do i = 0 to size-1
        tableTranscodingToUnicode[i+1] = i -- bof bof... 1-based
    end
    nextSpecificIndex = 0
    do i=1 to specificTranscoding~items
        item = specificTranscoding[i]
        if item~right(1) == ":" then do -- Ends with colon, this is an index. For example: "80:"
            nextSpecificIndex = item~left(item~length - 1)~x2d
        end
        else do
            if item == "" then codepoint = "" -- no transcoding
            else if item~left(1) == "-" then codepoint = -(item~substr(2)~x2d) -- unused character with fallback transcoding. For example: "-81" --> -129
            else codepoint = item~x2d
            tableTranscodingToUnicode[nextSpecificIndex+1] = codepoint -- bof bof... 1-based array
            nextSpecificIndex += 1
        end
    end
    return tableTranscodingToUnicode


/******************************************************************************/
-- Helper to build error messages.
-- Sometimes, the byte index is not available.
::routine atBytePosition public -- private
    use strict arg byteIndex
    if .nil == byteIndex then return ""
    return " at byte-position" byteIndex -- Keep the space at the begining!
