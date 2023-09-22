::requires "encoding/stringIndexer.cls"
::requires "encoding/encoding.cls"
-- ::requires "encoding/unicode.cls"    -- .Unicode
-- ::requires "extension/text.cls"      -- .RexxText

/*
Depends on
.UNICODE16_ENCODING
.UNICODE32_ENCODING
.UNICODE8_ENCODING
.UNICODEN_ENCODING
.UTF16BE_ENCODING
.UTF16LE_ENCODING
.UTF32BE_ENCODING
.UTF32LE_ENCODING
.UTF8_ENCODING
.WTF16BE_ENCODING
.WTF16LE_ENCODING
.WTF8_ENCODING
*/


/******************************************************************************/
::class "Unicode_CommonServices" mixinclass Object public -- private

::constant isUnicode 1


::method analyze class
    forward message "createIndexer"


::method createIndexer class
    use strict arg string
    maximumCodepoint = 0
    codepointIndexes = .array~new -- sparse array: only the string indexes different from the array index are stored
    graphemeIndexes = .array~new -- idem
    codepointCount = 0
    graphemeCount = 0
    errors = .nil
    indexB = 1
    previousCodepoint = .nil
    previousCodepointIndexB = .nil
    graphemeBreakArgs = (.nil, .nil, 0) -- codepoint1, codepoint2, state. Will use the same array at each iteration.
    case = 3 -- bitor(2,1) both isUpper isLower

    encoding = self
    errorInfo = .array~new(1) -- simulate a variable reference: errorInfo[1] = errorMessage
    forever:
        codepoint = .nil
        nextB = encoding~nextCodepointIndexB(string, indexB, :errorInfo)
        if nextB < 0 then signal error
        codepoint = encoding~decode(string, indexB, nextB - indexB) -- codepoint can be .nil if nextB == indexB

        -- Remember : previousCodepoint can be .nil (first codepoint) or <0 (error recovery)
        checkResult = encoding~checkCodepoint(codepoint, indexB, previousCodepoint, previousCodepointIndexB, :errorInfo)
        if checkResult == -1 then do
            -- The byte-sequence starting at previousCodepointIndexB is invalid,
            -- undo the last index
            -- currently, that can happen only for WTF-8 in case of high-surrogate followed by a low-surrogate
            /*
                "D800"x~text("wtf16")~wtf8~c2x=             -- 'EDA080' is the high surrogate U+D800 encoded in WTF-8
                "DC00"x~text("wtf16")~wtf8~c2x=             -- 'EDB080' is the low surrogate U+DC00 encoded in WTF-8

                -- Remember: keep "41 42", it's to illustrate that the isolated surrogate is a grapheme in WTF-8

                "41 42 EDA080"x~text("wtf8")~c2u=           -- 'U+0041 U+0042 U+D800'   no error, the isolated high surrogate is a grapheme
                "41 42 EDA080"x~text("wtf8")~c2g=           -- '41 42 EDA080'

                                                            -- BUT if the next codepoint is a low surrogate then it's an error
                "41 42 EDA080 EDB080"x~text("wtf8")~c2u=    -- 'U+0041 U+0042 U+FFFD U+FFFD U+FFFD U+DC00'
                "41 42 EDA080 EDB080"x~text("wtf8")~c2g=    -- '41     42     ED     A0     80     EDB080'
            */
            codepointCount -= 1         -- yes, always, no problem
            graphemeCount -= 1          -- This is true ONLY for WTF-8
                                        -- See the example above. The isolated high surrogate is a grapheme when encoded in WTF-8.
                                        -- If, in the future, checkCodepoint can return -1 for an encoding other than WTF-8
                                        -- then the update of graphemeCount is maybe to rework!
            indexB = previousCodepointIndexB
            nextB = indexB + encoding~codeUnitSizeInBytes -- add 1 or 2 or 4
            signal error
        end
        else if checkResult == 0 then do
            -- The byte-sequence starting at indexB is invalid,
            nextB = indexB + encoding~codeUnitSizeInBytes -- add 1 or 2 or 4
            signal error
        end

        -- From here, we know that the current codepoint is valid
        if .nil == codepoint then signal leave -- End of string
        call indexCodepoint
        if .nil == previousCodepoint then call indexGrapheme -- First codepoint
        else if previousCodepoint < 0 then call indexGrapheme -- Error recovery
        else do
            graphemeBreakArgs[1] = previousCodepoint
            graphemeBreakArgs[2] = codepoint
            if .Unicode~utf8proc_graphemeBreak(graphemeBreakArgs) then call indexGrapheme
        end
        call checkCase
        previousCodepoint = codepoint
        previousCodepointIndexB = indexB
        indexB = nextB
    signal forever
    leave:

    -- Optimization if no need of indexes (when direct access is possible)
    if codepointIndexes~size == 0 then codepointIndexes = .nil
    if graphemeIndexes~size == 0 then graphemeIndexes = .nil
    return encoding~new(string, maximumCodepoint, codepointIndexes, codepointCount, graphemeIndexes, graphemeCount, case, errors)

    /*
        No need to store the string indexes which can be calculated from the array index.
        All the string indexes below can be calculated:
        index   UTF-8   UTF-16  UTF-32
          1       1       1       1
          2       2       3       5
          3       3       5       9
          ...
    */
    indexCodepoint:
        codepointCount += 1
        if indexB <> encoding~codeUnitSizeInBytes * (codepointCount -1) + 1 then do
            codepointIndexes[codepointCount] = indexB
        end
        maximumCodepoint = max(maximumCodepoint, codepoint)
        return

    indexGrapheme:
        graphemeCount += 1
        if indexB <> encoding~codeUnitSizeInBytes * (graphemeCount -1) + 1 then do
            graphemeIndexes[graphemeCount] = indexB
        end
        return

    checkCase:
        if case <> 0 then do
            if case == 1, \.Unicode~utf8proc_codepointIsLower(codepoint) then case = 0
            else if case == 2, \.Unicode~utf8proc_codepointIsUpper(codepoint) then case = 0
            else do -- case == 3
                if .Unicode~utf8proc_codepointIsLower(codepoint) then case = 1 -- can no longer be upper
                else if .Unicode~utf8proc_codepointIsUpper(codepoint) then case = 2 -- can no longer be lower
                else case = 0 -- can no longer be lower or upper
            end
        end
        return

    error:
        if .nil == errors then errors = .array~new
        errors~append(errorInfo[1])
        -- follow the recommendation of W3C : U+FFFD Substitution of Maximal Subparts
        nextB = abs(nextB)
        codepointCount += 1
        codepointIndexes[codepointCount] = -indexB -- a negative index means "error", a replacement character will be returned
        maximumCodepoint = max(maximumCodepoint, .Unicode~replacementCharacter~codepoint)
        graphemeCount += 1
        graphemeIndexes[graphemeCount] = -indexB -- idem
        graphemeBreakArgs[3] = 0 -- reset the extended grapheme state
        previousCodepoint = codepoint
        if .nil <> codepoint then previousCodepoint = -codepoint -- Negative codepoint allows to get the original value, if needed, while knowing it's invalid
        previousCodepointIndexB = indexB
        indexB = nextB -- resume at the next valid code unit
        signal forever


::method codepointToLowerSimple class
    use strict arg codepoint
    return .Unicode~utf8proc_codepointToLowerSimple(codepoint)


::method codepointToLowerFull class
    use strict arg codepoint
    lowerFull = .Unicode~codepointToLowerFull(codepoint)
    if .nil \== lowerFull then return lowerFull
    return .Unicode~utf8proc_codepointToLowerSimple(codepoint)


::method codepointToUpperSimple class
    use strict arg codepoint
    return .Unicode~utf8proc_codepointToUpperSimple(codepoint)


::method codepointToUpperFull class
    use strict arg codepoint
    upperFull = .Unicode~codepointToUpperFull(codepoint)
    if .nil \== upperFull then return upperFull
    return .Unicode~utf8proc_codepointToUpperSimple(codepoint)


::method codepointToTitleSimple class
    use strict arg codepoint
    return .Unicode~utf8proc_codepointToTitleSimple(codepoint)


::method codepointToTitleFull class
    use strict arg codepoint
    titleFull = .Unicode~codepointToTitleFull(codepoint)
    if .nil \== titleFull then return titleFull
    return .Unicode~utf8proc_codepointToTitleSimple(codepoint)


/********************/
/* Instance methods */
/********************/

::method transcodeTo
    use strict arg targetEncoding
    targetEncoding = .Encoding~factory(targetEncoding, self~string)
    if targetEncoding~isUnicode then forward message "convertToUnicode"
    if targetEncoding~isByte then forward message "convertToByte"
    -- Should not reach here


::method convertToUnicode private
    /*
    D93 Encoding form conversion:
    A conversion defined directly between the code unit sequences of one Unicode
    encoding form and the code unit sequences of another Unicode encoding form.
    - In implementations of the Unicode Standard, a typical API will logically
      convert the input code unit sequence into Unicode scalar values (code points)
      and then convert those Unicode scalar values into the output code unit sequence.
      Proper analysis of the encoding forms makes it possible to convert the code units
      directly, thereby obtaining the same results but with a more efficient process.
    - A conformant encoding form conversion will treat any ill-formed code unit
      sequence as an error condition. (See conformance clause C10.) This guarantees
      that it will neither interpret nor emit an ill-formed code unit sequence.
      Any implementation of encoding form conversion must take this requirement
      into account, because an encoding form conversion implicitly involves a
      verification that the Unicode strings being converted do, in fact, contain
      well-formed code unit sequences.
    */
    use strict arg targetEncoding
    use strict named arg strict = .false, memorize = (.Unicode~memorizeConversions), buffer = .nil, replacementCharacter=.nil

    targetEncoding = .Encoding~factory(targetEncoding, self~string)
    if \targetEncoding~isUnicode then signal target_encoding_not_unicode

    string = .nil
    if self~encoding == targetEncoding then string = self~string
    else string = self~getCachedString(targetEncoding~name)
    if .nil \== string then do
        if .nil <> buffer then return targetEncoding~append(string, :buffer) -- buffer~~append(string)
                          else return string~text
    end

    sizeC = self~codepointCount -- size in codepoints
    returnBuffer = .nil \== buffer
    if .nil == buffer then buffer = .MutableBuffer~new(, sizeC * targetEncoding~codepointMaxBytes)
    buffer~encoding = targetEncoding~asEncodingFor(buffer) -- raise an error if not compatible
    bufferStart = buffer~length + 1
    do i=1 to sizeC
        codepoint = self~codepoint(i)
        indexB = self~codepointIndexB(i)
        targetEncoding~encode(codepoint, indexB, :buffer) -- WTF-8 is correctly managed (use appendToBuffer)
    end
    string = buffer~substr(bufferStart)
    -- It's a new string, without any encoding stored on it
    string~encoding = targetEncoding
    if memorize then self~cacheString(targetEncoding~name, string)

    if returnBuffer then return buffer
    text = .RexxText~new(string, targetEncoding)
    if memorize then text~indexer~cacheString(self~encoding~name, self~string)
    return text

    target_encoding_not_unicode:    raise syntax 23.900 array("The target encoding '"targetEncoding~name"' is not a Unicode encoding")


::method convertToByte private
    use strict arg targetEncoding
    use strict named arg strict=.false, memorize = (.Unicode~memorizeConversions), buffer=.nil, replacementCharacter=.nil

    targetEncoding = .Encoding~factory(targetEncoding, self~string)
    if \targetEncoding~isByte then signal target_encoding_not_byte

    tableTranscodingFromUnicode = targetEncoding~tableTranscodingFromUnicode
    if .nil == tableTranscodingFromUnicode then signal cannot_convert_encoding

    -- replacementCharacter: 1 character max or .nil.
    -- if .nil then will raise an error if a character can't be converted
    -- otherwise if not "" then will be used in replacement of a character that can't be converted
    -- otherwise any character that can't be converted will be ignored
    if .nil \== replacementCharacter then do
        replacementCharacter = replacementCharacter~string
        if replacementCharacter~length > 1 then signal invalid_replacement_character
        if replacementCharacter \== "" then replacementCharacter = replacementCharacter~c2d -- ready to use by encode which expects a whole number 0..255
    end

    string = self~getCachedString(targetEncoding~name)
    if .nil \== string then do
        if .nil <> buffer then return targetEncoding~append(string, :buffer)
                          else return string~text
    end

    sizeC = self~codepointCount -- size in codepoints
    returnBuffer = .nil <> buffer

    if .nil == buffer then buffer = .MutableBuffer~new(, sizeC * targetEncoding~codepointMaxBytes)
    buffer~encoding = targetEncoding~asEncodingFor(buffer) -- raise an error if not compatible

    bufferStart = buffer~length + 1
    do i=1 to sizeC
        codepoint = self~codepoint(i)
        indexB = self~codepointIndexB(i)
        charcode = tableTranscodingFromUnicode~at(codepoint)
        charcode = check_replace_char()
        if .nil == charcode then signal cannot_convert_character
        if charcode \== "" then targetEncoding~encode(charcode, indexB, :buffer)
    end

    string = buffer~substr(bufferStart)
    -- It's a new string, without any encoding stored on it
    string~encoding = targetEncoding
    if memorize then self~cacheString(targetEncoding~name, string)

    if returnBuffer then return buffer
    text = .RexxText~new(string, targetEncoding)
    if memorize then text~indexer~cacheString(self~encoding~name, self~string)
    return text

    target_encoding_not_byte:       raise syntax 23.900 array("The target encoding '"targetEncoding~name"' is not a Byte encoding")
    invalid_replacement_character:  raise syntax 23.900 array("The replacement character is one byte max, got '"replacementCharacter"' ("replacementCharacter~c2x")")
    cannot_convert_encoding:        raise syntax 23.900 array(self~encoding~name "encoding: cannot convert" self~description(short: .true) "to" targetEncoding~name)
    cannot_convert_character:       raise syntax 23.900 array(self~encoding~name "encoding: cannot convert" self~description(short: .true) "codepoint" codepoint "("codepoint~d2x") at position" i "to" targetEncoding~name)

    check_replace_char:
        -- A .nil charcode means no mapping
        -- An empty charcode means no mapping
        -- A negative charcode means unused character with fallback mapping
        if .nil == charcode then return replacementCharacter
        if charcode == "" then return replacementCharacter
        if strict, charcode < 0 then return .nil -- no fallback when strict
        return abs(charcode)


::method c2u
    use strict arg -- none
    use strict named arg buffer=.nil
    codepoints = self~codepoints
    returnBuffer = .nil <> buffer
    if .nil == buffer then buffer = .MutableBuffer~new
    first = .true
    do while codepoints~available
        if \first then buffer~append(" ")
        first = .false
        call ppCodepoint codepoints~item, :buffer
        codepoints~next
    end
    if returnBuffer then return buffer
                    else return buffer~string


::method maximumUnicodeCodepoint
    forward message "maximumCodepoint"


::method UnicodeCharacters
    use strict arg -- none
    return self~codepoints~each{.unicode~character(item)}


::method UTF8
    use strict arg -- none
    use strict named arg strict=.false, memorize = (.Unicode~memorizeConversions), buffer=.nil
    return self~convertToUnicode(.UTF8_Encoding, :strict, :memorize, :buffer)


::method WTF8
    use strict arg -- none
    use strict named arg strict=.false, memorize = (.Unicode~memorizeConversions), buffer=.nil
    return self~convertToUnicode(.WTF8_Encoding, :strict, :memorize, :buffer)


::method UTF16
    forward message "UTF16BE"


::method UTF16BE
    use strict arg -- none
    use strict named arg strict = .false, memorize = (.Unicode~memorizeConversions), buffer=.nil
    return self~convertToUnicode(.UTF16BE_Encoding, :strict, :memorize, :buffer)


::method UTF16LE
    use strict arg -- none
    use strict named arg strict = .false, memorize = (.Unicode~memorizeConversions), buffer=.nil
    return self~convertToUnicode(.UTF16LE_Encoding, :strict, :memorize, :buffer)


::method WTF16
    forward message "WTF16BE"


::method WTF16BE
    use strict arg -- none
    use strict named arg strict = .false, memorize = (.Unicode~memorizeConversions), buffer=.nil
    return self~convertToUnicode(.WTF16BE_Encoding, :strict, :memorize, :buffer)


::method WTF16LE
    use strict arg -- none
    use strict named arg strict = .false, memorize = (.Unicode~memorizeConversions), buffer=.nil
    return self~convertToUnicode(.WTF16LE_Encoding, :strict, :memorize, :buffer)


::method UTF32
    forward message "UTF32BE"


::method UTF32BE
    use strict arg -- none
    use strict named arg strict = .false, memorize = (.Unicode~memorizeConversions), buffer=.nil
    return self~convertToUnicode(.UTF32BE_Encoding, :strict, :memorize, :buffer)


::method UTF32LE
    use strict arg -- none
    use strict named arg strict = .false, memorize = (.Unicode~memorizeConversions), buffer=.nil
    return self~convertToUnicode(.UTF32LE_Encoding, :strict, :memorize, :buffer)


::method Unicode
    forward message "UnicodeN"


::method UnicodeN
    use strict arg -- none
    use strict named arg strict = .false, memorize = (.Unicode~memorizeConversions), buffer=.nil
    return self~convertToUnicode("UnicodeN", :strict, :memorize, :buffer)


::method Unicode8
    use strict arg -- none
    use strict named arg strict = .false, memorize = (.Unicode~memorizeConversions), buffer=.nil
    return self~convertToUnicode(.Unicode8_Encoding, :strict, :memorize, :buffer)


::method Unicode16
    use strict arg -- none
    use strict named arg strict = .false, memorize = (.Unicode~memorizeConversions), buffer=.nil
    return self~convertToUnicode(.Unicode16_Encoding, :strict, :memorize, :buffer)


::method Unicode32
    use strict arg -- none
    use strict named arg strict = .false, memorize = (.Unicode~memorizeConversions), buffer=.nil
    return self~convertToUnicode(.Unicode32_Encoding, :strict, :memorize, :buffer)
