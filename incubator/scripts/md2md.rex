/*
Transform a Markdown file to another Mardown file.

The titles are numbered, except the first level.
# title         -->     # title
## title        -->     ## 1 title
### title       -->     ### 1.1 title
#### title      -->     #### 1.1.1 title
##### title     -->     ##### 1.1.1.1 title
###### title    -->     ###### 1.1.1.1.1 title

If a title has already a number, then this number is removed, and the new
number is inserted.

KEEP THIS SCRIPT COMPATIBLE WITH OOREXX5
*/

if arg() == 0 then signal help

force = .false
parse_options:
    option = c_arg()
    option = option~lower

         if option == "-f"         then signal option_force
    else if option == "--force"    then signal option_force
    else if option == "-h"         then signal help
    else if option == "--help"     then signal help
    else if option == "--"         then signal option_end_of_options
    else if option~left(1) == "-"  then signal unknown_option
    else signal end_of_options

end_of_options:
    inputname = c_arg()
    call shift_c_args
    outputname = c_arg()
    call shift_c_args
    rest = remaining_c_args()
    if rest \== "" then signal unexpected_arguments

    if inputname == "" then inputname = "stdin"
    if outputname == "" then outputname = "stdout"

    inputobject = .stream~new(inputname)
    outputobject = .stream~new(outputname)
    if \ setupStreams(inputobject, outputobject, force) then exit -1
    call transform inputname, inputobject, outputobject
    exit 0

option_force:
    force = .true
    call shift_c_args -- skip the option
    signal parse_options -- continue parsing

option_end_of_options:
    call shift_c_args -- skip the option
    signal end_of_options

unknown_option:
    .error~say("Unknown option" option)
    signal usage

unexpected_arguments:
    .error~say("Unexpected arguments:" rest)
    signal usage

help:
    .error~say("Description:")
    .error~say("    Transform a Markdown file to another Mardown file.")
    .error~say("    The titles are numbered, except the first level.")
    signal usage

usage:
    parse source . . script
    scriptname = .file~new(script)~name
    dotpos = scriptname~lastpos(".")
    if dotpos \== 0 then scriptname = scriptname~left(dotpos - 1)
    .error~say("Usage:")
    .error~say("    "scriptname" [-h | --help] [-f | --force] [--] [inputname [outputname]]")
    .error~say("    where")
    .error~say("        -f --force  force overwriting if outputname already exists")
    .error~say("        -h --help   display help")
    .error~say("        --          indicate the end of options")
    .error~say("        inputname default value is stdin")
    .error~say("        outputname default value is stdout")
    exit -1


-------------------------------------------------------------------------------
-- Setup the streams

::routine setupStreams
    use strict arg inputobject, outputobject, force

    status = inputobject~open("READ")
    if status \== "READY:" then signal cannot_open_inputname

    if inputobject~qualify == outputobject~qualify then signal inputstream_must_be_different_from_outputstream
    if force == .false, outputobject~query("EXISTS") \== "" then signal outputname_exists

    status = outputobject~open("WRITE REPLACE")
    if status \== "READY:" then signal cannot_open_outputname

    return .true

    inputstream_must_be_different_from_outputstream:
        .error~say("The input stream must be different from the output stream")
        return .false

    outputname_exists:
        .error~say("The output file already exists, use -f to force overwriting")
        return .false

    cannot_open_inputname:
        .error~say("Can't open" inputobject~qualify)
        .error~say(status)
        return .false

    cannot_open_outputname:
        .error~say("Can't open" outputobject~qualify)
        .error~say(status)
        return .false


-------------------------------------------------------------------------------
-- Transformation the Markdown stream

::routine transform
    use strict arg inputname, inputobject, outputobject

    counter = .hierarchicalCounter~new
    contents = .list~new

    signal on notready
    do while inputobject~state == "READY"
        line = inputobject~linein
        line = transformLine(line, counter)
        contents~append(line)
    end
    notready:

    supplier = contents~supplier
    do while supplier~available
        line = supplier~item
        outputobject~lineout(line)
        outputobject~flush
        supplier~next
    end

    return


::routine transformLine
    use strict arg line, counter
    resultArray = .array~new -- simulate a variable reference
    if titleLevel(line, counter, 1, resultArray) then return resultArray[1]
    if titleLevel(line, counter, 2, resultArray) then return resultArray[1]
    if titleLevel(line, counter, 3, resultArray) then return resultArray[1]
    if titleLevel(line, counter, 4, resultArray) then return resultArray[1]
    if titleLevel(line, counter, 5, resultArray) then return resultArray[1]
    if titleLevel(line, counter, 6, resultArray) then return resultArray[1]
    return line


::routine titleLevel
    use strict arg line, counter, titleLevel, resultArray

    if titleLevel > 6 then return line -- only 6 title levels in Markdown
    if ("######"~left(titleLevel) || " ") \== line~left(titleLevel + 1) then return .false

    -- Example with title level 2:
    -- ## this is a title
    -- 1234
    -- ## 10.200 this is a title
    -- 12345678901
    startNumber = titleLevel + 2
    startTitle = startNumber
    spaces = .hierarchicalCounter~spaces
    endNumber = line~pos(spaces, startNumber)
    if endNumber \== 0, line~substr(startNumber, endNumber - startNumber)~verify("0123456789.") == 0 then startTitle = endNumber + spaces~length
    resultArray[1]  = "######"~left(titleLevel) || " " || counter~next(titleLevel) || line~substr(startTitle)
    return .true


-------------------------------------------------------------------------------
-- Generator of hierarchical counters
-- No counter for the level 1

::class hierarchicalCounter

::constant levelMax 6
-- With Chrome, a sequence of "normal" space is collapsed into one space in the titles
-- Using the Unicode character No-Break Space (NBSP)
::constant space "C2A0"x
::constant spaceNumber 3


::method spaces class
    return self~space~copies(self~spaceNumber)


::method init
    expose counters
    counters = .array~new(self~levelMax)~~fill(0)


::method next
    expose counters
    use strict arg level
    if level < 1 or level > self~levelMax then return "<Invalid level: "level">"

    counter = ""
    loop i = 1 to level
        if i == level then do
            counters[i] += 1
            -- reset the counters at upper level (child counters of current counter)
            do j = i + 1 to self~levelMax
                counters[j] = 0
            end
            -- self~charout(level, .true);
            if i == 1 then return "" -- no counter displayed for #
            return counter || counters[i] || "." || self~class~spaces
        end
        else do
            -- no counter displayed for #
            if i > 1 then counter ||= counters[i] || "."
        end
    end


::method charout
    expose counters
    use strict arg level, newline

    -- Display all the counters
    .traceOutput~charout(level": ")
    do i = 1 to self~levelMax
        .traceOutput~charout(counters[i])
    end
    if newline then .traceOutput~say


-------------------------------------------------------------------------------
-- Helpers to manipulate the C arguments

::routine c_arg
    if .nil == .syscargs[1] then return ""
    return .syscargs[1]


::routine shift_c_args
    .syscargs~delete(1)
    return


::routine remaining_c_args
    return .syscargs~toString("line", " ") -- concatenate all the remaining C arguments, separated by a space character.
