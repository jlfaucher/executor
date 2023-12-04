::extension StringIndexer inherit IndexerHelpers
::extension StringIndexer inherit IndexerStringInterface

::requires "encoding/encoding.cls"
--::requires "encoding/stringIndexer.cls"

-- ::requires "encoding/unicode.cls"    -- .Unicode
-- ::requires "extension/text.cls"      -- .RexxText

--::options trace r

/******************************************************************************/
::class "IndexerHelpers" mixinclass Object public -- private

-- Lets use directly a StringIndexer where a Text or Buffer or String is requested
::method requestTextOrBufferOrString
    use strict arg -- none
    return self~string~text


-- If you modify this method then see if the method EncodedMutableBuffer~appendEncoded must be modified as well
::method append class
    -- Positional arguments : zero to N text or buffer or string.
    use arg ...
    use strict named arg buffer=.nil
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
    use strict named arg normalization, casefold, lump, stripIgnorable, stripMark, stripCC, stripNA, debug=.false

    selfText = self~string~text

    textText = text~request("RexxText") -- not requestTextOrBufferOrString because we really need a RexxText
    if .nil == textText then signal argument_1_must_have_a_text_or_string_value

    padText = pad~request("RexxText") -- not requestTextOrBufferOrString because we really need the pad's length in characters
    if .nil == padText then signal incorrect_pad
    if padText~length <> 1 then signal incorrect_padText

    .Encoding~comparisonMode(selfText, textText) -- raise an error if not compatible
    .Encoding~forConcatenation(selfText, padText) -- raise an error if not compatible
    .Encoding~forConcatenation(textText, padText) -- raise an error if not compatible

    -- max length before transformation
    maxLength = max(selfText~length, textText~length)

    -- The shorter string is padded on the right with pad if necessary.
    if selfText~length < maxLength then selfText = selfText~left(maxlength, padText)
    if textText~length < maxLength then textText = textText~left(maxlength, padText)

    selfTextTransformer = selfText~transformer~transform(:normalization, :casefold, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA)
    selfTextTransformedString = selfTextTransformer~iSubtext~string
    textTextTransformer = textText~transformer~transform(:normalization, :casefold, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA)
    textTextTransformedString = textTextTransformer~iSubtext~string
if debug then do
    say "selfTextTransformer~iSubtext~string =" selfTextTransformer~iSubtext~string
    say "selfTextTransformer~iSubtext~c2g =" selfTextTransformer~iSubtext~c2g
    say "selfTextTransformedString~length =" selfTextTransformedString~length
    say "textTextTransformer~iSubtext~string =" textTextTransformer~iSubtext~string
    say "textTextTransformer~iSubtext~c2g =" textTextTransformer~iSubtext~c2g
    say "textTextTransformedString~length =" textTextTransformedString~length
end
    -- despite the padding made at character level, the binary strings may not have the same lengths, use the arbitrary pad "0"x
    posB1 = selfTextTransformedString~compare(textTextTransformedString, "0"x)
if debug then do
    say "posB1 =" posB1
end
    if posB1 == 0 then return 0 -- both strings are equal
    posC1 = selfTextTransformer~ib2xc(posB1, aligned:\debug)
if debug then do
    say "posC1 =" posC1
end
    -- yes, must get also this position posC2, to check if it's aligned.
    -- For example: "sss"~text~caselessCompare("", "ß")
    --      "sss" --pad--> "sss" --casefold--> "sss"
    --      ""    --pad--> "ßßß" --casefold--> "ssssss"
    -- Must return 3, not 4 because the 3rd "s" matches only half of casefolded "ß"
    -- todo: remove this line   posB2 = textTextTransformedString~compare(selfTextTransformedString, "0"x)
    posB2 = posB1 -- just to make clear that I will check if posB1 is aligned with a character in the 2nd string
    posC2 = textTextTransformer~ib2xc(posB2, aligned:\debug)
if debug then do
    say "posB2 =" posB2
    say "posC2 =" posC2
end
if debug then do
    -- In debug mode, a rational is returned: posC.posB
    -- Keep only posC
    posC1 = trunc(posC1)
    posC2 = trunc(posC2)
end
    /*
    if .nil == posC1 | .nil == posC2 then posC1 = abs(posC1) - 1 -- When not aligned.
    else
    */
    if posC1 < 0 & posC2 < 0 then return abs(posC1) -- When not aligned on both sides.
    if posC1 < 0 | posC2 < 0 then posC1 = abs(posC1) - 1 -- When not aligned on one side.
    return posC1

    argument_1_must_have_a_text_or_string_value: raise syntax 93.900 /*93.938*/ array("Method positional argument 1 must have a text or string value")
    incorrect_pad:                               raise syntax 93.922 array(pad)
    incorrect_padText:                           raise syntax 93.922 array(padText~descriptionForError)


::method compareToText private
    use strict arg text, n=1, length=.nil
    use strict named arg normalization, casefold, lump, stripIgnorable, stripMark, stripCC, stripNA
    text = text~request("RexxText") -- not requestTextOrBufferOrString because we really need a RexxText
    if .nil == length then do
        selfLength = self~length
        textLength = text~length
    end
    else do
        if \datatype(length, "w") then signal invalid_length
        if length < 0 then signal invalid_length -- 0 accepted
        selfLength = min(length, self~length)
        textLength = min(length, text~length)
    end

    .Encoding~comparisonMode(self, text) -- raise an error if not compatible

    selfNormalized = self~substr(n, selfLength)~transform(:normalization, :casefold, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA)
    textNormalized = text~substr(n, textLength)~transform(:normalization, :casefold, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA)

    /*
    REMEMBER!
    This method is called by caselessCompareTo, compareTo. These 2 methods are
    called by caselessEquals, equals. These 4 methods accept an optional named
    argument 'strict'.

    About strict versus non-strict comparison in ooRexx doc:
    For all other comparison operators, if both terms involved are numeric, a
    numeric comparison is effected. Otherwise, both terms are treated as
    character strings, leading and trailing whitespace characters are ignored,
    and the shorter string is padded with blanks on the right.

    So, if strict=.false, I should follow the definition above.
    Currently this is not the case (todo).
    */
    return selfNormalized~string~CompareTo(textNormalized~string)

    invalid_length: raise syntax 93.923 array(length)


::method endsWithText private
    use strict arg other
    use strict named arg normalization, casefold, lump, stripIgnorable, stripMark, stripCC, stripNA

    otherText = other~request("RexxText") -- not requestTextOrBufferOrString because we really need a RexxText
    if .nil == otherText then signal argument_1_must_have_a_text_or_string_value

    .Encoding~comparisonMode(self, otherText) -- raise an error if not compatible

    selfTextTransformer = self~transformer~transform(:normalization, :casefold, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA)
    selfTextTransformed = selfTextTransformer~iSubtext
    otherTextTransformed = otherText~transform(:normalization, :casefold, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA)
    if otherTextTransformed~string~length == 0 then return .false
    startB = selfTextTransformed~string~length - otherTextTransformed~string~length + 1
    if startB <= 0 then return .false -- can't match, other is longer than self
    startC = selfTextTransformer~ib2xc(startB)
    -- if .nil == startC then return .false -- startB is not aligned with a character
    if startC < 0 then return .false -- startB is not aligned with a character (here aligned is always true so startC is never an array)
    -- no need to test the alignment at the end, since all the bytes must be matched
    return selfTextTransformed~string~match(startB, otherTextTransformed~string)

    argument_1_must_have_a_text_or_string_value: raise syntax 93.900 /*93.938*/ array("Method positional argument 1 must have a text or string value")


::method lower_upper_title private
    use strict arg action, startC, length
    use strict named arg buffer=.nil

    if \datatype(startC, "w") then signal invalid_position
    if startC <= 0 then signal invalid_position

    if \datatype(length, "w") then signal invalid_length
    if length < 0 then signal invalid_length

    if startC > self~length then return self~string~text
    if length == 0 then return self~string~text

    endC = min(startC + length - 1, self~length)
    startB = abs(self~characterIndexB(startC))
    endB = abs(self~characterIndexB(endC+1))

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
        -- Simple split by words using space as separator. Absolutly not Unicode compliant (todo).
        beginOfWord = .false
        if codepointIndexB == 1 then beginOfWord = .true -- 1st character
        else do
            previousCodepointIndexB = encoding~previousCodepointIndexB(string, codepointIndexB, errorInfo: error)
            if previousCodepointIndexB > 0,  previousCodepointIndexB \== codepointIndexB then do
                codepointSizeB = codepointIndexB - previousCodepointIndexB
                -- remember: don't test directly .Unicode~spaceCharacter because this method is not limited to Unicode
                if string~substr(previousCodepointIndexB, codepointSizeB) == encoding~spaceCharacter~string then beginOfWord = .true
            end
        end
    end

    -- utf8proc has no function working on a whole string.
    -- It provides only functions taking a codepoint.
    -- It doesn't implement the special casing rules.
    do while codepointIndexB < endB
        nextCodepointIndexB = encoding~nextCodepointIndexB(string, codepointIndexB, errorInfo: error)
        if nextCodepointIndexB > 0 then do -- if no error
            if nextCodepointIndexB == codepointIndexB then leave -- should not happen, but...
            codepointSizeB = nextCodepointIndexB - codepointIndexB
            codepoint = encoding~decode(string, codepointIndexB, codepointSizeB)
            if action == "l" then codepoints = encoding~codepointToLowerFull(codepoint)
            else if action == "u" then codepoints = encoding~codepointToUpperFull(codepoint)
            else if action == "t" then do
                if beginOfWord then codepoints = encoding~codepointToTitleFull(codepoint)
                               else codepoints = encoding~codepointToLowerFull(codepoint)
                beginOfWord = (string~substr(codepointIndexB, codepointSizeB) == encoding~spaceCharacter~string)
            end
        end
        else do
            codepoints = .Unicode~replacementCharacter~codepoint
        end
        do while codepoints <> ""
            parse var codepoints codepoint codepoints
            encoding~encode(codepoint, :buffer)
        end
        codepointIndexB = abs(nextCodepointIndexB)
    end

    -- Append the rigth not-impacted section
    buffer~append(string~right(string~length - endB + 1))
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, encoding)

    invalid_length:     raise syntax 93.923 array(length)
    invalid_position:   raise syntax 93.924 array(startC)


::method matchCharText private
    use strict arg nC, chars
    use strict named arg normalization, casefold, lump, stripIgnorable, stripMark, stripCC, stripNA

    call check_position nC, self~length

    charsText = chars~request("RexxText") -- not requestTextOrBufferOrString because we really need a RexxText
    if .nil == charsText then signal argument_2_must_have_a_text_or_string_value

    .Encoding~comparisonMode(self, charsText) -- raise an error if not compatible

    characterText = self~character(nC)
    characterTextNormalized = characterText~transform(:normalization, :casefold, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA)
    -- The character may become 0..n characters... "ß" becomes "ss" when casefolded, an ignorable character is removed if stripIgnorable:.true

    charsTextSupplier = charsText~characters
    do while charsTextSupplier~available
        charText = charsTextSupplier~item
        charTextNormalized = charText~transform(:normalization, :casefold, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA)
        if characterTextNormalized~string == charTextNormalized~string then return .true
        charsTextSupplier~next
    end
    return .false

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
    use strict named arg normalization, casefold, lump, stripIgnorable, stripMark, stripCC, stripNA, aligned=.true

    call check_position startC, self~length

    otherText = other~request("RexxText") -- not requestTextOrBufferOrString because we really need a RexxText
    if .nil == otherText then signal argument_2_must_have_a_text_or_string_value

    .Encoding~comparisonMode(self, otherText) -- raise an error if not compatible

    call check_position nC, otherText~length
    if .nil == lengthC then lengthC = otherText~length - nC + 1
    call check_length lengthC, otherText~length, nC

    -- This implementation doesn't fulfill the following performance assertion,
    -- but it's just a prototype, okay?
    -- RexxRef:
    -- The match method is useful for efficient string parsing as it does not
    -- require new string objects be extracted from the target string.

    -- I do that because it's an easy way to support
    --   "Bundesstraße im Freiland"~text~caselessMatch(14, "im")
    -- where the casefold transformation invalidates the position 14 ("ß" becomes "ss")

    selfText = self~string~text
    selfSubText = selfText~substr(startC)
    otherSubText = otherText~substr(nC, lengthC)

    return 1 == selfSubText~indexer~posText(otherSubText, :normalization, :casefold, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA, :aligned)

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
    /*
    "abc def ghi"~pos("c de")           --> start=1,  length=11-start+1=11,             limit=start+length-4=8,     try from 1 to 8     --> 3
     12345678...
    "abc def ghi"~pos("c de", 2)        --> start=2,  length=11-start+1=10,             limit=start+length-4=8,     try from 2 to 8     --> 3
      2345678...
    "abc def ghi"~pos("i", 10)          --> start=10, length=11-start+1=2,              limit=start+length-1=11,    try from 10 to 11  --> 11
              01
    "abc def ghi"~pos("c d", 2, 4)      --> start=2,  length=min(4,11-start+1)=4,       limit=start+length-3=3,     try from 2 to 3     --> 3
      23..
    "abc def ghi"~pos("c de", 2, 6)     --> start=2,  length=min(6, 11-start+1)=6,      limit=start+length-4=4,     try from 2 to 4     --> 3
      234...
    "abc def ghi"~pos(" g", 2, 8)       --> start=2,  length=min(8, 11-start+1)=8,      limit=start+length-2=8,     try from 2 to 8     --> 8
      2345678.
    "abc def ghi"~pos(" g", 2, 80)      --> start=2,  length=min(80, 11-start+1)=10,    limit=start+length-2=10,    try from 2 to 10    --> 8
      2345678...
    */
    use strict arg needle, startC=1, lengthC=(self~length)
    use strict named arg normalization, casefold, lump, stripIgnorable, stripMark, stripCC, stripNA, aligned=.true, asList=.false, overlap=.false, debug=.false

    needleText = needle~request("RexxText") -- not requestTextOrBufferOrString because we really need a RexxText
    if .nil == needleText then signal argument_1_must_have_a_text_or_string_value

    .Encoding~comparisonMode(self, needleText) -- raise an error if not compatible

    if \datatype(startC, "w") then signal invalid_position
    if startC < 1 then signal invalid_position

    if \datatype(lengthC, "w") then signal invalid_length
    if lengthC < 0 then signal invalid_length
    if length == 0 then return 0

    if self~length == 0 then return 0
    if needleText~length == 0 then return 0
    if startC > self~length then return 0

    lengthC = min(lengthC, self~length - startC + 1)
    searchAreaTransformer = self~transformer(startC, lengthC)~transform(:normalization, :casefold, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA)
    needleTextTransformed = needleText                       ~transform(:normalization, :casefold, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA)
    searchArea =            searchAreaTransformer~xSubtext
    searchAreaTransformed = searchAreaTransformer~iSubtext
if debug then do
    width = 30
    say "searchArea ="~left(width) searchArea~string
    say "searchArea~c2g ="~left(width) searchArea~c2g
    say "searchAreaTransformed ="~left(width) searchAreaTransformed~string
    say "searchAreaTransformed~c2g ="~left(width) searchAreaTransformed~c2g
    say "needleText ="~left(width) needleText~string
    say "needleText~c2g ="~left(width) needleText~c2g
    say "needleTextTransformed ="~left(width) needleTextTransformed~string
    say "needleTextTransformed~c2g ="~left(width) needleTextTransformed~c2g
end

    -- default result
    if asList then list = .list~new
    else pos = 0

    startB = self~characterIndexB(startC)
    searchAreaNormalizedStartB = 1
    do forever
        posBFirst = searchAreaTransformed~string~pos(needleTextTransformed~string, searchAreaNormalizedStartB)
if debug then do
        say "searchAreaNormalizedStartB =" searchAreaNormalizedStartB
        say "posBFirst =" posBFirst
end
        if posBFirst == 0 then leave -- not found

        -- will check that the start of the transformed needle covers all the
        -- transformed bytes of the first matched grapheme of searchArea
        posCFirst = searchAreaTransformer~ib2xc(posBFirst, :aligned, :debug)

-- The next tests are convoluted.
-- It's because initially ib2xc returned .nil when not aligned, and now ib2xc returns a negative position.
-- to rework from here...
        posCLastPlus1 = .nil
        -- if aligned then
        -- no need to check the end pos if we know already that the start pos
        -- doesn't match (must be aligned with the first byte of the first
        -- matched grapheme)
        if /*.nil \== posCFirst,*/ \(aligned & posCFirst < 0) then do
            -- will check that the end of the transformed needle covers all the
            -- transformed bytes of the last matched grapheme of searchArea
            -- (must be aligned with the first byte of the first grapheme after
            -- the matched graphemes)
            posBLastPlus1 = posBFirst + needleTextTransformed~string~length
            searchAreaTransformer~backupPos
            posCLastPlus1 = searchAreaTransformer~ib2xc(posBLastPlus1, :aligned, :debug)
            searchAreaTransformer~restorePos
        end

        -- Remember: keep this test of .nil. posCFirst can no longer be .nil, but posCLastPlus1 can still be .nil.
        if aligned, .nil == posCFirst | .nil == posCLastPlus1 then do
            -- either first or last is not aligned
            pos = 0
        end
        else if aligned, posCFirst < 0 | posCLastPlus1 < 0 then do
            -- either first or last is not aligned
            pos = 0
        end
        else if \aligned then do
            -- returns a couple (array) of numbers +/-posC.posB
            pos = (posCFirst, posCLastPlus1)
        end
        else do
            -- aligned match, returns the position of the first character of the
            -- current match in the untransformed haystack (always > 0)
            pos = posCFirst
        end
-- ... to here

        if pos \== 0 then do
            if asList then list~append(pos)
            else leave -- only the first position is requested
        end

        if pos == 0 then searchAreaNormalizedStartB += 1
        else if overlap then searchAreaNormalizedStartB = posBFirst + 1
        else searchAreaNormalizedStartB = posBFirst + needleTextTransformed~string~length
        searchAreaNormalizedStartB = max(searchAreaNormalizedStartB, searchAreaTransformer~iSubtextPosB) -- for ligature like "ﬄ"
    end -- of do forever
    if asList then return list
    return pos

    argument_1_must_have_a_text_or_string_value:    raise syntax 93.900 /*93.938*/ array("Method positional argument 1 must have a text or string value")
    invalid_position:                               raise syntax 93.924 array(startC)
    invalid_length:                                 raise syntax 93.923 array(lengthC)


/******************************************************************************/
::class "IndexerStringInterface" mixinclass Object public -- private

::method append
    use strict arg text -- text or buffer or string
    use strict named arg buffer=.nil
    text = text~requestTextOrBufferOrString
    if .nil == text then signal must_have_a_text_or_buffer_or_string_value
    encoding = .Encoding~forConcatenation(self~string, text) -- raise an error if not compatible
    return encoding~append(self~string, text, :buffer)

    must_have_a_text_or_buffer_or_string_value: raise syntax 93.900 array("Method positional argument 1 must have a text or buffer or string value")


::method caselessCompare
    use strict arg text, pad=(self~encoding~spaceCharacter)
    use strict named arg strict=.true, normalization=(.Unicode~defaultNormalization(:strict)), lump=(\strict), stripIgnorable=(\strict), stripMark=.false, stripCC=.false, stripNA=.false, debug=.false
    return self~compareText(text, pad, :normalization, casefold:.true, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA, :debug)


::method caselessCompareTo
    use strict arg text, n=1, length=.nil
    use strict named arg strict=.true, normalization=(.Unicode~defaultNormalization(:strict)), lump=(\strict), stripIgnorable=(\strict), stripMark =.false, stripCC=.false, stripNA=.false
    return self~compareToText(text, n, length, :normalization, casefold:.true, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA)


::method caselessEndsWith
    use strict arg other
    use strict named arg strict=.true, normalization=(.Unicode~defaultNormalization(:strict)), lump=(\strict), stripIgnorable=(\strict), stripMark=.false, stripCC=.false, stripNA=.false
    return self~endsWithText(other, :normalization, casefold:.true, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA)


::method caselessMatch
    use strict arg startC, other, nC=1, lengthC=.nil
    use strict named arg strict=.true, normalization=(.Unicode~defaultNormalization(:strict)), lump=(\strict), stripIgnorable=(\strict), stripMark=.false, stripCC=.false, stripNA=.false, aligned=.true
    return self~matchText(startC, other, nC, lengthC, :normalization, casefold:.true, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA, :aligned)


::method caselessMatchChar
    use strict arg nC, chars
    use strict named arg strict=.true, normalization=(.Unicode~defaultNormalization(:strict)), lump=(\strict), stripIgnorable=(\strict), stripMark=.false, stripCC=.false, stripNA=.false
    return self~matchCharText(nC, chars, :normalization, casefold:.true, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA)


::method caselessPos
    use strict arg needle, startC=1, lengthC=(self~length)
    use strict named arg strict=.true, normalization=(.Unicode~defaultNormalization(:strict)), lump=(\strict), stripIgnorable=(\strict), stripMark=.false, stripCC=.false, stripNA=.false, aligned=.true, asList=.false, overlap=.false, debug=.false
    return self~posText(needle, startC, lengthC, :normalization, casefold:.true, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA, :aligned, :asList, :overlap, :debug)


::method center
    use strict arg length, pad=(self~encoding~spaceCharacter)
    use strict named arg buffer=.nil

    if \datatype(length, "w") then signal invalid_length
    if length < 0 then signal invalid_length

    padText = pad~request("RexxText") -- not requestTextOrBufferOrString because we really need the pad's length in characters
    if .nil == padText then signal incorrect_pad
    if padText~length <> 1 then signal incorrect_padText

    -- yes, check always, even if padText will not be used
    encoding = .Encoding~forConcatenation(self, padText) -- raise an error if not compatible

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
        leftPad = (width - len) % 2
        rightPad = (width - len) - leftPad
        space = rightPad + leftPad + len
        retval =
        if .nil <> buffer then do
            -- TODO: rework
            -- can't use encoding~concatenate for pad because pad~copies appends directly to the buffer
            -- consequence: will not detect WTF8 special concatenation, if any/
            padText~copies(leftPad, :buffer)
            encoding~concatenate(self~string, :buffer)
            padText~copies(rightPad, :buffer)
            return buffer
        end
        return encoding~concatenate(padText~copies(leftPad), self~string, padText~copies(rightPad))
    end
    else do
        leftPad = (len - width) % 2 -- integer divide
        return self~substr(leftPad + 1, width)
    end

    invalid_length:     raise syntax 93.923 array(length)
    incorrect_pad:      raise syntax 93.922 array(pad)
    incorrect_padText:  raise syntax 93.922 array(padText~descriptionForError)


::method compare
    use strict arg text, pad=(self~encoding~spaceCharacter)
    use strict named arg strict=.true, normalization=(.Unicode~defaultNormalization(:strict)), lump=(\strict), stripIgnorable=(\strict), stripMark=.false, stripCC=.false, stripNA=.false, debug=.false
    return self~compareText(text, pad, :normalization, casefold:.false, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA, :debug)


::method compareTo
    use strict arg text, n=1, length=.nil
    use strict named arg strict=.true, normalization=(.Unicode~defaultNormalization(:strict)), lump=(\strict), stripIgnorable=(\strict), stripMark =.false, stripCC=.false, stripNA=.false
    return self~compareToText(text, n, length, :normalization, casefold:.false, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA)


::method endsWith
    use strict arg other
    use strict named arg strict=.true, normalization=(.Unicode~defaultNormalization(:strict)), lump=(\strict), stripIgnorable=(\strict), stripMark=.false, stripCC=.false, stripNA=.false
    return self~endsWithText(other, :normalization, casefold:.false, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA)


::method length -- number of characters
    use strict arg -- none
    return self~characterCount


::method lower
    use strict arg startC=1, length=(max(0, self~length - startC + 1))
    use strict named arg buffer=.nil
    return self~lower_upper_title("l", startC, length, :buffer)


::method match
    use strict arg startC, other, nC=1, lengthC=.nil
    use strict named arg strict=.true, normalization=(.Unicode~defaultNormalization(:strict)), lump=(\strict), stripIgnorable=(\strict), stripMark=.false, stripCC=.false, stripNA=.false, aligned=.true
    return self~matchText(startC, other, nC, lengthC, :normalization, casefold:.false, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA, :aligned)


::method matchChar
    use strict arg nC, chars
    use strict named arg strict=.true, normalization=(.Unicode~defaultNormalization(:strict)), lump=(\strict), stripIgnorable=(\strict), stripMark=.false, stripCC=.false, stripNA=.false
    return self~matchCharText(nC, chars, casefold:.false, :normalization, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA)


::method pos
    use strict arg needle, startC=1, lengthC=(self~length)
    use strict named arg strict=.true, normalization=(.Unicode~defaultNormalization(:strict)), lump=(\strict), stripIgnorable=(\strict), stripMark=.false, stripCC=.false, stripNA=.false, aligned=.true, asList=.false, overlap=.false, debug=.false
    return self~posText(needle, startC, lengthC, :normalization, casefold:.false, :lump, :stripIgnorable, :stripMark, :stripCC, :stripNA, :aligned, :asList, :overlap, :debug)


::method reverse
    use strict arg -- none
    use strict named arg buffer=.nil
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new
    do indexC = self~characterCount to 1 by -1
        self~character(indexC, :buffer)
    end
    if returnBuffer then return buffer
                    else return .RexxText~new(buffer~string, self~encoding)


::method right
    use strict arg length, pad=(self~encoding~spaceCharacter)
    use strict named arg buffer=.nil

    if \datatype(length, "w") then signal invalid_length
    if length < 0 then signal invalid_length

    padText = pad~request("RexxText") -- not requestTextOrBufferOrString because we really need the pad's length in characters
    if .nil == padText then signal incorrect_pad
    if padText~length <> 1 then signal incorrect_padText

    encoding = .Encoding~forConcatenation(self~string, padText) -- raise an error if not compatible

    lengthPad = max(0, length - self~length)
    length = length - lengthPad

    endC = self~length + 1
    endB = abs(self~characterIndexB(endC))
    startC = endC - length
    startB = abs(self~characterIndexB(startC))
    right = self~string~right(endB - startB)
    if lengthPad == 0 then do
        if .nil <> buffer then return buffer~~append(right)
                          else return .RexxText~new(right, self~encoding)
    end
    if .nil <> buffer then do
        -- can't use encoding~concatenate for pad because pad~copies appends directly to the buffer
        -- consequence: will not detect WTF8 special concatenation, if any.
        padText~copies(lengthPad, :buffer)
        encoding~concatenate(right, :buffer)
        return buffer
    end
    return encoding~concatenate(padText~copies(lengthPad), right)

    invalid_length:     raise syntax 93.923 array(length)
    incorrect_pad:      raise syntax 93.922 array(pad)
    incorrect_padText:  raise syntax 93.922 array(padText~descriptionForError)


::method substr
    use strict arg startC, length=(max(0, self~length - startC + 1)), pad=(self~encoding~spaceCharacter)
    use strict named arg buffer=.nil

    if \datatype(startC, "w") then signal invalid_position
    if startC <= 0 then signal invalid_position

    if \datatype(length, "w") then signal invalid_length
    if length < 0 then signal invalid_length

    padText = pad~request("RexxText") -- not requestTextOrBufferOrString because we really need the pad's length in characters
    if .nil == padText then signal incorrect_pad
    if padText~length <> 1 then signal incorrect_padText

    encoding = .Encoding~forConcatenation(self~string, padText) -- raise an error if not compatible

    if startC > self~length then return padText~copies(length, :buffer)
    remainingLength = self~length - startC + 1 -- always >= 0
    lengthPad = max(0, length - remainingLength)
    endC = min(startC + length - 1, self~length)

    startB = abs(self~characterIndexB(startC))
    endB = abs(self~characterIndexB(endC+1))
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
        padText~copies(lengthPad, :buffer)
        return buffer
    end
    return encoding~concatenate(substr, padText~copies(lengthPad))

    invalid_length:     raise syntax 93.923 array(length)
    invalid_position:   raise syntax 93.924 array(startC)
    incorrect_pad:      raise syntax 93.922 array(pad)
    incorrect_padText:  raise syntax 93.922 array(padText~descriptionForError)


-- not a String method but maybe in the future...
::method title
    use strict arg startC=1, length=(max(0, self~length - startC + 1))
    use strict named arg buffer=.nil
    return self~lower_upper_title("t", startC, length, :buffer)


::method upper
    use strict arg startC=1, length=(max(0, self~length - startC + 1))
    use strict named arg buffer=.nil
    return self~lower_upper_title("u", startC, length, :buffer)
