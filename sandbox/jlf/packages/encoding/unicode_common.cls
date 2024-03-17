::requires "encoding/stringIndexer.cls"
::requires "encoding/encoding.cls"
::requires "encoding/byte_common.cls" -- for atBytePosition
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
    -- In case of transcoding error:
    -- if errorInfo is .nil (default) then raise the error
    -- otherwise store the error message in errorInfo and return .nil
    use strict arg targetEncoding
    use strict named arg strict=.false, memorize = (.Unicode~memorizeTranscodings), buffer=.nil, replacementCharacter=.nil, errorInfo=.nil

    replacementCodepoint = replacementCodepoint(replacementCharacter, targetEncoding)
    targetEncoding = .Encoding~factory(targetEncoding, self~string, :replacementCodepoint) -- replacementCodepoint is used for UnicodeN, to determine the maximumUnicodeCodepoint
    if targetEncoding~isUnicode then return self~transcodeToUnicode(targetEncoding, :memorize, :buffer, :replacementCodepoint, :errorInfo)
    if targetEncoding~isByte then return self~transcodeToByte(targetEncoding, :strict, :memorize, :buffer, :replacementCodepoint, :errorInfo)
    -- Should not reach here


::method transcodeToUnicode private
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
    use strict named arg memorize, buffer, replacementCodepoint, errorInfo

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
    encodeErrorInfo = .array~new -- simulate a variable passed by reference
    do i=1 to sizeC
        codepoint = self~codepoint(i)
        indexB = self~codepointIndexB(i)
        -- yes, checkOnlyRange, otherwise "\uD83D"~text~unescape will fail because U+D83D is a surrogate
        if targetEncoding~checkCodepoint(codepoint, checkOnlyRange: .true, errorInfo: encodeErrorInfo) \== 1 then do
            -- codepoint can't be transcoded
            if .nil == replacementCodepoint then signal cannot_convert_character
            if replacementCodepoint \== "" then targetEncoding~encode(replacementCodepoint, indexB, :buffer)
        end
        else targetEncoding~encode(codepoint, indexB, :buffer) -- WTF-8 is correctly managed (use appendToBuffer)
    end
    string = buffer~substr(bufferStart)
    -- It's a new string, without any encoding stored on it
    string~encoding = targetEncoding
    if memorize then self~cacheString(targetEncoding~name, string)

    if returnBuffer then return buffer
    text = .RexxText~new(string, targetEncoding)

    -- discutable... On the target, I memorize the origin string.
    -- but nothing guarantees that transcoding the target string to the origin encoding would give the origin string.
    if memorize then text~indexer~cacheString(self~encoding~name, self~string)
    return text

    cannot_convert_character: return error("Cannot convert" self~description(short: .true) "codepoint" codepoint "("ppCodepoint(codepoint)")" || atBytePosition(indexB) "to" targetEncoding~name)

    error:
        use strict arg errorMessage
        if .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return .nil
        end
        raise syntax 23.900 array (errorMessage)


::method transcodeToByte private
    use strict arg targetEncoding
    use strict named arg strict, memorize, buffer, replacementCodepoint, errorInfo

    tableTranscodingFromUnicode = targetEncoding~tableTranscodingFromUnicode
    if .nil == tableTranscodingFromUnicode then signal cannot_convert_encoding

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
        charcode = tableTranscodingFromUnicode~at(codepoint) -- it's a directory, no need to search codepoint+1
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

    cannot_convert_encoding:    return error("Cannot convert" self~description(short: .true) "to" targetEncoding~name)
    cannot_convert_character:   return error("Cannot convert" self~description(short: .true) "codepoint" codepoint "("codepoint~d2x") at position" i "to" targetEncoding~name)

    error:
        use strict arg errorMessage
        if .nil <> errorInfo then do
            errorInfo[1] = errorMessage"."
            return .nil
        end
        raise syntax 23.900 array (errorMessage)

    check_replace_char:
        -- A .nil charcode means no mapping
        -- An empty charcode means no mapping
        -- A negative charcode means unused character with fallback mapping
        if .nil == charcode then return replacementCodepoint
        if charcode == "" then return replacementCodepoint
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
    forward message "maximumCodepoint" -- attribute, updated during the analysis


::method UnicodeCharacters
    use strict arg -- none
    return self~codepoints~each{.unicode~character(item)}


::method UTF8
    use strict arg -- none
    forward message "transcodeTo" arguments ( .array~of(.UTF8_Encoding) )


::method WTF8
    use strict arg -- none
    forward message "transcodeTo" arguments ( .array~of(.WTF8_Encoding) )


::method UTF16
    forward message "UTF16BE"


::method UTF16BE
    use strict arg -- none
    forward message "transcodeTo" arguments ( .array~of(.UTF16BE_Encoding) )


::method UTF16LE
    use strict arg -- none
    forward message "transcodeTo" arguments ( .array~of(.UTF16LE_Encoding) )


::method WTF16
    forward message "WTF16BE"


::method WTF16BE
    use strict arg -- none
    forward message "transcodeTo" arguments ( .array~of(.WTF16BE_Encoding) )


::method WTF16LE
    use strict arg -- none
    forward message "transcodeTo" arguments ( .array~of(.WTF16LE_Encoding) )


::method UTF32
    forward message "UTF32BE"


::method UTF32BE
    use strict arg -- none
    forward message "transcodeTo" arguments ( .array~of(.UTF32BE_Encoding) )


::method UTF32LE
    use strict arg -- none
    forward message "transcodeTo" arguments ( .array~of(.UTF32LE_Encoding) )


::method Unicode
    forward message "UnicodeN"


::method UnicodeN
    use strict arg -- none
    forward message "transcodeTo" arguments ( .array~of("UnicodeN") )


::method Unicode8
    use strict arg -- none
    forward message "transcodeTo" arguments ( .array~of(.Unicode8_Encoding) )


::method Unicode16
    use strict arg -- none
    forward message "transcodeTo" arguments ( .array~of(.Unicode16_Encoding) )


::method Unicode32
    use strict arg -- none
    forward message "transcodeTo" arguments ( .array~of(.Unicode32_Encoding) )
