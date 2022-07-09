/*
Keep it compatible with official ooRexx
*/

-------------------------------------------------------------------------------
::class "StringChunk" public
-------------------------------------------------------------------------------

::attribute container           -- the string container from which the string value has been extracted
::attribute containerEnd        -- index of last character in container
::attribute containerStart      -- index of first character in container
::attribute quotedFlags         -- string of booleans : "1" when the corresponding character in string is part of a chunk surrounded by quotes
::attribute string              -- the string value of the stringChunk (the quotes are removed)


::method init
    expose container containerEnd containerStart quotedFlags string
    use strict arg string, quotedFlags="", container="", containerStart=0, containerEnd=0


::method description
    -- Helper to get the string and its quoted flags.
    -- An optional width can be passed, to align the strings of quoted flags when displaying an array of StringChunk
    use strict arg stringWidth=(self~string~length), index="", indexWidth=(index~length), descriptionKind="all", leftQuote = "|", rightQuote=(leftQuote)
    index = index~left(indexWidth)
    string = leftQuote || self~string || rightQuote
    string = string~left(stringWidth+2)
    start = self~containerStart~right(self~container~length~length,"0")
    end = self~containerEnd~right(self~container~length~length, "0")
    containerSection = self~container~substr(self~containerStart, self~containerEnd - self~containerStart + 1)
    containerSection = leftQuote || containerSection || rightQuote
    containerSection = containerSection~left(stringWidth+2)
    quotedFlags = leftQuote || self~quotedFlags || rightQuote
    quotedFlags = quotedFlags~left(stringWidth+2)
    if descriptionKind == 1 then do -- line 1 for sayDescription
        if index <> "" then return index string start end containerSection
                       else return       string start end containerSection
    end
    else if descriptionKind == 2 then do -- line 2 for sayDescription
        if index <> "" then return index quotedFlags
                       else return       quotedFlags
    end
    else do -- all in one line
        if index <> "" then return index string start end containerSection quotedFlags
                       else return       string start end containerSection quotedFlags
    end

::method sayDescription
    -- Helper to display the string and its quoted flags.
    -- An optional width can be passed, to align the columns when displaying an array of StringChunk
    -- An optional index and its width can be passed
    use strict arg stringWidth=(self~string~length), index="", indexWidth=(index~length)
    say self~description(stringWidth, index, indexWidth, 1)
    say self~description(stringWidth, index, indexWidth, 2)


::method left
    -- Extract a left substring while keeping the contextual informations
    copy = self~copy
    forward to (self~string) continue
    copy~string = result
    forward to (self~quotedFlags) continue
    copy~quotedFlags = result
    return copy


::method right
    -- Extract a right substring while keeping the contextual informations
    copy = self~copy
    forward to (self~string) continue
    copy~string = result
    forward to (self~quotedFlags) continue
    copy~quotedFlags = result
    return copy


::method substr
    -- Extract a substring while keeping the contextual informations
    copy = self~copy
    forward to (self~string) continue
    copy~string = result
    forward to (self~quotedFlags) continue
    copy~quotedFlags = result
    return copy


::method compareTo
    -- Added because I added caselessCompareto
    use strict arg other
    return self~string~compareto(other~string)


::method caselessCompareto
    -- Added because needed from ooRexxshell when displaying a set of StringChunk
    use strict arg other
    return self~string~caselessCompareto(other~string)


::routine stringChunks public
    /*
    Converts a string to an array of String or to an array of stringChunk.
    The type of result is indicated by the argument withInfos:
    - If withInfos == .false (default) then the result is an array of String.
    - If withInfos == .true then the result is an array of StringChunk.

    A StringChunk is a substring which references the start and end character in its container.
    It's associated to a string of booleans (quotedFlags) which indicate for each character if
    it was inside a quoted section or if it was escaped.

    A quote is either " or '.

    An unquoted section is splitted in StringChunks delimited by whitespaces (anything <= 32) and break tokens.

    A quoted section is not splitted:
    - Whitespaces are kept,
    - single occurences of quotes are removed,
    - double occurrence of quotes are replaced by a single embedded quote,
    - break tokens and escape characters are ignored.

    An escape character is any character passed in the argument escapeCharacters.
    An escape character sets the quote flag of the next character to 1.
    Escape characters are removed, even if they are not followed by another character (truncated string).
    Example with 'a' declared escape character:
    - "a" --> ""
    - "aa" --> "a"
    - "aaa" --> "a"
    - "aaaa" --> "aa"

    If a quote is declared escape character, there is no impact: a quote is already an escape mechanism.

    If a space is declared escape character, there is an impact when splitLevel=0:
    the quote flag of a character following an unquoted space is set to 1, the unquoted spaces are removed
    Example:
        'one two "three four" five six' --> onetwothree fourfivesix
                                            00010011111111111000100

    Break tokens are passed in the argument breakTokens.
    A break token cannot contains spaces.
    The break tokens can be case sensitive (default) or case insensitive.
    Each break token can be prefixed by:
    - cs:  case sensitive
    - ci:  case insensitive
    - cl:  caseless (synonym of case insensitive)
    Any other prefix is not an error. It's just not a case prefix.

    If a quote is declared break token then it's no longer recognized as a quote.
    If an escape character is declared break token then it's no longer recognized as an escape character.

    The split process is controlled by the argument splitLevel:
    - If splitLevel == 0 then the string is not splitted but the quotes and escape characters are managed, quotedFlags is set.
        'xx aa"b b"cc"d d"ee yy' is 1 StringChunk.
    - If splitLevel == 1 (default) then adjacent quoted/unquoted sections are kept glued.
        'xx aa"b b"cc"d d"ee yy' is 3 StringChunk: xx "aab bccd dee" yy
    - If splitLevel == 2 then adjacent quoted/unquoted sections are separated.
        'xx aa"b b"cc"d d"ee yy' is splitted in 7 StringChunk: xx aa "b b" cc "d d" ee yy

    Illustration with splitLevel=1:
    11111111111111111111111111 222222222222222 333333333333333333333
    "hello "John" how are you" good" bye "John "my name is ""BOND"""
    0000000001111111111222222222233333333334444444444555555555566666
    1234567890123456789012345678901234567890123456789012345678901234
    arg1 = |hello John how are you|      containerStart = 01      containerEnd = 26      quotedFlags = 1111110000111111111111
    arg2 = |good bye John|               containerStart = 28      containerEnd = 42      quotedFlags = 0000111110000
    arg3 = |my name is "BOND"|           containerStart = 44      containerEnd = 64      quotedFlags = 11111111111111111

    To test the example above
        string = '"hello "John" how are you" good" bye "John "my name is ""BOND"""'
        stringChunks(string)==

    Output:
        an Array (shape [3], 3 items)
         1 : 'hello John how are you'
         2 : 'good bye Jonh'
         3 : 'my name is "BOND"'
    */

    use strict arg string, withInfos=.false, breakTokens="", splitLevel=1, escapeCharacters=""
    breakTokens = makeSortedArrayOfPrefixedBreakTokens(breakTokens)
    args = .Array~new
    i = 1

    loop label stringChunks
        if splitLevel >= 1 then do
            -- Skip whitespaces
            loop
                if i > string~length then return args
                if string~subchar(i) > " " then leave
                i += 1
            end
        end

        current = .MutableBuffer~new
        quotedFlags = .MutableBuffer~new
        firstCharPosition = i
        breakTokenLength = 0 -- will receive the length of the break token, if a break token starts at current position i.
        loop label current_stringChunk

            if splitLevel >= 1 then do
                if breakTokenLength == 0 then breakTokenLength = breakTokenLength(i) -- check if we have a break token at current position i
                if breakTokenLength <> 0 then do
                    if current~length <> 0 then args~append(result())
                    -- Now creates a StringChunk for the break token
                    current = string~substr(i, breakTokenLength)
                    quotedFlags = 0~copies(breakTokenLength) -- The break tokens are detected only in unquoted chunks
                    firstCharPosition = i
                    i += breakTokenLength
                    args~append(result())
                    leave current_stringChunk
                end
                if string~subchar(i) <= " " then do
                    args~append(result())
                    leave current_stringChunk
                end
            end

            c = string~subchar(i)
            quote = ""
            if c == '"' | c == "'" then quote = c
            if quote <> "" then do
                if splitLevel == 2 then do
                    -- Adjacent quoted/unquoted sections are separated
                    if current~length <> 0 then do
                        args~append(result())
                        leave current_stringChunk
                    end
                end
                -- Chunk surrounded by quotes: whitespaces are kept, double occurrence of quotes are replaced by a single embedded quote, break tokens and escape characters are ignored
                loop label quoted_chunk
                    i += 1
                    if i > string~length then return args~~append(result())
                    select
                        when string~subchar(i) == quote & string~subchar(i+1) == quote then do
                            current~append(quote)
                            quotedFlags~append("1")
                            i += 1
                        end
                        when string~subchar(i) == quote then do
                            i += 1
                            if splitLevel == 2 then do
                                -- Adjacent quoted/unquoted sections are separated
                                if current~length <> 0 then args~append(result())
                                leave current_stringChunk
                            end
                            leave quoted_chunk
                        end
                        otherwise do
                            current~append(string~subchar(i))
                            quotedFlags~append("1")
                        end
                    end
                end quoted_chunk
            end

            if splitLevel >= 1 then do
                if breakTokenLength == 0 then breakTokenLength = breakTokenLength(i) -- check if we have a break token at current position i
                if breakTokenLength <> 0 then do
                    if current~length <> 0 then args~append(result())
                    -- Now creates a StringChunk for the break token
                    current = string~substr(i, breakTokenLength)
                    quotedFlags = 0~copies(breakTokenLength) -- The break tokens are detected only in unquoted chunks
                    firstCharPosition = i
                    i += breakTokenLength
                    args~append(result())
                    leave current_stringChunk
                end
                if string~subchar(i) <= " " then do
                    args~append(result())
                    leave current_stringChunk
                end
            end

            -- Chunk not surrounded by quotes: ends when a whitespace or quote or break token is reached
            loop label unquoted_chunk
                if i > string~length then return args~~append(result())
                c = string~subchar(i)
                if splitLevel >= 1 then do
                    breakTokenLength = breakTokenLength(i)
                    if c <= " " | c == '"' | c == "'" | breakTokenLength <> 0 then leave unquoted_chunk
                end
                else do
                    if c == '"' | c == "'" then leave unquoted_chunk
                end
                quotedFlag = "0"
                if escapeCharacters~pos(c) <> 0 then do
                    i += 1
                    if i > string~length then return args~~append(result()) -- the escape character is not followed by a character, ignore it
                    c = string~subchar(i)
                    if c == '"' | c == "'" then leave unquoted_chunk -- must not "eat" the quote
                    quotedFlag = "1" -- escaped character
                end
                current~append(c)
                quotedFlags~append(quotedFlag)
                i += 1
            end unquoted_chunk

        end current_stringChunk

    end stringChunks
    return args

    breakTokenLength: procedure expose string breakTokens
        use strict arg i
        -- Assumption : the collection breakTokens is an ordered collection sorted from longest to shortest token
        do breakToken over breakTokens
            parse var breakToken prefix ":" breakToken
            compare = "caselessEquals"
            if prefix == "cs" then compare = "equals"
            if string~substr(i, breakToken~length)~send(compare, breakToken) then return breakToken~length
        end
        return 0

    result:
        if withInfos then return .StringChunk~new(/*string*/         current~string,,
                                                  /*quotedFlags*/    quotedFlags~string,,
                                                  /*container*/      string,,
                                                  /*containerStart*/ firstCharPosition,,
                                                  /*containerEnd*/   i-1)
        else return current~string


::routine makeSortedArrayOfPrefixedBreakTokens
    /*
    The break tokens can be case sensitive (default) or case insensitive.
    Each break token can be prefixed by:
    - cs:  case sensitive
    - ci:  case insensitive
    - cl:  caseless (synonym of case insensitive)
    Any other prefix is not an error. It's just not a case prefix.
    Must ensure that all the break tokens have a case prefix, because they will be sorted by length.
    */
    use strict arg breakTokens
    breakTokens = breakTokens~subwords
    do i=1 to breakTokens~items
        breakToken = breakTokens[i]
        prefixed = "cs: ci: cl:"~caselessWordPos(breakToken~left(3)) <> 0
        if \prefixed | breakToken~length == 3 then breakToken = "cs:" || breakToken
        breakTokens[i] = breakToken
    end
    return breakTokens~sortWith(.LengthComparator~new("d")) -- sort descending, from longer to shorter


-------------------------------------------------------------------------------
::class "LengthComparator" mixinclass object private
-------------------------------------------------------------------------------

::method init
    expose direction
    use strict arg criteria="ascending"
    select
        when "ascending"~caselessAbbrev(criteria, 1) then direction = 1
        when "descending"~caselessAbbrev(criteria, 1) then direction = -1
        otherwise raise syntax 93.900 array("LengthComparator: invalid criteria" criteria)
    end


::method compare
    expose direction
    use strict arg left, right
    return direction * sign(left~length - right~length)
