/*
Usage:
rexx test_encoding_combinations.rex > test_encoding_combinations-output.txt
*/

-- Test all the combinations of encodings.
-- For each combination, test ASCII,ASCII, not-ASCII,ASCII and ASCII,not-ASCII.
errors = .array~new
encodings = .array~new
.stringIndexer~pipe(.subclasses "rec" | .sort | .arrayCollector[encodings])

title = "leftEncoding................... rightEncoding..................     concatEncoding. bufferEncoding. compare"
say title
say "-"~copies(title~length)

count.EncodingCombinations = 0
count.Cases = 0
count.BadBufferEncodings = 0
.Collection~product2(encodings){
    expose count.EncodingCombinations count.Cases count.BadBufferEncodings errors
    count.EncodingCombinations += 1
    say "countEncodingCombination =" count.EncodingCombinations

    -- CAREFUL! The literal strings are interned by the parser
    -- MUST use .string~new to ensure it's a distinct instance

    left = .string~new("ee")~text(item1)
    right = .string~new("ee")~text(item2)
    call display

    left = .string~new("ée")~text(item1)
    right = .string~new("ee")~text(item2)
    call display

    left = .string~new("ee")~text(item1)
    right = .string~new("ée")~text(item2)
    call display

    left = .string~new("ée")~text(item1)
    right = .string~new("ée")~text(item2)
    call display

    return

    display:
        count.Cases += 1
        errorInfo = .array~new(1) -- simulate a variable reference: errorInfo[1] = errorMessage

        concatEncoding = .Encoding~forConcatenation(left, right, :errorInfo)
        if .nil == concatEncoding then errors~append("case" count.Cases":" errorInfo[1])

        bufferEncoding = item2~asEncodingFor(left, :errorInfo)
        if .nil == bufferEncoding then errors~append("case" count.Cases":" errorInfo[1])
        bufferEncodingFlag = (concatEncoding \== bufferEncoding)~?("*", "") -- should be always equal

        compare = .Encoding~comparisonMode(left, right, :errorInfo)
        if compare == "error" then errors~append("case" count.Cases":" errorInfo[1])

        say name(item1) asciiness(left) name(item2) asciiness(right) "-->" name(concatEncoding) name(bufferEncoding, bufferEncodingFlag) compare
        return

    name: procedure expose count.BadBufferEncodings
        use strict arg encoding, flag=""
        if flag \== "" then count.BadBufferEncodings += 1
        if .nil == encoding then return ("nil" || flag)~left(15)
        return (encoding~name || flag)~left(15)

    asciiness: procedure
        use strict arg text
        if text~isASCII then asciiness = "ASCII"
                        else asciiness = "not-ASCII"
        return asciiness~left(15)
}

say
call dump2 errors, /*title*/, /*comparator*/, /*iterateOverItem*/, /*surroundItemByQuotes*/ .false, /*surroundIndexByQuotes*/, /*maxCount*/, /*action*/

say
say encodings~items "encodings"
say count.EncodingCombinations "encoding combinations * 4 asciiness combinations =" count.EncodingCombinations * 4 "cases"
say count.Cases "cases * 3 checks =" count.Cases * 3 "results of which" errors~items "errors"
say count.BadBufferEncodings "bad buffer encodings"

::requires "extension/extensions.cls"
::requires "pipeline/pipe_extension.cls"
::requires "rgf_util2/rgf_util2.rex"
--::options trace i
