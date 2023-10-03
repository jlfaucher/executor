-- ::requires "encoding/unicode.cls"    -- .Unicode
-- ::requires "extension/text.cls"      -- .RexxText

/******************************************************************************/
::class "Byte_CommonServices" mixinclass Object public -- private
-- Services for byte-oriented encodings (byte, utf-8, wtf-8): unescape
-- Services for all encodings: atBytePosition

::method unescape
    -- The escape characters are used in literal strings, they should be managed
    -- at parse-time. Here, this method is used at run-time.
    -- This method could work for utf-16, wtf-16, utf-32 if it was rewritten
    -- to use RexxText API instead of String API. But would be way slower...
    -- Would it make sense ? Nobody is editing literal strings encoded in 16-bit
    -- or 32-bit.
    use strict named arg buffer=.nil
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
                    character~transcodeTo(self~encoding, :buffer)
                end

                else if character == "u" then do
                    -- \uXXXX
                    length = min(4, string~length - pos + 1)
                    hexadecimalDigits = string~substr(pos, length)
                    if hexadecimalDigits~length < 4 then signal expecting_4_hexadecimal_digits
                    if \hexadecimalDigits~datatype("X") then signal expecting_4_hexadecimal_digits
                    character = .Unicode~character(hexadecimalDigits, hexadecimal: .true)
                    character~transcodeTo(self~encoding, :buffer)
                    pos += 4
                end

                else if character == "U" then do
                    -- \uXXXXXXXX
                    length = min(8, string~length - pos + 1)
                    hexadecimalDigits = string~substr(pos, length)
                    if hexadecimalDigits~length < 8 then signal expecting_8_hexadecimal_digits
                    if \hexadecimalDigits~datatype("X") then signal expecting_8_hexadecimal_digits
                    character = .Unicode~character(hexadecimalDigits, hexadecimal: .true)
                    character~transcodeTo(self~encoding, :buffer)
                    pos += 8
                end

            end

            when character == "x" then do
                -- \x{X..X} sequence of 1..n hexadecimal digits
                if string~subchar(pos) == "{" then do
                    pos += 1 -- skip {
                    first = pos
                    pos = string~pos("}", pos)
                    if pos == 0 then signal expecting_sequence_of_hexadecimal_digits
                    length = pos - first
                    if length == 0 then signal expecting_sequence_of_hexadecimal_digits
                    pos += 1 -- skip }
                    hexadecimalDigits = string~substr(first, length)
                    bytes = hexadecimalDigits~x2c -- 1..n bytes
                    buffer~append(bytes)
                end

                else if character == "x" then do
                    -- \xXX
                    length = min(2, string~length - pos + 1)
                    hexadecimalDigits = string~substr(pos, length)
                    if hexadecimalDigits~length < 2 then signal expecting_2_hexadecimal_digits
                    if \hexadecimalDigits~datatype("X") then signal expecting_2_hexadecimal_digits
                    bytes = hexadecimalDigits~x2c -- 2 bytes
                    buffer~append(bytes)
                    pos += 2
                end

                else if character == "X" then do
                    -- \xXXXX
                    length = min(4, string~length - pos + 1)
                    hexadecimalDigits = string~substr(pos, length)
                    if hexadecimalDigits~length < 4 then signal expecting_4_hexadecimal_digits
                    if \hexadecimalDigits~datatype("X") then signal expecting_4_hexadecimal_digits
                    bytes = hexadecimalDigits~x2c -- 4 bytes
                    buffer~append(bytes)
                    pos += 4
                end

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
    expecting_name_or_sequence_of_hexadecimal_digits: raise syntax 23.900 array(self~encoding~name "encoding: expecting a character name {name} or 1..8 hexadecimal digits {X..X} after \"character)
    expecting_2_hexadecimal_digits:                   raise syntax 23.900 array(self~encoding~name "encoding: expecting 2 hexadecimal digits after \"character", got '"hexadecimalDigits"'")
    expecting_4_hexadecimal_digits:                   raise syntax 23.900 array(self~encoding~name "encoding: expecting 4 hexadecimal digits after \"character", got '"hexadecimalDigits"'")
    expecting_8_hexadecimal_digits:                   raise syntax 23.900 array(self~encoding~name "encoding: expecting 8 hexadecimal digits after \"character", got '"hexadecimalDigits"'")
    expecting_sequence_of_hexadecimal_digits:         raise syntax 23.900 array(self~encoding~name "encoding: expecting 1..n hexadecimal digits {X..X} after \"character)
    unsupported_escape_character:                     raise syntax 23.900 array(self~encoding~name "encoding: escape character '"character"' not supported")


/******************************************************************************/
-- Helper to build error messages.
-- Sometimes, the byte index is not available.
::routine atBytePosition public -- private
    use strict arg byteIndex
    if .nil == byteIndex then return ""
    return " at byte-position" byteIndex -- Keep the space at the begining!
