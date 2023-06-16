/*
Checks if the specified files are correctly encoded
*/

cmdargs = .local~syscargs
if cmdargs~size == 0  then do
    call sayUsage
    return 1
end

encodingName = cmdargs[1]
encoding = getEncoding(encodingName)
if encoding == .nil then do
    say encodingName~quoted "is an invalid encoding."
    say "Supported encodings:"
    call saySupportedEncodings, indent:4
    return 1
end

errorCount = 0
do i=2 to cmdargs~size
    filename = cmdargs[i]
    errorCount += checkFileEncoding(filename, encoding)
end
say "Total:" errorCount~singularPluralCount("error", "errors")
return errorCount <> 0


::routine sayUsage
    say "Usage:"
    say "    rexx check_encoding <encoding> <file 1>...<file n>"
    say "where <encoding> is one of"
    call saySupportedEncodings, indent:4


::routine saySupportedEncodings
    use strict arg -- none
    use strict named arg indent=0
    spaces = " "~copies(indent)
    encodings = .encoding~list~table
    allIndexes = encodings~allIndexes
    widthMax = allIndexes~each("length")~reduce("max")
    do encodingName over allIndexes~sort
        say spaces || encodingName~left(widthMax) || " : " || encodings[encodingName]
    end


::routine getEncoding
    use strict arg encodingName
    signal on syntax name invalid_encoding
        encoding = .encoding~factory(encodingName)
    signal off syntax
    return encoding

    invalid_encoding:
    return .nil


::routine checkFileEncoding
    use strict arg filename, encoding
    say "Checking file" filename~quoted
    spaces = "  "
    stream = .stream~new(filename)
    signal on notready
    errorCount = 0
    lineNumber = 1
    do forever
        lineString = stream~linein
        lineText = lineString~text(encoding)
        if lineText~errors <> .nil then do
            loop error over lineText~errors
                say spaces || "line" lineNumber":" error
                errorCount += 1
            end
        end
        lineNumber += 1
    end

    notready:
    say spaces || errorCount~singularPluralCount("error", "errors")
    return errorCount


::requires "extension/extensions.cls"
