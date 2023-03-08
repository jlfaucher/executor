::extension StringIndexer inherit IndexerHelpers
::extension StringIndexer inherit IndexerStringInterface

::requires "encoding/encoding.cls"
::requires "encoding/stringIndexer.cls" -- for internalIndexer

-- ::requires "encoding/unicode.cls"    -- .Unicode
-- ::requires "extension/text.cls"      -- .RexxText


/******************************************************************************/
::class "IndexerHelpers" mixinclass Object public -- private

::method append class
    -- Positional arguments : zero to N text or buffer or string.
    use arg ...
    use strict named arg buffer(1)=.nil
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new
    buffer~encoding = self~asEncodingFor(buffer) -- raise an error if not compatible

    do i=1 to arg()
        text = arg(i)~requestTextOrBufferOrString
        if .nil == text then signal must_have_a_text_or_buffer_or_string_value
        encoding = .Encoding~forConcatenation(buffer, text) -- raise an error if not compatible
        buffer~encoding = encoding
        encoding~concatenate(text, :buffer)
    end
    if returnBuffer then return buffer
    else return .RexxText~new(buffer~string, buffer~encoding)

    must_have_a_text_or_buffer_or_string_value: raise syntax 93.900 array("Method positional argument "i" must have a text or buffer or string value")


::method compareText private
    use strict arg text, pad
    use strict named arg normalization, casefold, lump, stripIgnorable, stripMark
    -- todo


::method endsWithText private
    use strict arg other
    use strict named arg normalization, casefold, lump, stripIgnorable, stripMark
    -- todo
/*
    start = self~length - substr~length + 1
    if start < 1 then return .false
    return self~pos(substr, start) == start
*/


::method lower_upper_title private
    use strict arg action, startC, length
    use strict named arg buffer(1)=.nil

    if \datatype(startC, "w") then signal invalid_position
    if startC <= 0 then signal invalid_position

    if \datatype(length, "w") then signal invalid_length
    if length < 0 then signal invalid_length

    if startC > self~length then return self~string~text
    if length == 0 then return self~string~text

    endC = min(startC + length - 1, self~length)
    startB = abs(self~graphemeIndex(startC))
    endB = abs(self~graphemeIndex(endC+1))

    string = self~string
    encoding = self~encoding
    returnBuffer = .nil <> buffer

    -- Initialize the left not-impacted section
    if .nil == buffer then buffer = .MutableBuffer~new(string~left(startB - 1))
                      else buffer~append(string~left(startB - 1))
    codepointIndexB = startB

    -- Process the impacted section

    error = .array~new -- simulate variable by reference

    -- If the action is to title then check if the begining of the section is a begining of word
    if action == "t" then do
        -- Simple split by words using space as separator. Absolutly not Unicode compliant.
        beginOfWord = .false
        if codepointIndexB == 1 then beginOfWord = .true -- 1st character
        else do
            previousCodepointIndexB = encoding~previousCodepointIndex(string, codepointIndexB, errorInfo: error)
            if previousCodepointIndexB > 0,  previousCodepointIndexB \== codepointIndexB then do
                codepointSizeB = codepointIndexB - previousCodepointIndexB
                -- remember: don't test directly .Unicode~spaceCharacter because this method is not limited to Unicode
                if string~substr(previousCodepointIndexB, codepointSizeB) == encoding~spaceCharacter~string then beginOfWord = .true
            end
        end
    end

    do while codepointIndexB < endB
        nextCodepointIndexB = encoding~nextCodepointIndex(string, codepointIndexB, errorInfo: error)
        if nextCodepointIndexB > 0 then do -- if no error
            if nextCodepointIndexB == codepointIndexB then leave -- should not happen, but...
            codepointSizeB = nextCodepointIndexB - codepointIndexB
            codepoint = encoding~decode(string, codepointIndexB, codepointSizeB)
            if action == "l" then codepoint = encoding~codepointToLower(codepoint)
            else if action == "u" then codepoint = encoding~codepointToUpper(codepoint)
            else if action == "t" then do
                if beginOfWord then codepoint = encoding~codepointToTitle(codepoint)
                               else codepoint = encoding~codepointToLower(codepoint)
                beginOfWord = (string~substr(codepointIndexB, codepointSizeB) == encoding~spaceCharacter~string)
            end
        end
        else do
            codepoint = .Unicode~replacementCharacter~codepoint
        end
        encoding~encode(codepoint, :buffer)
        codepointIndexB = abs(nextCodepointIndexB)
    end

    -- Append the rigth not-impacted section
    buffer~append(string~right(string~length - endB + 1))
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, encoding)

    invalid_length:             raise syntax 93.923 array(length)
    invalid_position:           raise syntax 93.924 array(startC)


::method matchCharText private
    use strict arg nC, chars
    use strict named arg normalization, casefold, lump, stripIgnorable, stripMark

    selfIndexer = self
    call check_position nC, selfIndexer~length

    charsText = chars~request("RexxText") -- not requestTextOrBufferOrString because we really need a RexxText
    if .nil == charsText then signal argument_2_must_have_a_text_or_string_value
    charsNormText = charsText~transform(:normalization, :casefold, :lump, :stripIgnorable, :stripMark)

    graphemeText = selfIndexer~grapheme(nC)
    graphemeNormText = graphemeText~transform(:normalization, :casefold, :lump, :stripIgnorable, :stripMark)
    -- The grapheme may become 2 graphemes... "ß" becomes "ss" when casefolded
    -- Test only the first grapheme, because the second grapheme doesn't exist in the original string
    firstGrapheme = graphemeNormText~grapheme(1)
    return charsNormText~string~pos(firstGrapheme~string) \== 0

    check_position: procedure
        use strict arg position, max
        if \datatype(position, "w") then signal invalid_position
        if position <= 0 then signal invalid_position
        if position > max then signal invalid_position
        return

        invalid_position: raise syntax 93.924 array(position)

    argument_2_must_have_a_text_or_string_value: raise syntax 93.900 /*93.938*/ array("Method positional argument 2 must have a text or string value")


::method matchText private
    use strict arg startC, other, nC, lengthC
    -- the position and length are related to the internal normalized strings
    use strict named arg normalization, casefold, lump, stripIgnorable, stripMark

    selfIndexer = self
    selfText = selfIndexer~string~text
    selfNormText = selfText~transform(:normalization, :casefold, :lump, :stripIgnorable, :stripMark)
    selfNormIndexer = selfNormText~internalIndexer
    call check_position startC, selfNormIndexer~length

    otherText = other~request("RexxText") -- not requestTextOrBufferOrString because we really need a RexxText
    if .nil == otherText then signal argument_2_must_have_a_text_or_string_value
    otherNormText = otherText~transform(:normalization, :casefold, :lump, :stripIgnorable, :stripMark)
    otherNormIndexer = otherNormText~internalIndexer
    call check_position nC, otherNormIndexer~length
    if .nil == lengthC then lengthC = otherNormIndexer~length - nC + 1
    call check_length lengthC, otherNormIndexer~length, nC

    startB = abs(selfNormIndexer~graphemeIndex(startC))
    nB = abs(otherNormIndexer~graphemeIndex(nC))
    mC = nC + lengthC
    mB = abs(otherNormIndexer~graphemeIndex(mC))
    lengthB = mB - nB

    selfNormString = selfNormIndexer~string
    otherNormString = otherNormIndexer~string
    return selfNormString~match(startB, otherNormString, nB, lengthB)

    check_position: procedure
        use strict arg position, max
        if \datatype(position, "w") then signal invalid_position
        if position <= 0 then signal invalid_position
        if position > max then signal invalid_position
        return

        invalid_position: raise syntax 93.924 array(position)

    check_length: procedure
        use strict arg length, max, pos
        if \datatype(length, "w") then signal invalid_length
        if length < 0 then signal invalid_length -- 0 accepted
        if length > max then signal invalid_length
        -- rexxref.pdf: the combination of n and length must be a valid substring within the bounds of other.
        if (pos + length - 1) > max then signal invalid_length
        return

        invalid_length: raise syntax 93.923 array(length)

    argument_2_must_have_a_text_or_string_value: raise syntax 93.900 /*93.938*/ array("Method positional argument 2 must have a text or string value")


::method posText private
    use strict arg needle, startC, lengthC
    use strict named arg casefold, lump, stripIgnorable, stripMark
    -- todo


/******************************************************************************/
::class "IndexerStringInterface" mixinclass Object public -- private

::method append
    use strict arg text -- text or string
    use strict named arg buffer(1)=.nil
    text = text~requestTextOrBufferOrString
    if .nil == text then signal must_have_a_text_or_buffer_or_string_value
    encoding = .Encoding~forConcatenation(self~string, text) -- raise an error if not compatible
    return encoding~append(self~string, text, :buffer)

    must_have_a_text_or_buffer_or_string_value: raise syntax 93.900 array("Method positional argument 1 must have a text or buffer or string value")


::method caselessCompare
    use strict arg text, pad=(self~encoding~spaceCharacter)
    use strict named arg normalization=(.Unicode~NFC), lump=.false, stripIgnorable=.false, stripMark=.false
    return self~compareText(text, pad, :normalization, casefold:.true, :lump, :stripIgnorable, :stripMark)


::method caselessEndsWith
    use strict arg other
    use strict named arg normalization=(.Unicode~NFC), lump=.false, stripIgnorable=.false, stripMark=.false
    return self~endsWithText(other, :normalization, casefold:.true, :lump, :stripIgnorable, :stripMark)


::method caselessMatch
    use strict arg startC, other, nC=1, lengthC=.nil
    use strict named arg normalization=(.Unicode~NFC), lump=.false, stripIgnorable=.false, stripMark=.false
    return self~matchText(startC, other, nC, lengthC, :normalization, casefold:.true, :lump, :stripIgnorable, :stripMark)


::method caselessMatchChar
    use strict arg nC, chars
    use strict named arg normalization=(.Unicode~NFC), lump=.false, stripIgnorable=.false, stripMark=.false
    return self~matchCharText(nC, chars, :normalization, casefold:.true, :lump, :stripIgnorable, :stripMark)


::method caselessPos
    use strict arg needle, startC=1, lengthC=(self~length)
    use strict named arg lump=.false, stripIgnorable=.false, stripMark=.false
    return self~posText(needle, startC, lengthC, casefold:.true, :lump, :stripIgnorable, :stripMark)


::method center
    use strict arg length, pad=(self~encoding~spaceCharacter)
    use strict named arg buffer(1)=.nil

    if \datatype(length, "w") then signal invalid_length
    if length < 0 then signal invalid_length

    pad = pad~request("RexxText") -- not requestTextOrBufferOrString because we really need the pad's length in graphemes
    if .nil == pad then signal argument_3_must_have_a_text_or_string_value
    if pad~length <> 1 then signal incorrect_pad

    width = length
    len = self~length

    if witdh == len then do
        if .nil <> buffer then return buffer~~append(self~string)
                          else return .RexxText~new(self~string, self~encoding)
    end

    if width == 0 then do
        if .nil <> buffer then return buffer -- unchanged because result of center is ""
                          else return self~encoding~emptyString
    end

    if width > len then do
        encoding = .Encoding~forConcatenation(self~string, pad) -- raise an error if not compatible
        leftPad = (width - len) % 2
        rightPad = (width - len) - leftPad
        space = rightPad + leftPad + len
        retval =
        if .nil <> buffer then do
            -- TODO: rework
            -- can't use encoding~concatenate for pad because pad~copies appends directly to the buffer
            -- consequence: will not detect WTF8 special concatenation, if any/
            pad~copies(leftPad, :buffer)
            encoding~concatenate(self~string, :buffer)
            pad~copies(rightPad, :buffer)
            return buffer
        end
        return encoding~concatenate(pad~copies(leftPad), self~string, pad~copies(rightPad))
    end
    else do
        leftPad = (len - width) % 2 -- integer divide
        return self~substr(leftPad + 1, width)
    end

    incorrect_pad:                               raise syntax 93.922 array(pad~descriptionForError)
    invalid_length:                              raise syntax 93.923 array(length)
    argument_3_must_have_a_text_or_string_value: raise syntax 93.900 array("Method positional argument 3 must have a text or string value")


::method compare
    use strict arg text, pad=(self~encoding~spaceCharacter)
    use strict named arg normalization=(.Unicode~NFC), lump=.false, stripIgnorable=.false, stripMark=.false
    return self~compareText(text, pad, :normalization, casefold:.false, :lump, :stripIgnorable, :stripMark)


::method endsWith
    use strict arg other
    use strict named arg normalization=(.Unicode~NFC), lump=.false, stripIgnorable=.false, stripMark=.false
    return self~endsWithText(other, :normalization, casefold:.false, :lump, :stripIgnorable, :stripMark)


::method length -- number of graphemes
    use strict arg -- none
    return self~graphemeCount


::method lower
    use strict arg startC=1, length=(max(0, self~length - startC + 1))
    use strict named arg buffer(1)=.nil
    return self~lower_upper_title("l", startC, length, :buffer)


::method match
    use strict arg startC, other, nC=1, lengthC=.nil
    use strict named arg normalization=(.Unicode~NFC), lump=.false, stripIgnorable=.false, stripMark=.false
    return self~matchText(startC, other, nC, lengthC, :normalization, casefold:.false, :lump, :stripIgnorable, :stripMark)


::method matchChar
    use strict arg nC, chars
    use strict named arg normalization=(.Unicode~NFC), lump=.false, stripIgnorable=.false, stripMark=.false
    return self~matchCharText(nC, chars, casefold:.false, :normalization, :lump, :stripIgnorable, :stripMark)


::method pos
    use strict arg needle, startC=1, lengthC=(self~length)
    use strict named arg lump=.false, stripIgnorable=.false, stripMark=.false
    return self~posText(needle, startC, lengthC, casefold:.false, :lump, :stripIgnorable, :stripMark)


::method reverse
    use strict arg -- none
    use strict named arg buffer(1)=.nil
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new
    do indexG = self~graphemeCount to 1 by -1
        self~grapheme(indexG, :buffer)
    end
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self~encoding)


::method right
    use strict arg length, pad=(self~encoding~spaceCharacter)
    use strict named arg buffer(1)=.nil

    if \datatype(length, "w") then signal invalid_length
    if length < 0 then signal invalid_length

    pad = pad~request("RexxText") -- not requestTextOrBufferOrString because we really need the pad's length in graphemes
    if .nil == pad then signal argument_3_must_have_a_text_or_string_value
    if pad~length <> 1 then signal incorrect_pad

    encoding = .Encoding~forConcatenation(self~string, pad) -- raise an error if not compatible

    lengthPad = max(0, length - self~length)
    length = length - lengthPad

    endC = self~length + 1
    endB = abs(self~graphemeIndex(endC))
    startC = endC - length
    startB = abs(self~graphemeIndex(startC))
    right = self~string~right(endB - startB)
    if lengthPad == 0 then do
        if .nil <> buffer then return buffer~~append(right)
                          else return .RexxText~new(right, self~encoding)
    end
    if .nil <> buffer then do
        -- can't use encoding~concatenate for pad because pad~copies appends directly to the buffer
        -- consequence: will not detect WTF8 special concatenation, if any.
        pad~copies(lengthPad, :buffer)
        encoding~concatenate(right, :buffer)
        return buffer
    end
    return encoding~concatenate(pad~copies(lengthPad), right)

    incorrect_pad:                               raise syntax 93.922 array(pad~descriptionForError)
    invalid_length:                              raise syntax 93.923 array(length)
    argument_3_must_have_a_text_or_string_value: raise syntax 93.900 array("Method positional argument 3 must have a text or string value")


::method substr
    use strict arg startC, length=(max(0, self~length - startC + 1)), pad=(self~encoding~spaceCharacter)
    use strict named arg buffer(1)=.nil

    if \datatype(startC, "w") then signal invalid_position
    if startC <= 0 then signal invalid_position

    if \datatype(length, "w") then signal invalid_length
    if length < 0 then signal invalid_length

    pad = pad~request("RexxText") -- not requestTextOrBufferOrString because we really need the pad's length in graphemes
    if .nil == pad then signal argument_3_must_have_a_text_or_string_value
    if pad~length <> 1 then signal incorrect_pad

    encoding = .Encoding~forConcatenation(self~string, pad) -- raise an error if not compatible

    if startC > self~length then return pad~copies(length, :buffer)
    remainingLength = self~length - startC + 1 -- always >= 0
    lengthPad = max(0, length - remainingLength)
    endC = min(startC + length - 1, self~length)

    startB = abs(self~graphemeIndex(startC))
    endB = abs(self~graphemeIndex(endC+1))
    substr = self~string~substr(startB, endB - startB)
    if lengthPad == 0 then do
        if .nil <> buffer then return buffer~~append(substr)
                          else return .RexxText~new(substr, self~encoding)
    end
    if .nil <> buffer then do
        encoding~concatenate(substr, :buffer)
        -- TODO: rework
        -- can't use encoding~concatenate for pad because pad~copies appends directly to the buffer
        -- consequence: will not detect WTF8 special concatenation, if any.
        pad~copies(lengthPad, :buffer)
        return buffer
    end
    return encoding~concatenate(substr, pad~copies(lengthPad))

    incorrect_pad:                               raise syntax 93.922 array(pad~descriptionForError)
    invalid_length:                              raise syntax 93.923 array(length)
    invalid_position:                            raise syntax 93.924 array(startC)
    argument_3_must_have_a_text_or_string_value: raise syntax 93.900 array("Method positional argument 3 must have a text or string value")


-- not a String method but maybe in the future...
::method title
    use strict arg startC=1, length=(max(0, self~length - startC + 1))
    use strict named arg buffer(1)=.nil
    return self~lower_upper_title("t", startC, length, :buffer)


::method upper
    use strict arg startC=1, length=(max(0, self~length - startC + 1))
    use strict named arg buffer(1)=.nil
    return self~lower_upper_title("u", startC, length, :buffer)
