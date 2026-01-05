/*
Transform a Markdown file to another Mardown file.

If 0 or 1 level 1 title, or if option --no-level-1 then
    The level 1 counter is not displayed in the sequence of title counters.
    # title         -->     # title
    ## title        -->     ## 1. title
    ### title       -->     ### 1.1. title
    #### title      -->     #### 1.1.1. title
    ##### title     -->     ##### 1.1.1.1. title
    ###### title    -->     ###### 1.1.1.1.1. title
otherwise
    All the counters are displayed in the sequence of title counters.
    # title         -->     # 1. title
    ## title        -->     ## 1.1. title
    ### title       -->     ### 1.1.1. title
    #### title      -->     #### 1.1.1.1. title
    ##### title     -->     ##### 1.1.1.1.1. title
    ###### title    -->     ###### 1.1.1.1.1.1. title

If a title has already a number, then
- this number is checked for length consistency with the title level;
  In case of discrepancy, an error is reported.
- this number is removed, and the new number is inserted.

Note:
Numbering consistency is not checked, as the purpose of this script is to
(re-)generate consistent title numbers.

KEEP THIS SCRIPT COMPATIBLE WITH OOREXX5
*/

signal on syntax name abort

.local~column.width = 5
.local~column.separator = "  " -- plus one space before and one space after when written "before" .column.separator "after"
.local~verbose = .false

if arg() == 0 then signal help

display_level_1 = .true
force_overwrite = .false
force_update = .false

parse_options:
    option = c_arg()
    option = option~lower

         if option == "-fo"                 then signal option_force_overwrite
    else if option == "--force-overwrite"   then signal option_force_overwrite
    else if option == "-fu"                 then signal option_force_update
    else if option == "--force-update"      then signal option_force_update
    else if option == "-h"                  then signal help
    else if option == "--help"              then signal help
    else if option == "-nl1"                then signal option_no_level_1
    else if option == "--no-level-1"        then signal option_no_level_1
    else if option == "-v"                  then signal option_verbose
    else if option == "--verbose"           then signal option_verbose
    else if option == "--"                  then signal option_end_of_options
    else if option~left(1) == "-"           then signal unknown_option
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

    inputobject = setupInputStream(inputname)
    outputobject = setupOutputStream(outputname, force_overwrite, inputobject)
    if \ transform(inputobject, outputobject, outputname, display_level_1, force_update) then exit -1
    exit 0

option_force_overwrite:
    force_overwrite = .true
    call shift_c_args -- skip the option
    signal parse_options -- continue parsing

option_force_update:
    force_update = .true
    call shift_c_args -- skip the option
    signal parse_options -- continue parsing

option_no_level_1:
    display_level_1 = .false
    call shift_c_args -- skip the option
    signal parse_options -- continue parsing

option_verbose:
    .local~verbose = .true
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
    .error~say("    The titles are numbered.")
    signal usage

usage:
    parse source . . script
    scriptname = .file~new(script)~name
    dotpos = scriptname~lastpos(".")
    if dotpos \== 0 then scriptname = scriptname~left(dotpos - 1)
    .error~say("Usage:")
    .error~say("    "scriptname" [-h | --help] [-fo | --force-overwrite] [-fu | --force-update] [-v | --verbose] [--] [inputname [outputname]]")
    .error~say("    where")
    .error~say("        -fo --force-overwrite  forces overwriting if the output name already exists")
    .error~say("        -fu --force-update     forces the update in case of reported errors")
    .error~say("        -v  --verbose          activates the verbose mode")
    .error~say("        -h  --help             show help")
    .error~say("        --                     indicates the end of the options")
    .error~say("        The default value for inputname is stdin.")
    .error~say("        The default value for outputname is stdout.")
    exit -1

    /*
    Order of output:
    1) The verbose messages are sent to the .traceOutput monitor (stderr).
    2) The Markdown lines are sent to the outputname stream (outputobject).
    3) The error messages are sent to the .error monitor (stderr).

    errors?     force_update    .verbose
      no             no            no        the output is updated
      no             no            yes       the verbose messages are displayed, the output is updated
      no             yes           no        the output is updated
      no             yes           yes       the verbose messages are displayed, the output is updated
      yes            no            no        the error messages are displayed
      yes            no            yes       the verbose messages are displayed, the error messages are displayed
      yes            yes           no        the output is updated
      yes            yes           yes       the verbose messages are displayed, the output is updated, the error messages are displayed
    */

abort:
    additional = condition("A")
    if additional~isa(.array) then additional = additional[1]
    if additional == "Abort" then exit -1
    raise propagate


-------------------------------------------------------------------------------
-- Setup the input stream

::routine setupInputStream
    use strict arg inputname

    if inputname~caselessEquals("STDIN") then return .input

    inputobject = .stream~new(inputname)
    status = inputobject~open("READ")
    if status \== "READY:" then signal cannot_open_inputname

    return inputobject

    cannot_open_inputname:
        .error~say("Can't open" inputname)
        .error~say(status)
        call abort


-------------------------------------------------------------------------------
-- Setup the output stream

::routine setupOutputStream
    use strict arg outputname, force_overwrite, inputobject

    if outputname~caselessEquals("STDOUT") then return .output
    if outputname~caselessEquals("STDERR") then return .error

    outputobject = .stream~new(outputname)

    if force_overwrite == .false then do
        if inputobject~qualify == outputobject~qualify then signal input_and_output_names_are_identical
        if outputobject~query("EXISTS") \== "" then signal outputfile_exists
    end

    status = outputobject~open("WRITE REPLACE")
    if status \== "READY:" then signal cannot_open_outputname

    return outputobject

    input_and_output_names_are_identical:
        .error~say("The input and output names are identical, use the -fo option to force overwriting")
        call abort

    outputfile_exists:
        .error~say("The output file already exists, use the -fo option to force overwriting")
        call abort

    cannot_open_outputname:
        .error~say("Can't open" outputobject~qualify)
        .error~say(status)
        call abort


-------------------------------------------------------------------------------
-- Transforms the Markdown stream.

::routine transform
    use strict arg inputobject, outputobject, outputname, display_level_1, force_update

    inputLines = inputobject~arrayIn("Lines")
    outputLines = .list~new

    -- If at least 2 titles at level 1 then the titles at level will be displayed
    level1TitlesCount = 0
    do line over inputLines
        level1TitlesCount += .MarkdownTransformer~isMarkdownTitle(line, 1)
    end
    if .verbose then .traceOutput~say("level1TitlesCount =" level1TitlesCount)
    if display_level_1 then display_level_1 = (level1TitlesCount >= 2)

    transformer = .MarkdownTransformer~new(display_level_1)

    lineNumber = 1
    do line over inputLines
        if .verbose then .traceOutput~say("line" lineNumber~right(.column.width) .column.separator "line in  =" line)
        if .verbose then .traceOutput~say("line" lineNumber~right(.column.width) .column.separator "          " "1234567890123456789")
        line = transformer~updateTitleNumber(line, lineNumber)
        if .verbose then .traceOutput~say("line" lineNumber~right(.column.width) .column.separator "line out =" line)
        outputLines~append(line)
        lineNumber += 1
    end
    if .verbose then do
        .traceOutput~say
        .traceOutput~say("-----------------------")
        .traceOutput~say("End of verbose messages")
        .traceOutput~say("-----------------------")
        .traceOutput~say
    end
    .traceOutput~flush

    if transformer~errors~items == 0 | force_update then do
        outputobject~arrayOut(outputLines)
        outputobject~flush
    end

    if transformer~errors~items \== 0 then do
        if \ force_update | .verbose then do
            .traceOutput~say
            .traceOutput~say("--------------")
            .traceOutput~say("Errors summary")
            .traceOutput~say("--------------")
            .traceOutput~say
            .error~arrayOut(transformer~errors)
        end
        if \ force_update then do
            .error~say
            .error~say(outputname "not updated, use the -fu option to force the update despite the errors")
        end
    end
    .error~flush

    return transformer~errors~items == 0


-------------------------------------------------------------------------------
-- Updater of Markdown title number

::class MarkdownTransformer

::constant maxLevel 6 -- only 6 title levels in Markdown

-- I use a 3-space separator after the title number, c'est mon choix.
-- ## 10.200.   This is a title
-- With Chrome, a sequence of 3 "normal" spaces is collapsed into one space in the titles.
-- Using the Unicode character No-Break Space (NBSP).
::constant nbspace "C2A0"x
::constant nbspaceCount 3


::method isMarkdownTitle class
    use strict arg line, titleLevel
    line = line~changeStr(self~nbspace, " ")

    -- A markdown title tag is made of 1..n #, followed by a space or an end-of-line
    -- titleLevel 1:    ^# ...$ or ^#$
    -- titleLevel 2:    ^## ...$ or ^##$
    -- etc.
    tag = "#"~copies(titleLevel)
    nextChar = line~subchar(titleLevel + 1)
    isMarkdownTitle = (line~pos(tag) == 1) & (nextChar == " " | nextChar == "")
    return isMarkdownTitle


::attribute hcounter -- Hierarchical counter
::attribute errors get
::attribute display_level_1 get


::method init
    expose hcounter errors display_level_1
    use strict arg display_level_1
    hcounter = .HierarchicalCounter~new(self~maxLevel, display_level_1)
    errors = .List~new


/*
Returns the line with the updated title number, if applicable;
otherwise returns the unchanged line.
*/
::method updateTitleNumber
    use strict arg line, lineNumber
    do titleLevel = 1 to self~maxLevel
        updatedLine = self~updateTitleNumber_Maybe_(line, lineNumber, titleLevel)
        if .NIL \== updatedLine then return updatedLine
    end
    if .verbose then .traceOutput~say("line" lineNumber~right(.column.width) .column.separator "is not a Markdown title")
    return line


/*
Returns the line with an updated title number
        or .NIL if the line is not a '#...' markdown title
*/
::method updateTitleNumber_Maybe_
    use strict arg line, lineNumber, titleLevel

    if \ self~class~isMarkdownTitle(line, titleLevel) then return .NIL

    -- Standardizes nbspaces
    lineUnchanged = line
    line = line~changeStr(self~nbspace, " ")

    hcounterNext = self~hcounter~next(titleLevel)
    if .verbose then .traceOutput~say("line" lineNumber~right(.column.width) .column.separator "title level" titleLevel .column.separator "next =" hcounterNext)
    --if hcounterNext == "" then return lineUnchanged

    -- Remove the markdown title tag and the title number, if any
    -- Example with title level 2:
    -- ## this is a title           --> startTitle = 4  "this is a title"
    -- 1234
    -- ## 10.200. this is a title   --> startTitle = 12 "this is a title"
    -- 123456789012
    startTitle = titleLevel + 2
    startNumber = line~verify(" ", "Nomatch", titleLevel + 2) -- 1st non-space position after the markdown title tag
    endNumber = 0
    titleNumber = ""
    if startNumber \= 0 then do
        startTitle = startNumber
        endNumber = line~pos(" ", startNumber)
        if endNumber == 0 then endNumber = line~length + 1 -- either a title number without a title text, or a title text without a title number
        if line~verify("0123456789.", "Nomatch", startNumber, endNumber - startNumber) == 0 then do
            -- We have a title number
            titleNumber = line~substr(startNumber, endNumber - startNumber)
            startTitle = line~verify(" ", "Nomatch", endNumber) -- 1st non-space position after the title number
            if startTitle == 0 then startTitle = line~length + 1 -- a title number without a title text
        end
    end
    if .verbose then .traceOutput~say("line" lineNumber~right(.column.width) .column.separator "title level" titleLevel .column.separator "startNumber =" startNumber ", endNumber =" endNumber ", startTitle =" startTitle)
    -- titleNumber can be "", either because # (no displayed counter) or because we have a title text without a title number
    self~checkTitleNumber(lineNumber, titleNumber, titleLevel)
    title = line~substr(startTitle)

    -- Transform the line, using an updated title number
    tag = "#"~copies(titleLevel)
    separator = self~nbspace~copies(self~nbspaceCount)
    line = tag || " " || hcounterNext || separator || title
    return line


::method checkTitleNumberSyntax
    /*
    either empty
    or 1. or 1.1. or 1.1.1. or 1.1.1.1. or 1.1.1.1.1. or 1.1.1.1.1.1.
    */
    use strict arg lineNumber, titleNumber
    if titleNumber == "" then return .true

    isValid = .false
    index = 1
    do while index <= titleNumber~length
        dotIndex = titleNumber~verify("0123456789", "Nomatch", index) -- first non-digit position
        if dotIndex == index then leave -- no digit
        if dotIndex == 0 then leave -- missing dot
        if titleNumber~subchar(dotIndex) \== "." then leave -- dot expected
        isValid = (dotIndex == titleNumber~length)
        if isValid then leave
        index = dotIndex + 1
    end

    if isValid then return .true

    error = "line" lineNumber~right(.column.width) .column.separator "Invalid title number:" titleNumber
    if .verbose then .traceOutput~say(error)
    self~errors~append(error)
    return .false


::method checkTitleNumber
    /*
    Pre-condition: titleNumber is well-formed.
    If 0..1 title at level 1
        Correct:
            titleLevel titleNumber
                #                          no counter
                ##          1.          or no counter
                ###         1.1.        or no counter
                ####        1.1.1.      or no counter
                #####       1.1.1.1.    or no counter
                ######      1.1.1.1.1.  or no counter
        Incorrect:
                #           1.          Level 1 or level 2?
                #           1.1.        Level 1 or level 3?
                ##          1.1.        Level 2 or level 3?
                ##          1.1.1.      Level 2 or level 4?
    If at least 2 titles at level 1
        Correct:
            titleLevel titleNumber
                #           1.              or no counter
                ##          1.1.            or no counter
                ###         1.1.1.          or no counter
                ####        1.1.1.1.        or no counter
                #####       1.1.1.1.1.      or no counter
                ######      1.1.1.1.1.1.    or no counter
        Incorrect:
                #           1.1.            Level 1 or level 2?
                #           1.1.1.          Level 1 or level 3?
                ##          1.1.1.          Level 2 or level 3?
                ##          1.1.1.1.        Level 2 or level 4?
    */
    expose display_level_1
    use strict arg lineNumber, titleNumber, titleLevel
    if titleNumber == "" then return .true
    if self~checkTitleNumberSyntax(lineNumber, titleNumber) == .false then return .false

    -- The count of dots gives the level of this title number:
    -- Titles at level 1 are displayed?     yes        no
    -- 1 dot    ==> n1.         ==>         level 1 or level 2
    -- 2 dots   ==> n1.n2.      ==>         level 2 or level 3
    -- 3 dots   ==> n1.n2.n3.   ==>         level 3 or level 4
    -- etc.
    titleNumberLevel = titleNumber~countStr(".")
    if \ display_level_1 then titleNumberLevel += 1
    if titleNumberLevel == titleLevel then return .true

    error = "line" lineNumber~right(.column.width) .column.separator "Number of '#' incorrect? got" titleLevel "'#' for a counter level" titleNumberLevel
    if .verbose then .traceOutput~say(error)
    self~errors~append(error)
    return .false


-------------------------------------------------------------------------------
-- Generator of hierarchical counters
-- The level 1 counter can be displayed or not

::class HierarchicalCounter

::attribute maxLevel get
::attribute display_level_1 get


::method init
    expose counters maxLevel display_level_1
    use strict arg maxLevel=9, display_level_1=.true
    counters = .array~new(maxLevel)~~fill(0)


::method next
    expose counters string
    use strict arg level

    if level < 1 or level > self~maxLevel then signal invalid_level

    string = "" -- invalidates the string representation
    counters[level] += 1
    -- Reset the counters at upper level (child counters of current counter)
    -- The counters at lower level are unchanged, they can be zero if you "jump" intermediate levels, c'est mon choix.
    do i = level + 1 to self~maxLevel
        counters[i] = 0
    end
    return self~toString

    invalid_level: raise syntax 88.900 array ("Invalid level:" level". Must be from 1 to" self~maxLevel)


::method toString
    expose counters display_level_1 string
    use strict arg -- none

    -- Display all counters except the first; stop at the first zero counter after a non-zero counter.
    -- With maxLevel == 9
    -- #####    "0.0.0.0.5."    counters = 0 0 0 0 5 0 0 0 0
    -- #        ""              counters = 1 0 0 0 0 0 0 0 0
    -- ##       "2."            counters = 1 2 0 0 0 0 0 0 0
    -- ###      "2.3."          counters = 1 2 3 0 0 0 0 0 0
    -- etc...

    if string \== "" then return string -- already calculated

    string = ""
    stopWhen0 = .false
    do i = 1 to self~maxLevel
        counter = counters[i]
        if counter == 0, stopWhen0 then leave
        if counter \== 0 then stopWhen0 = .true -- next 0 will be a stop
        if display_level_1 | i > 1 then string ||= counter || "." -- display the first counter only if display_level_1 is true
    end
    return string


-------------------------------------------------------------------------------
-- Helpers to manipulate the C arguments

::routine c_arg
    if .NIL == .syscargs[1] then return ""
    return .syscargs[1]


::routine shift_c_args
    .syscargs~delete(1)
    return


::routine remaining_c_args
    return .syscargs~toString("line", " ") -- concatenate all the remaining C arguments, separated by a space character.


-------------------------------------------------------------------------------
-- The missing global exit -1

::routine abort
    raise syntax 98.900 array("Abort")
