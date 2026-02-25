#!/usr/bin/env rexx

-- Keep this script compatible with Executor and ooRexx5.

/****
Usage:
    tracer [-csv] [-f | -filter] [<traceFile>]
    tracer [-h | -help]
    Options for debug: [-n n] [-v | -verbose]

Description:
    MultiThreaded trace utility.
    Convert a technical MT trace to an MT trace.
    Convert an MT trace to CSV.

    If <traceFile> is not specified then read from stdin.
    The output is sent to stdout.

Options:
    -csv     to generate a CSV output.
    -filter  to filter out the lines which are not a trace.
    -n n     to stop after n input lines
    -verbose to display internal informations

Supported trace formats:
    - ooRexx5 full MT trace.
    - ooRexx5 and Executor classic trace.
    - Executor technical MT trace (32-bit and 64-bit pointers)
    - Executor human-readable MT trace.
****/

-- Keep these 2 comments blocks separated.

/****
Examples:
    (Remember: you MUST redirect stderr to stdout with 2>&1)

    rexx my_tracedScript.rex 2>&1 | rexx tracer -csv > my_traceFile.csv
    rexx tracer -csv my_traceFile.txt

Activation of MT trace:
    [ooRexx5]
    Add in source file: .TraceObject~option = "F"

    [Executor]
    Windows:        set RXTRACE_CONCURRENCY=on
    Linux, MacOs:   export RXTRACE_CONCURRENCY=on

Supported trace formats:
    [ooRexx5]

    ooRexx5 doesn't use the same widths, doesn't use the same letters as Executor.
    The column widths are DIFFERENT between "S" and "F" options.
    The position of the closing square bracket is not constant for a same option.
    The widths are small and because of that, they are not fixed.

    The parsing is robust, with fixed-size columns.
    Any anomaly will be detected, and the trace line will be considered invalid.
    An invalid trace line is not decomposed into columns for CSV export.
    The whole line will be put in the "raw" column.

    Thread MT format
            15 *-1*   say 'isTimer 1 ='SysTimer1~isTimer' isTimer 2 ='SysTimer2~isTimer'
               >K2>     "WHEN" => "0"
               <I1< Method "M2" with scope "C" in package "<path>".
             6 *-1* say 1/0
        Error 42 running <path> line 6:  Arithmetic overflow/underflow.
        Error 42.3:  Arithmetic overflow; divisor must not be zero.

    Standard MT format.
                 1         2
    pos 123456789012345678901234
  width  3   3   2  3   3   11
        [T1  I1 ]                   15 *-*   say 'isTimer 1 ='SysTimer1~isTimer' isTimer 2 ='SysTimer2~isTimer'
        [T2  I5  Ug A1  L1  *W]        >K>     "WHEN" => "0"
        [T1  I3  Gu A1  L1    ]        <I< Method "M2" with scope "C" in package "<path>".
        [T1  I1 ]                    6 *-* say 1/0
        [T1  I0 ]               Error 42 running <path> line 6:  Arithmetic overflow/underflow.
        [T1  I0 ]               Error 42.3:  Arithmetic overflow; divisor must not be zero.

    Full MT format.
    The expected input format is:
                 1         2         3
    pos 1234567890123456789012345678901234
  width  4    4    5     2  5     4    11
        [R1   T1   I1   ]                      15 *-*   say 'isTimer 1 ='SysTimer1~isTimer' isTimer 2 ='SysTimer2~isTimer'
        [R1   T2   I5    Ug A1    L1   *W]        >K>     "WHEN" => "0"
        [R1   T1   I3    Gu A1    L1     ]        <I< Method "M2" with scope "C" in package "<path>".
        [R1   T1   I1   ]                       6 *-* say 1/0
        [R1   T1   I0   ]                  Error 42 running <path> line 6:  Arithmetic overflow/underflow.
        [R1   T1   I0   ]                  Error 42.3:  Arithmetic overflow; divisor must not be zero.

    [Executor]

    The expected input format is something like that (in case of 32-bit pointers) :
        0000f5fc 7efb0180 7eeee7a0 00000         >I> Routine D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\generator\coroutine.cls in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\generator\coroutine.cls
        0000f5fc 7efb0180 7eeee7a0 00000         >I> Routine A_ROUTINE in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\generator\coroutine.cls
        0000f5fc 7efb29f8 7eeee7a0 00001*        >I> Method INIT with scope "The COROUTINE class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\generator\coroutine.cls
        0000f5fc 7efb29f8 7eeee7a0 00001*     44 *-* self~table = .IdentityTable~new
        00010244 00000000 00000000 00000  Error 99 running D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\trace\doit.rex line 17:  Translation error
        00010244 00000000 00000000 00000  Error 99.916:  Unrecognized directive instruction

    See RexxActivity::traceOutput
    Utilities::snprintf(buffer, sizeof buffer - 1, CONCURRENCY_TRACE,
                                                   Utilities::currentThreadId(),
                                                   activation,
                                                   (activation) ? activation->getVariableDictionary() : NULL,
                                                   (activation) ? activation->getReserveCount() : 0,
                                                   (activation && activation->isObjectScopeLocked()) ? '*' : ' ');

    The same format with 64-bit pointers is also supported.
    See common\Utilities.hpp
    #ifdef __REXX64__
    #define CONCURRENCY_TRACE "%16.16x %16.16x %16.16x %5.5hu%c "
    #else
    #define CONCURRENCY_TRACE "%8.8x %8.8x %8.8x %5.5hu%c "
    #endif


    The same format with human-readable ids is also supported :
  width 4    6      6      2 1
        T1   A1                         >I> Routine D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\generator\coroutine.cls in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\generator\coroutine.cls
        T1   A1                         >I> Routine A_ROUTINE in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\generator\coroutine.cls
        T1   A2     V1      1*          >I> Method INIT with scope "The COROUTINE class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\generator\coroutine.cls
        T1   A2     V1      1*       44 *-* self~table = .IdentityTable~new
        T2   A0                  Error 99 running D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\trace\doit.rex line 17:  Translation error
        T2   A0                  Error 99.916:  Unrecognized directive instruction

    [ooRexx5 and Executor]

    The classic trace (without any concurrency trace) is also supported.
    That lets generate a CSV file, more easy to analyze/filter.
    Without concurrency trace, it's not possible to get the name of the executable for each line of the CSV file.
****/

use arg args = ""

.local~verbose = .false
csv = .false
filter = .false
tracefile = ""
max_count = 999999999

do forever
    parse var args current rest
    if current~left(1) == "-" then do
        option = current~lower
        select
            when option == "-csv" then csv = .true
            when option == "--csv" then csv = .true
            when option == "-f" then filter = .true
            when option == "-filter" then filter = .true
            when option == "--filter" then filter = .true
            when option == "-h" then signal help
            when option == "-help" then signal help
            when option == "--help" then signal help
            when option == "-n" then do
                parse var rest current rest
                if \current~datatype("W") then signal count_is_not_a_number
                max_count = current
            end
            when option == "-v" then .local~verbose = .true
            when option == "-verbose" then .local~verbose = .true
            when option == "--verbose" then .local~verbose = .true
            otherwise do
                .error~say( "[error] Invalid option : "current )
                signal usage
            end
        end
    end
    else do
        traceFile = args
        leave
    end
    args = rest
end

streamIn = .stdin
traceFile = .Utility~unquoted(traceFile)
if traceFile \== "" then do
    streamIn = .stream~new(traceFile)
    status = streamIn~open("READ")
    if status \== "READY:" then signal cannot_open_traceFile
end

streamOut = .stdout
traceLineParser = .TraceLineParser~new

count = 0
if csv then .TraceLineCsv~lineoutTitle(streamOut)
do while streamIn~state == "READY"
    if count >= max_count then do
        .error~say( "STOP after" max_count "iteration." )
        leave
    end
    rawLine = streamIn~linein
    if streamIn~state == "NOTREADY", rawLine == "" then leave
    traceOutputBuffer = .StreamBuffer~new
    .traceOutput~destination(traceOutputBuffer)
    currentTrace = traceLineParser~parse(rawLine)
    currentTrace~lineOut(streamOut, traceOutputBuffer, csv, filter)
    .traceOutput~destination -- restore previous destination
    count += 1
end

return count >= max_count -- 1 if STOP, 0 otherwise (normal exit)

usage:
    call source_doc "Usage:"
    return 1

help:
    call source_doc "Usage:"
    call source_doc "Description:"
    call source_doc "Options:"
    call source_doc "Supported trace formats:"
    return 1

count_is_not_a_number:
    .error~say( "Invalid count, got" '"'current'".' )
    return 1

cannot_open_traceFile:
    .error~say( "Can't open" '"'traceFile'".' )
    .error~say( status )
    return 1


::routine source_doc
    -- The text is taken from the first /**** ... ****/ comment at the begining of the source file.
    -- If a label is specified then only the section for this label is displayed.
    -- Otherwise the whole comment is displayed.
    use strict arg label=""
    display = 0
    loop line = 1 to .context~package~sourceSize
        sourceLine = .context~package~sourceLine(line)
        if sourceLine~startsWith("****/") then leave
        if display == 2, sourceLine \== "", sourceLine[1] \== " " then leave -- not indented => new label, end of section
        if sourceLine~startsWith("/****") then display = 1
        if label \== "", sourceLine == label, display == 1 then display = 2
        if label \== "", display == 2 then .error~say(sourceLine) -- display only this section
        if label == "", display == 1 then .error~say(sourceLine) -- display all the sections
    end


-------------------------------------------------------------------------------
::class Utility
-------------------------------------------------------------------------------

::method isNULL class
    /*
    The more I hear people proudly claiming that Rexx is the most user-friendly language,
    the more I find them biased, blind, and naive!

    I want to test if a pointer is NULL:
    000000000e042000 = 0    --> TRUE    What??? Really??? Of course, I'm stupid, I have to use ==.
    000000000e042000 == 0   --> FALSE   Yeah! I'm the most intelligent programmer.
    0000000000000000 == 0   --> FALSE   What??? Really??? Of course, I'm stupid, it's a strict comparison.

    Review git log...
    In 2011, I replaced
        if threadId~verify("0") == 0
        if activationId~verify("0") == 0
    by
        if threadId = 0
        if activationId = 0
    and never noticed the regression, until today (year 2026).
    */
    use strict arg id
    return id~verify("0") == 0


::method isZero class
    -- Could use isNULL, but I prefer a distinct name when testing an integer
    use strict arg integer
    return integer~verify("0") == 0


::method isHex class
    use strict arg str, length
    if str~length \== length then return .false
    return str~verify("0123456789abcdefABCDEF") == 0


::method quoted class
    -- Returns a quoted string.
    -- If the string contains a double quote character, it is escaped by placing another double quote character next to it.
    -- a"bc"d --> "a""bc""d"
    use strict arg string, quote = '"'
    doubleQuote = quote || quote
    return quote || string~changeStr(quote, doubleQuote) || quote


::method unquoted class
    -- Replace escaped double quotes by a double quote, and remove leading and trailing double quotes, if any.
    -- "a""bc""d" --> a"bc"d
    use strict arg string, quote = '"'
    doubleQuote = quote || quote
    if string~left(1) == quote & string~right(1) == quote then
        return string~substr(2, string~length - 2)~changeStr(doubleQuote, quote)
    else
        return string


-------------------------------------------------------------------------------
::class TraceLineParser
-------------------------------------------------------------------------------

::attribute ooRexx5MTtraceWidth class get -- maximum position of ] in an MT prefix [...]
    if .ooRexx5.trace == "S" then return 23
    return 34
::attribute ooRexx5MTtraceWidth get  -- both at class and instance scope, like a constant
    return self~class~ooRexx5MTtraceWidth

::constant hexIdWidth64bit 16 -- width in hexadecimal digits of an hexadecimal identifier
::constant hexIdWidth32bit 8 -- width in hexadecimal digits of an hexadecimal identifier


::method isHexId64bit class
    use strict arg id
    return .Utility~isHex(id, self~hexIdWidth64bit) -- Ex : 0001654c0001654c


::method isHexId32bit class
    use strict arg id
    return .Utility~isHex(id, self~hexIdWidth32bit) -- Ex : 0001654c


-- Specific to concurrency trace
::attribute rawLine
    ::attribute interpreterId   -- R1   Rexx interpreter (ooRexx5)
    ::attribute threadId        -- T1
    ::attribute activationId    -- I1   Invocation
    ::attribute guard           -- G or U or Gu or Ug (ooRexx5)
    ::attribute varDictId       -- A1   Attribute pool
    ::attribute reserveCount    -- 0 (Executor) or L0 (ooRexx5)
    ::attribute lock            -- *
    ::attribute wait            -- W (ooRexx5)
    -- Classic trace line, without concurrency trace
    ::attribute rawTrace
        ::attribute lineNumber
        ::attribute tracePrefix
        ::attribute restOfTrace
            ::attribute routine
            ::attribute method
            ::attribute scope
            ::attribute package


::method init
    self~resetMTprefix
    self~resetClassicTrace


::method resetMTprefix
    use strict arg rawLine = ""
    self~rawLine = rawLine
    self~interpreterId = "" -- (ooRexx5)
    self~threadId = ""
    self~activationId = ""
    self~guard = "" -- (ooRexx5)
    self~varDictId = ""
    self~reserveCount = ""
    self~lock = ""
    self~wait = "" -- (ooRexx5)
    self~rawTrace = rawLine


::method stripTrailingMTprefix
    -- self~rawLine =       self~rawLine~strip("Trailing")
    self~interpreterId =    self~interpreterId~strip("Trailing") -- (ooRexx5)
    self~threadId =         self~threadId~strip("Trailing")
    self~activationId =     self~activationId~strip("Trailing")
    self~guard =            self~guard~strip("Trailing") -- (ooRexx5)
    self~varDictId =        self~varDictId~strip("Trailing")
    self~reserveCount =     self~reserveCount~strip("Trailing")
    self~lock =             self~lock~strip("Trailing")
    self~wait =             self~wait~strip("Trailing") -- (ooRexx5)
    -- self~rawTrace =      self~rawTrace~strip("Trailing")


::method resetClassicTrace
    self~lineNumber = ""
    self~tracePrefix = ""
    self~restOfTrace = ""
    self~routine = ""
    self~method = ""
    self~scope = ""
    self~package = ""


::method stripTrailingClassicTrace
    self~lineNumber =       self~lineNumber~strip("Trailing")
    self~tracePrefix =      self~tracePrefix~strip("Trailing")
    -- self~restOfTrace =   self~restOfTrace~strip("Trailing")
    self~routine =          self~routine~strip("Trailing")
    self~method =           self~method~strip("Trailing")
    self~scope =            self~scope~strip("Trailing")
    self~package =          self~package~strip("Trailing")


::method parse
    use strict arg rawLine

    -- ooRexx5 doesn't use the same widths, doesn't use the same letters...
    -- Must have a global variable to test.
    -- "" or "T" or "S" or "F"
    .local~ooRexx5.trace = ""

    -- Several concurrency trace formats supported
    concurrencyTrace = "none"
    if self~parseMTtraceF(rawLine) then concurrencyTrace = "F"
    else if self~parseMTtraceS(rawLine) then concurrencyTrace = "S"
    else if self~parse64bit(rawLine) then concurrencyTrace = "64" -- 64-bit pointers
    else if self~parse32bit(rawLine) then concurrencyTrace = "32" -- 32-bit pointers
    else if self~parseHrId(rawLine) then concurrencyTrace = "HR" -- HR ids (parsing a trace already hr-ized)
    else self~resetMTprefix(rawLine)

    /*
    If an MT prefix has been successfully parsed, then
        - the MT attributes have been set.
        - self~rawTrace is the part of the rawLine after the MT prefix.
    otherwise
        - the MT attributes are empty.
        - self~rawTrace is the whole rawLine.
    */

    currentTrace = .nil
    if self~rawTrace~startsWith("Error") then currentTrace = .ErrorLine~new
    else do
        classicTrace = "none"
        if .ooRexx5.trace == "" then do
            -- .ooRexx5.trace could be "T", try both
            if self~parseMTclassicTrace(self~rawTrace) then classicTrace = "withThreadId"
            else if self~parseClassicTrace(self~rawTrace) then classicTrace = "withoutThreadId"
        end
        else do
            -- .ooRexx5.trace can't be "T" because already "S" or "F"
            if self~parseClassicTrace(self~rawTrace) then classicTrace = "withoutThreadId"
        end
        if classicTrace == "none" then do
            -- not a classic trace line
            self~resetClassicTrace
            if concurrencyTrace == "none" then currentTrace = .UnknownFormat~new
            else currentTrace = .InvalidClassicTrace~new
        end
        else do
            -- classic trace line
            if self~tracePrefix~startsWith(">I") then do
                if self~restOfTrace~startsWith("Routine ") then do
                    parse value self~restOfTrace with "Routine " self~routine " in package " self~package -- "." Bad idea! Will stop at the FIRST ".", even if inside a quoted string
                    currentTrace = .RoutineActivation~new("enter")
                end
                else if self~restOfTrace~startsWith("Method ") then do
                    parse value self~restOfTrace with "Method " self~method ' with scope "' self~scope '" in package ' self~package -- "."
                    currentTrace = .MethodActivation~new("enter")
                end
                else currentTrace = .UnknownActivation~new
            end
            else if self~tracePrefix~startsWith("<I") then do
                if self~restOfTrace~startsWith("Routine ") then do
                    parse value self~restOfTrace with "Routine " self~routine " in package " self~package -- "."
                    currentTrace = .RoutineActivation~new("exit")
                end
                else if self~restOfTrace~startsWith("Method ") then do
                    parse value self~restOfTrace with "Method " self~method ' with scope "' self~scope '" in package ' self~package -- "."
                    currentTrace = .MethodActivation~new("exit")
                end
                else currentTrace = .UnknownActivation~new
            end
            else currentTrace = .ClassicTrace~new
            -- Remove the final "."
            if self~package~endsWith(".") then self~package = self~package~left(self~package~length - 1)
        end
    end

    self~stripTrailingMTprefix
    self~stripTrailingClassicTrace

    currentTrace~initializeWith(self)
    return currentTrace


::method parseMTtraceF -- ooRexx5
    use strict arg rawLine

    if .verbose then do
        .traceOutput~say( "parseMTtraceF:" )
        .traceOutput~say( "    rawLine =" '"'rawLine'"' )
    end

    if rawLine[1] \== "[" then return .false
    rawLine = rawLine~translate("  ", "[]", , 1, self~ooRexx5MTtraceWidth)

    -- MUST be set BEFORE parsing because some widths depend on it!
    .local~ooRexx5.trace = "F"

    self~resetMTprefix(rawLine)
    parse value rawLine with,
             2 self~interpreterId >(.Interpreter~hrIdWidth),
            +1 self~threadId >(.Thread~hrIdWidth),
            +1 self~activationId >(.Activation~hrIdWidth),
            +1 self~guard >(.WithActivationInfo~guardWidth),
            +1 self~varDictId >(.VariableDictionary~hrIdWidth),
            +1 self~reserveCount >(.WithActivationInfo~reserveCountHrWidth),
            +1 self~lock >(.WithActivationInfo~lockWidth) self~wait >(.WithActivationInfo~waitWidth),
            +2 self~rawTrace
    i = .Interpreter~isHrId(self~interpreterId)
    t = .Thread~isHrId(self~threadId)
    a = .Activation~isHrId(self~activationId)
    g = (self~guard[1]~verify("GU") == 0 & self~guard[2]~verify(" gu")) == 0
    v = (.VariableDictionary~isHrId(self~varDictId) | self~varDictId~strip == "")
    r = ((self~reserveCount[1] == "L" & self~reserveCount~substr(2)~datatype("W")) | self~reserveCount~strip == "")
    l = (self~lock == " " | self~lock == "*")
    w = (self~wait == " " | self~wait == "W")
    if .verbose then do
        .traceOutput~say( "    i =" i '"'self~interpreterId'"' )
        .traceOutput~say( "    t =" t '"'self~threadId'"' )
        .traceOutput~say( "    a =" a '"'self~activationId'"' )
        .traceOutput~say( "    g =" g '"'self~guard'"' )
        .traceOutput~say( "    v =" v '"'self~varDictId'"' )
        .traceOutput~say( "    r =" r '"'self~reserveCount'"' )
        .traceOutput~say( "    l =" l '"'self~lock'"' )
        .traceOutput~say( "    w =" w '"'self~wait'"' )
    end
    optionF = i & t & a & g & v & r & l & w
    if \optionF then .local~ooRexx5.trace = ""
    return optionF


::method parseMTtraceS -- ooRexx5
    use strict arg rawLine

    if .verbose then do
        .traceOutput~say( "parseMTtraceS:" )
        .traceOutput~say( "    rawLine =" '"'rawLine'"' )
    end

    if rawLine[1] \== "[" then return .false
    rawLine = rawLine~translate("  ", "[]", , 1, self~ooRexx5MTtraceWidth)

    -- MUST be set BEFORE parsing because some widths depend on it!
    .local~ooRexx5.trace = "S"

    self~resetMTprefix(rawLine)
    parse value rawLine with,
             2 self~threadId >(.Thread~hrIdWidth),
            +1 self~activationId >(.Activation~hrIdWidth),
            +1 self~guard >(.WithActivationInfo~guardWidth),
            +1 self~varDictId >(.VariableDictionary~hrIdWidth),
            +1 self~reserveCount >(.WithActivationInfo~reserveCountHrWidth),
            +1 self~lock >(.WithActivationInfo~lockWidth) self~wait >(.WithActivationInfo~waitWidth),
            +2 self~rawTrace
    t = .Thread~isHrId(self~threadId)
    a = .Activation~isHrId(self~activationId)
    g = (self~guard[1]~verify("GU") == 0 & self~guard[2]~verify(" gu")) == 0
    v = (.VariableDictionary~isHrId(self~varDictId) | self~varDictId~strip == "")
    r = ((self~reserveCount[1] == "L" & self~reserveCount~substr(2)~datatype("W")) | self~reserveCount~strip == "")
    l = (self~lock == " " | self~lock == "*")
    w = (self~wait == " " | self~wait == "W")
    if .verbose then do
        .traceOutput~say( "    t =" t '"'self~threadId'"' )
        .traceOutput~say( "    a =" a '"'self~activationId'"' )
        .traceOutput~say( "    g =" g '"'self~guard'"' )
        .traceOutput~say( "    v =" v '"'self~varDictId'"' )
        .traceOutput~say( "    r =" r '"'self~reserveCount'"' )
        .traceOutput~say( "    l =" l '"'self~lock'"' )
        .traceOutput~say( "    w =" w '"'self~wait'"' )
    end
    optionS = t & a & g & v & r & l & w
    if \optionS then .local~ooRexx5.trace = ""
    return optionS


::method parse64bit -- Executor
    use strict arg rawLine

    if .verbose then do
        .traceOutput~say( "parse64bit:" )
        .traceOutput~say( "    rawLine =" '"'rawLine'"' )
    end

    -- MUST be set BEFORE parsing because some widths depend on it!
    .local~ooRexx5.trace = ""

    self~resetMTprefix(rawLine)
    parse value rawLine with,
             1 self~threadId >(self~hexIdWidth64bit),
            +1 self~activationId >(self~hexIdWidth64bit),
            +1 self~varDictId >(self~hexIdWidth64bit),
            +1 self~reserveCount >(.WithActivationInfo~reserveCountRawWidth) self~lock >(.WithActivationInfo~lockWidth),
            +1 self~rawTrace
    t = self~class~isHexId64bit(self~threadId)
    a = self~class~isHexId64bit(self~activationId)
    v = self~class~isHexId64bit(self~varDictId)
    r = self~reserveCount~datatype("W")
    l = (self~lock == " " | self~lock == "*")
    if .verbose then do
        .traceOutput~say( "    t =" t '"'self~threadId'"' )
        .traceOutput~say( "    a =" a '"'self~activationId'"' )
        .traceOutput~say( "    v =" v '"'self~varDictId'"' )
        .traceOutput~say( "    r =" r '"'self~reserveCount'"' )
        .traceOutput~say( "    l =" l '"'self~lock'"' )
    end
    return t & a & v & r & l


::method parse32bit -- Executor
    use strict arg rawLine

    if .verbose then do
        .traceOutput~say( "parse32bit:" )
        .traceOutput~say( "    rawLine =" '"'rawLine'"' )
    end

    -- MUST be set BEFORE parsing because some widths depend on it!
    .local~ooRexx5.trace = ""

    self~resetMTprefix(rawLine)
    parse value rawLine with,
             1 self~threadId >(self~hexIdWidth32bit),
            +1 self~activationId >(self~hexIdWidth32bit),
            +1 self~varDictId >(self~hexIdWidth32bit),
            +1 self~reserveCount >(.WithActivationInfo~reserveCountRawWidth) self~lock >(.WithActivationInfo~lockWidth),
            +1 self~rawTrace
    t = self~class~isHexId32bit(self~threadId)
    a = self~class~isHexId32bit(self~activationId)
    v = self~class~isHexId32bit(self~varDictId)
    r = self~reserveCount~datatype("W")
    l = (self~lock == " " | self~lock == "*")
    if .verbose then do
        .traceOutput~say( "    t =" t '"'self~threadId'"' )
        .traceOutput~say( "    a =" a '"'self~activationId'"' )
        .traceOutput~say( "    v =" v '"'self~varDictId'"' )
        .traceOutput~say( "    r =" r '"'self~reserveCount'"' )
        .traceOutput~say( "    l =" l '"'self~lock'"' )
    end
    return t & a & v & r & l


::method parseHrId -- Executor
    use strict arg rawLine

    if .verbose then do
        .traceOutput~say( "parseHrId:" )
        .traceOutput~say( "    rawLine =" '"'rawLine'"' )
    end

    -- MUST be set BEFORE parsing because some widths depend on it!
    .local~ooRexx5.trace = ""

    self~resetMTprefix(rawLine)
    parse value rawLine with,
             1 self~threadId >(.Thread~hrIdWidth),
            +1 self~activationId >(.Activation~hrIdWidth),
            +1 self~varDictId >(.VariableDictionary~hrIdWidth),
            +1 self~reserveCount >(.WithActivationInfo~reserveCountHrWidth) self~lock >(.WithActivationInfo~lockWidth),
            +1 self~rawTrace
    t = (.Thread~isHrId(self~threadId) | self~threadId~strip == "")
    a = (.Activation~isHrId(self~activationId) | self~activationId~strip == "")
    v = (.VariableDictionary~isHrId(self~varDictId) | self~varDictId~strip == "")
    r = (self~reserveCount~datatype("W") | self~reserveCount~strip == "")
    l = (self~lock == " " | self~lock == "*")
    if .verbose then do
        .traceOutput~say( "    t =" t '"'self~threadId'"' )
        .traceOutput~say( "    a =" a '"'self~activationId'"' )
        .traceOutput~say( "    v =" v '"'self~varDictId'"' )
        .traceOutput~say( "    r =" r '"'self~reserveCount'"' )
        .traceOutput~say( "    l =" l '"'self~lock'"' )
    end
    return t & a & v & r & l


::method parseMTclassicTrace -- ooRexx5 where the trace prefix contains the thread id: >I1> or >I22>
    use strict arg rawTrace

    if .verbose then do
        .traceOutput~say( "parseMTclassicTrace:" )
        .traceOutput~say( "    rawTrace =" '"'rawTrace'"' )
    end

    -- MUST be set BEFORE parsing because some widths depend on it!
    .local~ooRexx5.trace = "T"

    self~resetClassicTrace
    parse value rawTrace with,
             1 self~lineNumber >(.ClassicTrace~lineNumberWidth),
            +1 self~tracePrefix, -- variable length >In> where n is a whole number
               self~restOfTrace
    l = .ClassicTrace~isValidLineNumber(self~lineNumber)
    results = .ClassicTrace~parseMTprefix(self~tracePrefix)
    p = (.nil \== results)
    if p then self~threadId = "T" || results[2]
    if .verbose then do
        if p then .traceOutput~say( "    parseMTprefix = [" results[1] || "," results[2] "]")
        .traceOutput~say( "    l =" l '"'self~lineNumber'"' )
        .traceOutput~say( "    p =" p '"'self~tracePrefix'"' )
    end
    T = l & p
    if \T then .local~ooRexx5.trace = ""
    return T


::method parseClassicTrace
    use strict arg rawTrace

    if .verbose then do
        .traceOutput~say( "parseClassicTrace:" )
        .traceOutput~say( "    rawTrace =" '"'rawTrace'"' )
    end

    -- .local~ooRexx5.trace = ""    -- keep it! You can have an ooRexx5 "S" or "F" option

    self~resetClassicTrace
    parse value rawTrace with,
             1 self~lineNumber >(.ClassicTrace~lineNumberWidth),
            +1 self~tracePrefix >(.ClassicTrace~tracePrefixWidth),
            +1 self~restOfTrace
    l = .ClassicTrace~isValidLineNumber(self~lineNumber)
    p = .ClassicTrace~isValidPrefix(self~tracePrefix)
    if .verbose then do
        .traceOutput~say( "    l =" l '"'self~lineNumber'"' )
        .traceOutput~say( "    p =" p '"'self~tracePrefix'"' )
    end
    return l & p


-------------------------------------------------------------------------------
::class StreamBuffer
-------------------------------------------------------------------------------
-- Helper to build a list of stream lines.
-- In this script, a StreamBuffer instance can be used instead of a Stream instance.
-- First need: defer the stream output until the whole buffer is flushed.

::method init
    expose lines lastAction append
    lines = .list~new
    lastAction = ""
    append = .true


::method append
    expose lines lastAction append
    use strict arg action, string
    if append then lines~append(.MutableBuffer~new)
    lines~lastItem~append(string)
    append = (action \== "charout") -- before the next action, append a new line
    lastAction = action


::method charout
    use strict arg string
    self~append("charout", string)


::method lineout
    use strict arg string
    self~append("lineout", string)


::method say
    use strict arg string
    self~append("say", string)


::method flush
    expose lines lastAction
    use strict arg stream, csv=.false
    supplier = lines~supplier
    do while supplier~available
        item = supplier~item -- a MutableBuffer
        if csv then do
            -- no need to test lastAction, a CSV line is always a complete line.
            csvLine = .TraceLineCsv~new
            csvLine~raw = item~string
            csvLine~lineout(stream)
            supplier~next
        end
        else do
            stream~charout(item~string)
            supplier~next
            if supplier~available then stream~lineout("") -- not the last line
            else if lastAction \== "charout" then stream~lineout("") -- last line
        end
    end


-------------------------------------------------------------------------------
::class TraceLineCsv
-------------------------------------------------------------------------------
-- Helper to generate a CSV line

::constant sep ","

-- Better to have a non-empty value, otherwise filtering may not be good (depending on your favorite tool)
::constant defaultValue "."


::method lineoutTitle class
    use strict arg stream
    stream~charout("interpreter") ; stream~charout(self~sep)
    stream~charout("thread") ; stream~charout(self~sep)
    stream~charout("activation") ; stream~charout(self~sep)
    stream~charout("guard") ; stream~charout(self~sep)
    stream~charout("varDict") ; stream~charout(self~sep)
    stream~charout("count") ; stream~charout(self~sep)
    stream~charout("lock") ; stream~charout(self~sep)
    stream~charout("wait") ; stream~charout(self~sep)
    stream~charout("kind") ; stream~charout(self~sep)
    stream~charout("scope") ; stream~charout(self~sep)
    stream~charout("executable") ; stream~charout(self~sep)
    stream~charout("line") ; stream~charout(self~sep)
    stream~charout("prefix") ; stream~charout(self~sep)
    stream~charout("trace") ; stream~charout(self~sep)
    stream~charout("package") ; stream~charout(self~sep)
    stream~charout("raw") -- ; stream~charout(self~sep)
    stream~lineout("")


::attribute interpreterId
::attribute threadId
::attribute activationId
::attribute guard
::attribute varDictId
::attribute reserveCount
::attribute lock
::attribute wait
::attribute kind -- of executable
::attribute scope -- of executable
::attribute executable
::attribute line
::attribute prefix
::attribute trace
::attribute package
::attribute raw


::method init
    self~interpreterId = ""
    self~threadId = ""
    self~activationId = ""
    self~guard = ""
    self~varDictId = ""
    self~reserveCount = ""
    self~lock = ""
    self~wait = ""
    self~kind = ""
    self~scope = ""
    self~executable = ""
    self~line = ""
    self~prefix = ""
    self~trace = ""
    self~package = ""
    self~raw = ""


::method quoted
    use strict arg value
    value = value~strip("trailing") -- must keep the leading spaces in raw
    if value == "" then value = self~defaultValue
    return .Utility~quoted(value)


::method charout
    use strict arg stream, value
    stream~charout(self~quoted(value))
    stream~charout(self~sep)


::method lineout
    use strict arg stream
    self~charout(stream, self~interpreterId)
    self~charout(stream, self~threadId)
    self~charout(stream, self~activationId)
    self~charout(stream, self~guard)
    self~charout(stream, self~varDictId)
    self~charout(stream, self~reserveCount)
    self~charout(stream, self~lock)
    self~charout(stream, self~wait)
    self~charout(stream, self~kind)
    self~charout(stream, self~scope)
    self~charout(stream, self~executable)
    self~charout(stream, self~line)
    self~charout(stream, self~prefix)
    self~charout(stream, self~trace)
    self~charout(stream, self~package)
    self~charout(stream, self~raw)
    stream~lineout("")


-------------------------------------------------------------------------------
::class Interpreter -- ooRexx5
-------------------------------------------------------------------------------

::constant hrIdWidth 4 -- width of hr id (used for parsing and rewriting)


-- class attributes
::attribute counter class
::attribute directory class


::method init class
    self~counter = 0
    self~directory = .directory~new


::method fromId class
    use strict arg interpreterId
    if .verbose then .traceOutput~charout("Interpreter~fromId")
    interpreter = self~directory[interpreterId]
    if .nil == interpreter then do
        if .verbose then .traceOutput~charout(" new")
        interpreter = self~new
        self~directory[interpreterId] = interpreter
        interpreter~id = interpreterId
        interpreter~hrId = interpreterId
        if interpreterId == "" then interpreter~hrId = ""
        -- else if .Utility~isNULL(interpreterId) | interpreterId == "R0" then interpreter~hrId = "R0" -- Always use R0 for null pointer
        else if .Utility~isNULL(interpreterId) then interpreter~hrId = "" -- Always use "" for null pointer
        else do
            -- Assign a calculated HR id only for pointers.
            -- With ooRexx5 MT trace, I can have HR sequences like 1 2 4 3 5, where 4 is out-of-order.
            -- Assigning a calculated HR id would change some ids (4 becomes 3, 3 becomes 4).
            -- Not wrong in itself, but would present many differences when comparing the original trace with the parsed trace.
            if .TraceLineParser~isHexId64bit(interpreterId) | .TraceLineParser~isHexId32bit(interpreterId) then do
                if .verbose then .traceOutput~charout(" calculated")
                self~counter += 1
                interpreter~hrId = "R" || self~counter
            end
        end
    end
    if .verbose then .traceOutput~say("" '"'interpreterId'"' "-->" '"'interpreter~hrId'"' self~counter)
    return interpreter


::method isHrId class
    use strict arg interpreterId
    return interpreterId~left(1) =="R" & interpreterId~substr(2)~dataType("W")  -- Ex : R1, R12, R123, ...


-- instance attributes
::attribute id
::attribute hrId -- Human-readable


::method init
    self~id = ""
    self~hrId = ""


-------------------------------------------------------------------------------
::class Thread
-------------------------------------------------------------------------------

::attribute hrIdWidth class get -- max width of hr id (used for parsing and rewriting)
    if .ooRexx5.trace == "S" then return 3
    return 4
::attribute hrIdWidth get  -- both at class and instance scope, like a constant
    return self~class~hrIdWidth


-- class attributes
::attribute counter class
::attribute directory class


::method init class
    self~counter = 0
    self~directory = .directory~new


::method fromId class
    use strict arg threadId
    if .verbose then .traceOutput~charout("Thread~fromId")
    thread = self~directory[threadId]
    if .nil == thread then do
        if .verbose then .traceOutput~charout(" new")
        thread = self~new
        self~directory[threadId] = thread
        thread~id = threadId
        thread~hrId = threadId
        if threadId == "" then thread~hrId = ""
        -- else if .Utility~isNULL(threadId) | threadId == "T0" then thread~hrId = "T0" -- Always use T0 for null pointer
        else if .Utility~isNULL(threadId) then thread~hrId = "" -- Always use "" for null pointer
        else do
            -- Assign a calculated HR id only for pointers.
            -- With ooRexx5 MT trace, I can have HR sequences like 1 2 4 3 5, where 4 is out-of-order.
            -- Assigning a calculated HR id would change some ids (4 becomes 3, 3 becomes 4).
            -- Not wrong in itself, but would present many differences when comparing the original trace with the parsed trace.
            if .TraceLineParser~isHexId64bit(threadId) | .TraceLineParser~isHexId32bit(threadId) then do
                if .verbose then .traceOutput~charout(" calculated")
                self~counter += 1
                thread~hrId = "T" || self~counter
            end
        end
    end
    if .verbose then .traceOutput~say("" '"'threadId'"' "-->" '"'thread~hrId'"' self~counter)
    return thread


::method isHrId class
    use strict arg threadId
    return threadId~left(1) =="T" & threadId~substr(2)~dataType("W")  -- Ex : T1, T12, T123, ...


-- instance attributes
::attribute id
::attribute hrId -- Human-readable
::attribute activationStack


::method init
    self~id = ""
    self~hrId = ""
    self~activationStack = .queue~new


-------------------------------------------------------------------------------
::class Activation
-------------------------------------------------------------------------------

::attribute letter class get
    use strict arg internal=.false
    if internal then do
        if .ooRexx5.trace \== "" then return "i" -- not applicable (for the moment)
        return "a"
    end
    else do
        if .ooRexx5.trace \== "" then return "I"
        return "A"
    end
::attribute letter get  -- both at class and instance scope, like a constant
    return self~class~letter
::attribute hrIdWidth class get -- max width of hr id (used for parsing and rewriting)
    if .ooRexx5.trace == "S" then return 3
    if .ooRexx5.trace == "F" then return 5
    return 6
::attribute hrIdWidth get  -- both at class and instance scope, like a constant
    return self~class~hrIdWidth

-- class attributes
::attribute counter class
::attribute internalCounter class
::attribute directory class


::method init class
    self~counter = 0
    self~internalCounter = 0
    self~directory = .directory~new


-- Human-readable activation id
::method fromId class
    use strict arg activationId, internal
    newHrIdMessage = ""
    if .verbose then do
        .traceOutput~charout("Activation~fromId")
        if internal then .traceOutput~charout(" internal")
    end
    activation = self~directory[activationId] -- important: the key is case-sensitive! "a1" if internal, "A1" otherwise.
    if .nil == activation then do
        if .verbose then .traceOutput~charout(" new")
        activation = self~new
        self~directory[activationId] = activation
        activation~isInternal = internal
        activation~id = activationId
        activation~hrId = activationId
        if activationId == "" then activation~hrId = ""
        -- else if .Utility~isNULL(activationId) | activationId == (self~letter || "0") then activation~hrId = (self~letter || "0") -- Always use A0 or I0 for null pointer
        else if .Utility~isNULL(activationId) then activation~hrId = "" -- Always use "" for null pointer
        else do
            -- Assign a calculated HR id only for pointers.
            -- With ooRexx5 MT trace, I can have HR sequences like 1 2 4 3 5, where 4 is out-of-order.
            -- Assigning a calculated HR id would change some ids (4 becomes 3, 3 becomes 4).
            -- Not wrong in itself, but would present many differences when comparing the original trace with the parsed trace.
            if .TraceLineParser~isHexId64bit(activationId) | .TraceLineParser~isHexId32bit(activationId) then do
                if .verbose then .traceOutput~charout(" calculated")
                if internal then do
                    self~internalCounter += 1
                    activation~hrId = self~letter(internal) || self~internalCounter
                end
                else do
                    self~counter += 1
                    activation~hrId = self~letter || self~counter
                end
            end
        end
    end
    else if activation~isInternal, \internal then do
        -- An internal activation becomes not-internal.
        -- That happens when an activation has an internal trace "..." before a normal trace.
        -- Example:
        -- 000000006fe97000 0000000032841820 0000000032823bd0 00001  ...... ... (SysSemaphore)RexxActivity::runsem.wait : after pthread_cond_wait(0x32836b50, 0x32836b80) from runsem (0x0)
        -- 000000006fe97000 0000000032841820 0000000032823bd0 00001  ...... ... (SysMutex)ActivityManager::kernelSemaphore.request : before pthread_mutex_lock(0x91a9e8) from ActivityManager::lockKernel (0x0)
        -- ...
        -- 00000000700a3000 0000000032841820 0000000032823bd0 00001         >I> Method "ADD" with scope "BUFFER" in package "/Users/Shared/local/rexx/oorexx/scripts/multithread/bug#2003/guard_when-4.rex".
        internalHrId = activation~hrId
        self~counter += 1
        activation~hrId = self~letter || self~counter
        activation~isInternal = .false
        -- Alway displayed
        newHrIdMessage = "The internal activation" '"'internalHrId'"' "became the non-internal activation" '"'activation~hrId'"'
    end
    if .verbose then .traceOutput~say("" '"'activationId'"' "-->" '"'activation~hrId'"' "internal =" internal "self~internalCounter =" self~internalCounter "self~counter =" self~counter)
    if newHrIdMessage \== "" then .traceOutput~say(newHrIdMessage) -- always displayed
    return activation


::method isHrId class
    use strict arg activationId
    isLetter = activationId~left(1) == self~letter
    isLetterInternal = activationId~left(1) == self~letter(/*internal*/ .true)
    isDataTypeW = activationId~substr(2)~dataType("W")
    return (isLetter | isLetterInternal) & isDataTypeW  -- Ex : A1, a1, A12, a12, A123, a123, ... or I1, i1, I12, i12, I123, i123, ...

-- instance attributes
::attribute isInternal
::attribute id
::attribute hrId -- Human-readable
::attribute lineNumber
::attribute kind
::attribute scope
::attribute executable
::attribute package


::method init
    self~isInternal = .false
    self~id = ""
    self~hrId = ""
    self~lineNumber = ""
    self~kind = ""
    self~scope = ""
    self~executable = ""
    self~package = ""


-------------------------------------------------------------------------------
::class VariableDictionary
-------------------------------------------------------------------------------

::attribute letter class get
    if .ooRexx5.trace \== "" then return "A"
    return "V"
::attribute letter get  -- both at class and instance scope, like a constant
    return self~class~letter
::attribute hrIdWidth class get -- max width of hr id (used for parsing and rewriting)
    if .ooRexx5.trace == "S" then return 3
    if .ooRexx5.trace == "F" then return 5
    return 6
::attribute hrIdWidth get  -- both at class and instance scope, like a constant
    return self~class~hrIdWidth


-- class attributes
::attribute counter class
::attribute directory class


::method init class
    self~counter = 0
    self~directory = .directory~new


-- Human-readable varDict id
::method fromId class
    use strict arg varDictId -- can be made of spaces, when parsing hr trace
    if .verbose then .traceOutput~charout("VariableDictionary~fromId")
    varDict = self~directory[varDictId]
    if .nil == varDict then do
        if .verbose then .traceOutput~charout(" new")
        varDict = self~new
        self~directory[varDictId] = varDict
        varDict~id = varDictId
        varDict~hrId = varDictId
        if varDictId == "" then varDict~hrId = ""
        -- else if .Utility~isNULL(varDictId) | varDictId == (self~letter || "0") | varDictId = "" then varDict~hrId = (self~letter || "0") -- Always use V0 or I0 for null pointer
        else if .Utility~isNULL(varDictId) then varDict~hrId = "" -- Always use "" for null pointer
        else do
            -- Assign a calculated HR id only for pointers.
            -- With ooRexx5 MT trace, I can have HR sequences like 1 2 4 3 5, where 4 is out-of-order.
            -- Assigning a calculated HR id would change some ids (4 becomes 3, 3 becomes 4).
            -- Not wrong in itself, but would present many differences when comparing the original trace with the parsed trace.
            if .TraceLineParser~isHexId64bit(varDictId) | .TraceLineParser~isHexId32bit(varDictId) then do
                if .verbose then .traceOutput~charout(" calculated")
                self~counter += 1
                varDict~hrId = self~letter || self~counter
            end
        end
    end
    if .verbose then .traceOutput~say("" '"'varDictId'"' "-->" '"'varDict~hrId'"' self~counter)
    return varDict


::method isHrId class
    use strict arg varDictId
    if varDictId == "" then return .true -- special case, when parsing hr trace.
    return varDictId~left(1) == self~letter & varDictId~substr(2)~dataType("W")  -- Ex : V1, V12, V123, ... or A1, A12, A123, ...

-- instance attributes
::attribute id
::attribute hrId -- Human-readable


::method init
    self~id = ""
    self~hrId = ""


-------------------------------------------------------------------------------
::class TraceLine
-------------------------------------------------------------------------------
-- TraceLine
--    UnknownFormat
--    WithActivationInfo
--        ErrorLine
--        InvalidClassicTrace
--        ClassicTrace              internal when tracePrefix == "..."
--            RoutineActivation
--            MethodActivation
--            UnknownActivation


::method initializeWith
    use strict arg _traceLineParser
    return


::method isInternal
    return .false -- will be overriden (.true when trace prefix is "...")


::method lineout
    use strict arg stream, traceOutputBuffer, csv, filter
    if csv then do
        csvLine = .TraceLineCsv~new
        somethingToprint = self~prepareCsv(csvLine, filter, self~isInternal)
        traceOutputBuffer~flush(stream, csv)
        if somethingToprint then csvLine~lineout(stream)
    end
    else do
        -- Initially, the text was printed immediately.
        -- After having to capture the traceOutput in a StreamBuffer to not
        -- pollute the CSV output, I decided to apply the same deferred printing
        -- as for CSV. The charout methods could be renamed prepareText to be
        -- aligned with CSV, but for now, I'm leaving them as they are.
        streamBuffer = .StreamBuffer~new
        somethingToprint = self~charout(streamBuffer, filter, self~isInternal)
        traceOutputBuffer~flush(stream, csv)
        if somethingToprint then do
            streamBuffer~lineout("")
            streamBuffer~flush(stream)
        end
    end


::method charout
    use strict arg stream, _filter, _internal
    return .false -- nothing displayed here


::method prepareCsv
    use strict arg _csv, _filter, _internal
    return .false -- nothing stored here


-------------------------------------------------------------------------------
::class UnknownFormat subclass TraceLine
-------------------------------------------------------------------------------

::attribute rawLine


::method initializeWith
    use strict arg traceLineParser
    self~rawLine = traceLineParser~rawline
    forward class (super)


::method charout
    use strict arg stream, filter, _internal
    if filter then return .false
    forward class (super) continue
    if result == .true then stream~charout(" ")
    -- Unknown structure : print as-is
    stream~charout(self~rawLine)
    return .true


::method prepareCsv
    use strict arg csv, filter, _internal
    if filter then return .false
    forward class (super) continue
    -- Unknown structure : put all in 'raw' column
    csv~raw = self~rawLine
    return .true


-------------------------------------------------------------------------------
::class WithActivationInfo subclass TraceLine
-------------------------------------------------------------------------------

::constant guardWidth 2
::constant reserveCountRawWidth 5 -- unsigned short : 0...65535 : 5 digits
::attribute reserveCountHrWidth class get-- in practice, I don't think we go above 99 : 2 digits
    if .ooRexx5.trace == "S" then return 3
    if .ooRexx5.trace == "F" then return 4
    return 2
::attribute reserveCountHrWidth get -- both at class and instance scope, like a constant
    return self~class~reserveCountHrWidth
::constant lockWidth 1
::constant waitWidth 1

::attribute interpreterId
::attribute threadId
::attribute activationId
::attribute guard
::attribute varDictId
::attribute reserveCount
::attribute lock
::attribute wait


::method initializeWith
    use strict arg traceLineParser
    self~interpreterId = traceLineParser~interpreterId
    self~threadId = traceLineParser~threadId
    self~activationId = traceLineParser~activationId
    self~guard = traceLineParser~guard
    self~varDictId = traceLineParser~varDictId
    self~reserveCount = traceLineParser~reserveCount
    self~lock = traceLineParser~lock
    self~wait = traceLineParser~wait
    forward class (super)


::method noConcurrencyTrace
    if .verbose then do
        .traceOutput~say("noConcurrencyTrace:")
        .traceOutput~say("    .ooRexx5.trace =" '"'.ooRexx5.trace'"')
    end
    if .verbose then do
        .traceOutput~say("    self~interpreterId =" '"'self~interpreterId'"')
        .traceOutput~say("    self~threadId =" '"'self~threadId'"')
        .traceOutput~say("    self~activationId =" '"'self~activationId'"')
        .traceOutput~say("    self~guard =" '"'self~guard'"')
        .traceOutput~say("    self~varDictId =" '"'self~varDictId'"')
        .traceOutput~say("    self~reserveCount =" '"'self~reserveCount'"')
        .traceOutput~say("    self~lock =" '"'self~lock'"')
        .traceOutput~say("    self~wait =" '"'self~wait'"')
    end
    noConcurrencyTrace =,
          self~interpreterId == "",
        & self~threadId == "",
        & self~activationId == "",
        & self~guard == "",
        & self~varDictId == "",
        & self~reserveCount == "",
        & self~lock == "",
        & self~wait == ""
    if .verbose then .traceOutput~say("    --> noConcurrencyTrace =" noConcurrencyTrace)
    return noConcurrencyTrace

::method charout
    use strict arg stream, _filter, internal

    forward class (super) continue
    spaceNeeded = result

    if self~noConcurrencyTrace then return .false
    if .ooRexx5.trace == "T" then return .false -- no [...] MT prefix

    interpreter = .Interpreter~fromId(self~interpreterId)
    thread = .Thread~fromId(self~threadId)
    activation = .Activation~fromId(self~activationId, internal)

    varDict = .VariableDictionary~fromId(self~varDictId)
    varDictHrId = varDict~hrId
    if varDictHrId == (.VariableDictionary~letter || "0") then varDictHrId = ""

    reserveCount = self~reserveCount
    if .ooRexx5.trace \== "" then do
        if reserveCount == "L0" then nop -- reserveCount = "" -- must keep L0 to reduce the differences
    end
    else do
        if .Utility~isZero(reserveCount) then reserveCount = ""
        if reserveCount \== "" then reserveCount = reserveCount~format(self~reserveCountHrWidth)
    end

    if spaceNeeded then stream~charout(" ")

    if .ooRexx5.trace == "F" then do
        ITA =,
            interpreter~hrId~left(.Interpreter~hrIdWidth),
            thread~hrId~left(.Thread~hrIdWidth),
            activation~hrId~left(.Activation~hrIdWidth)
        GVRLW =,
            self~guard~left(self~guardWidth),
            varDictHrId~left(.VariableDictionary~hrIdWidth),
            reserveCount~left(self~reserveCountHrWidth), -- yes, ~left because Lnn
            self~lock~left(self~lockWidth) || self~wait~left(self~waitWidth)
        if GVRLW~strip == "" then stream~charout("[" || ITA || "]" GVRLW)
                             else stream~charout("[" || ITA GVRLW || "]")
        return .true
    end
    else if .ooRexx5.trace == "S" then do
        TA =,
            thread~hrId~left(.Thread~hrIdWidth),
            activation~hrId~left(.Activation~hrIdWidth)
        GVRLW =,
            self~guard~left(self~guardWidth),
            varDictHrId~left(.VariableDictionary~hrIdWidth),
            reserveCount~left(self~reserveCountHrWidth), -- yes, ~left because Lnn
            self~lock~left(self~lockWidth) || self~wait~left(self~waitWidth)
        if GVRLW~strip == "" then stream~charout("[" || TA || "]" GVRLW)
                             else stream~charout("[" || TA GVRLW || "]")
        return .true
    end
    else do
        -- ooRexx5 "T" or Executor
        TAVRL =,
            thread~hrId~left(.Thread~hrIdWidth),
            activation~hrId~left(.Activation~hrIdWidth),
            varDictHrId~left(.VariableDictionary~hrIdWidth),
            reserveCount~right(self~reserveCountHrWidth) || self~lock~left(self~lockWidth)
        stream~charout(TAVRL)
        return .true
    end
    return .false


::method prepareCsv
    use strict arg csv, _filter, internal
    forward class (super) continue
    if self~noConcurrencyTrace then return .false

    interpreter = .Interpreter~fromId(self~interpreterId)
    csv~interpreterId = interpreter~hrId

    thread = .Thread~fromId(self~threadId)
    csv~threadId = thread~hrId

    activation = .Activation~fromId(self~activationId, internal)
    csv~activationId = activation~hrId

    csv~guard = self~guard

    varDict = .VariableDictionary~fromId(self~varDictId)
    if varDict~hrId \== (.VariableDictionary~letter || "0") then csv~varDictId = varDict~hrId

    if \.Utility~isZero(self~reserveCount) & self~reserveCount \== "L0" then csv~reserveCount = self~reserveCount
    csv~lock = self~lock
    csv~wait = self~wait

    -- With ooRexx5 option "T", there is no activationId, but there is a threadId.
    if self~activationId == "", self~threadId \== "" then do
        if \thread~activationStack~isEmpty then do
            activation = thread~activationStack~peek
        end
    end
    csv~kind = activation~kind
    csv~scope = activation~scope
    csv~executable = activation~executable
    csv~package = activation~package

    return .true


-------------------------------------------------------------------------------
::class ErrorLine subclass WithActivationInfo
-------------------------------------------------------------------------------

::attribute rawTrace


::method initializeWith
    use strict arg traceLineParser
    self~rawTrace = traceLineParser~rawTrace
    forward class (super)


::method charout
    use strict arg stream, _filter, _internal
    forward class (super) continue
    if result == .true then stream~charout(" ")
    stream~charout(self~rawTrace)
    return .true


::method prepareCsv
    use strict arg csv, _filter, _internal
    forward class (super) continue
    csv~raw = self~rawTrace
    return .true


-------------------------------------------------------------------------------
::class InvalidClassicTrace subclass WithActivationInfo
-------------------------------------------------------------------------------

::attribute rawTrace


::method initializeWith
    use strict arg traceLineParser
    self~rawTrace = traceLineParser~rawTrace
    forward class (super)


::method charout
    use strict arg stream, filter, _internal
    if filter then return .false
    forward class (super) continue
    if result == .true then stream~charout(" ")
    stream~charout(self~rawTrace)
    return .true


::method prepareCsv
    use strict arg csv, filter, _internal
    if filter then return .false
    forward class (super) continue
    csv~raw = self~rawTrace
    return .true


-------------------------------------------------------------------------------
::class ClassicTrace subclass WithActivationInfo
-------------------------------------------------------------------------------

::constant lineNumberWidth 6
::constant tracePrefixWidth 3

::method isValidLineNumber class
    use strict arg lineNumber
    if lineNumber~datatype("W") then return .true
    if lineNumber~strip == "" then return .true
    if lineNumber == "......" then return .true -- used by the debug output of SysSemaphore and SysMutex
    return .false


::method parseMTprefix class -- ooRexx5
    use strict arg prefix
    -- >I1> or >I31> or >I250> etc.
    if prefix~length < 4 then return .nil
    part1 = prefix~left(2)
    threadId = prefix~substr(3, prefix~length - 3)
    part2 = prefix~right(1)
    prefix = part1 || part2
    if \self~isValidPrefix(prefix) then return .nil
    if \threadId~verify("0123456789") == 0 then return .nil
    return prefix, threadId


::method isValidPrefix class
    use strict arg prefix
    -- The last "..." is not a standard trace prefix. This is the prefix used by the debug output of SysSemaphore and SysMutex.
    -- New ooRexx5: >K> <R> <I<
    -- Collision: >N> is named argument for executor, namespace for ooRexx5
    return prefix~space(0)~length == 3 & "*-* +++ >I> <I< >K> >>> >=> >.> >A> >C> >E> >F> >L> >M> >N> >O> >P> >R> >V> ..."~pos(prefix) \== 0


::attribute lineNumber
::attribute tracePrefix
::attribute restOfTrace


::method initializeWith
    use strict arg traceLineParser
    self~lineNumber = traceLineParser~lineNumber
    self~traceprefix = traceLineParser~traceprefix
    self~restOfTrace = traceLineParser~restOfTrace
    forward class (super)


::method isInternal
    return self~tracePrefix == "..."


::method charout
    use strict arg stream, _filter, _internal
    forward class (super) continue
    if result == .true then stream~charout(" ")
    if .ooRexx5.trace == "T" then do
        LTR =,
            self~lineNumber~right(self~lineNumberWidth),
            self~tracePrefix, -- variable length
            self~restOfTrace
        stream~charout(LTR)
    end
    else do
        LTR =,
            self~lineNumber~right(self~lineNumberWidth),
            self~tracePrefix~left(self~tracePrefixWidth),
            self~restOfTrace
        stream~charout(LTR)
    end
    return .true


::method prepareCsv
    use strict arg csv, _filter, internal
    forward class (super) continue

    activation = .Activation~fromId(self~activationId, internal)
    -- With ooRexx5 option "T", there is no activationId, but there is a threadId.
    -- That can also happen with Executor, whith the debug output of SysSemaphore and SysMutex.
    if self~activationId == "", self~threadId \== "" then do
        thread = .Thread~fromId(self~threadId)
        if \thread~activationStack~isEmpty then do
            activation = thread~activationStack~peek
        end
    end
    -- The test self~lineNumber~datatype("W") is used to ignore the line numbers like "......" coming from the debug output of SysSemaphore and SysMutex
    if self~lineNumber \== "", self~lineNumber~datatype("W") then activation~lineNumber = self~lineNumber -- will be used for the next trace lines, if they have no line number.
    csv~line = activation~lineNumber

    csv~prefix = self~tracePrefix
    csv~trace = self~restOfTrace
    return .true


-------------------------------------------------------------------------------
::class RoutineActivation subclass ClassicTrace
-------------------------------------------------------------------------------

::attribute action -- "enter" or "exit"
::attribute routine
::attribute package

::method init
    use strict arg action
    self~action = action


::method initializeWith
    use strict arg traceLineParser
    self~routine = traceLineParser~routine
    self~package = traceLineParser~package
    forward class (super) continue
    if self~action == "enter" then self~enter
    if self~action == "exit" then self~exit


::method enter
    if self~activationId \== "" then do
        -- Stores other infos of the activation's trace on the activation, for use in following trace lines
        activation = .Activation~fromId(self~activationId, /*internal*/ .false)
        activation~kind = "routine"
        activation~scope = ""
        activation~executable = self~routine
        activation~package = self~package
    end
    else if self~threadId \== "" then do
        activationId = self~interpreterId || "#" || self~threadId || "#" || self~package || "#" || self~routine
        activation = .Activation~fromId(activationId, /*internal*/ .false)
        activation~kind = "routine"
        activation~scope = ""
        activation~executable = self~routine
        activation~package = self~package
        thread = .Thread~fromId(self~threadId)
        thread~activationStack~push(activation)
    end


::method exit
    if self~activationId == "" & self~threadId \== "" then do
        thread = .Thread~fromId(self~threadId)
        activation = thread~activationStack~pull
    end


::method prepareCsv
    use strict arg csv, _filter, _internal
    forward class (super) continue

    csv~trace = "" -- self~restOfTrace -- redundant with kind, executable, package.

    -- The superclass WithActivationInfo manages the following attributes,
    -- but only when the concurrency trace is available.
    -- Here we can store these values even when no concurrency trace (they come from >I> trace)
    -- but this is ONLY for the current trace line, not for the next trace lines.
    csv~kind = "routine"
    csv~scope = ""
    csv~executable = self~routine
    csv~package = self~package
    return .true


-------------------------------------------------------------------------------
::class MethodActivation subclass ClassicTrace
-------------------------------------------------------------------------------

::attribute action -- "enter" or "exit"
::attribute method
::attribute scope
::attribute package


::method init
    use strict arg action
    self~action = action


::method initializeWith
    use strict arg traceLineParser
    self~method = traceLineParser~method
    self~scope = traceLineParser~scope
    self~package = traceLineParser~package
    forward class (super) continue
    if self~action == "enter" then self~enter
    if self~action == "exit" then self~exit


::method enter
    if self~activationId \== "" then do
        -- Stores other infos of the activation's trace on the activation, for use in following trace lines
        activation = .Activation~fromId(self~activationId, /*internal*/ .false)
        activation~kind = "method"
        activation~scope = self~scope
        activation~executable = self~method
        activation~package = self~package
    end
    else if self~threadId \== "" then do
        activationId = self~interpreterId || "#" || self~threadId || "#" || self~package || "#" || self~scope || "#" || self~method
        activation = .Activation~fromId(activationId, /*internal*/ .false)
        activation~lineNumber = "."
        activation~kind = "method"
        activation~scope = self~scope
        activation~executable = self~method
        activation~package = self~package
        thread = .Thread~fromId(self~threadId)
        thread~activationStack~push(activation)
    end


::method exit
    if self~activationId == "" & self~threadId \== "" then do
        thread = .Thread~fromId(self~threadId)
        activation = thread~activationStack~pull
    end


::method prepareCsv
    use strict arg csv, _filter, _internal
    forward class (super) continue

    csv~trace = "" -- self~restOfTrace -- redundant with kind, scope, executable, package.

    -- The superclass WithActivationInfo manages the following attributes,
    -- but only when the concurrency trace is available.
    -- Here we can store these values even when no concurrency trace (they come from >I> trace)
    -- but this is ONLY for the current trace line, not for the next trace lines.
    csv~kind = "method"
    csv~scope = self~scope
    csv~executable = self~method
    csv~package = self~package
    return .true


-------------------------------------------------------------------------------
::class UnknownActivation subclass ClassicTrace
-------------------------------------------------------------------------------


--::options novalue syntax
--::options trace i
