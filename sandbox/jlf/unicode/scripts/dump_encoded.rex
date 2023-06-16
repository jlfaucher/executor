/*
Dumps the contents of the specified encoded file.
The file encoding is not guessed, it must be passed explicitely.
The lines of the file are dumped as-is, in their native encoding. The non-printable characters are written in [hex].
The rest of the output is in byte encoding (description, hexadecimal characters, errors).
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

.Unicode~loadDerivedName(/*action*/ "load", /*showProgress*/ .false)

errorCount = 0
do i=2 to cmdargs~size
    filename = cmdargs[i]
    errorCount += dumpEncodedFile(filename, encoding)
end
say "Total:" errorCount~singularPluralCount("error", "errors")
return errorCount <> 0


::routine sayUsage
    say "Usage:"
    say "    rexx dump_encoded <encoding> <file 1>...<file n>"
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


::routine dumpEncodedFile
    use strict arg filename, encoding
    say "Dumping file" filename~quoted
    spaces = "  "
    -- stream = .encodedStream~new(filename, encoding) -- manage correctly the end of line in function of the encoding
    stream = .stream~new(filename)
    signal on notready
    errorCount = 0
    lineNumber = 1
    do forever
        -- lineText = stream~linein -- an EncodedStream returns directly a RexxText
        lineString = stream~linein
        lineText = lineString~text(encoding)
        say spaces || lineNumber~left(4) lineText~ppString -- raw output of lineText, in binary format, whatever its encoding
        say spaces || lineNumber~left(4) lineText~description
        say spaces || lineNumber~left(4) lineText~c2x
        lineText~UnicodeCharacters~each{
            expose spaces lineNumber
            say spaces || lineNumber~left(4) item
        }
        if lineText~errors <> .nil then do
            loop error over lineText~errors
                say spaces || lineNumber~left(4) error
                errorCount += 1
            end
        end
        say
        lineNumber += 1
    end

    notready:
    say spaces || errorCount~singularPluralCount("error", "errors")
    return errorCount


::requires "extension/extensions.cls"
