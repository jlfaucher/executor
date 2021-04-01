/****
Usage :
    tracer [-csv] [-filter] [<traceFile>]

Description :
    Convert a trace to an annotated trace.
    If no <traceFile> is specified then read from stdin.
    The annotated trace is sent to stdout.

    Use -csv to generate a CSV output.

    Use -filter to filter out the lines which are not a trace

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
    T1   A1                   >I> Routine D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\generator\coroutine.cls in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\generator\coroutine.cls
    T1   A1                   >I> Routine A_ROUTINE in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\generator\coroutine.cls
    T1   A2     V1     1*          >I> Method INIT with scope "The COROUTINE class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\generator\coroutine.cls
    T1   A2     V1     1*       44 *-* self~table = .IdentityTable~new
    T2   A0                 Error 99 running D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\trace\doit.rex line 17:  Translation error
    T2   A0                 Error 99.916:  Unrecognized directive instruction

    The classic trace (without any concurrency trace) is also supported.
    That lets generate a CSV file, more easy to analyze/filter.
    Without concurrency trace, it's not possible to get the name of the executable for each line of the CSV file.

Examples :
    (Remember : you MUST redirect stderr to stdout with 2>&1)

    Windows:
    set RXTRACE=i:3
    set RXTRACE_CONCURRENCY=on
    rexx my_traced_script.rex 2>&1 | rexx tracer -csv > out.csv

    Linux, MacOs:
    RXTRACE=i:3 RXTRACE_CONCURRENCY=on rexx my_traced_script.rex 2>&1 | rexx tracer -csv > out.csv

    rexx tracer -csv my_trace_file.txt
****/

csv = .false
filter = .false
parse arg args
do forever
    parse var args current rest
    if current~left(1) == "-" then do
        if current~caselessEquals("-csv") then csv = .true
        else if current~caselessEquals("-filter") then filter = .true
        else do
            say "[error] Invalid option : "current
            return 1
        end
        args = rest
    end
    else do
        traceFile = args
        leave
    end
end

streamIn = .stdin
traceFile = .Utility~unquoted(traceFile)
if traceFile <> "" then streamIn = .stream~new(traceFile)~~open

streamOut = .stdout
traceLineParser = .TraceLineParser~new

if csv then .TraceLineCsv~lineoutTitle(streamOut)
do while streamIn~state="READY"
    rawLine=streamIn~linein
    if streamIn~state="NOTREADY", rawLine == "" then leave
    currentTrace = traceLineParser~parse(rawLine)
    currentTrace~lineOut(streamOut, csv, filter)
end

return 0


--::options trace i

-------------------------------------------------------------------------------
::class Utility
-------------------------------------------------------------------------------

::method isHex class
    use strict arg str, length
    if str~length <> length then return .false
    return str~verify("0123456789abcdefABCDEF") == 0


::method quoted class
    -- Returns a quoted string.
    -- If the string contains a double quote character, it is escaped by placing another double quote character next to it.
    -- a"bc"d --> "a""bc""d"
    use strict arg string, quote='"'
    doubleQuote = quote || quote
    return quote || string~changeStr(quote, doubleQuote) || quote


::method unquoted class
    -- Replace escaped double quotes by a double quote, and remove leading and trailing double quotes, if any.
    -- "a""bc""d" --> a"bc"d
    use strict arg string, quote='"'
    doubleQuote = quote || quote
    if string~left(1) == quote & string~right(1) == quote then
        return string~substr(2, string~length - 2)~changeStr(doubleQuote, quote)
    else
        return string


-------------------------------------------------------------------------------
::class TraceLineParser
-------------------------------------------------------------------------------

::constant hexIdWidth64bit 16 -- width in digit count of hex id
::constant hexIdWidth32bit 8 -- width in characters of hex id

-- Specific to concurrency trace
::attribute rawLine
    ::attribute threadId
    ::attribute activationId
    ::attribute varDictId
    ::attribute reserveCount
    ::attribute lock
    -- Normal trace line, without concurrency trace
    ::attribute rawTrace
        ::attribute lineNumber
        ::attribute tracePrefix
        ::attribute restOfTrace
            ::attribute routine
            ::attribute method
            ::attribute scope
            ::attribute package


::method isHexId64bit class
    use strict arg id
    return .Utility~isHex(id, .TraceLineParser~hexIdWidth64bit) -- Ex : 0001654c0001654c


::method isHexId32bit class
    use strict arg id
    return .Utility~isHex(id, .TraceLineParser~hexIdWidth32bit) -- Ex : 0001654c


::method init
    rawLine = ""
    threadId = ""
    activationId = ""
    varDictId = ""
    reserveCount = ""
    lock = ""
    rawTrace = ""
    lineNumber = ""
    tracePrefix = ""
    restOfTrace = ""
    routine = ""
    method = ""
    scope = ""
    package = ""


::method parse64bit
    use strict arg -- none
    parse value self~rawLine with,
            1 self~threadId >(.TraceLineParser~hexIdWidth64bit),
            +1 self~activationId >(.TraceLineParser~hexIdWidth64bit),
            +1 self~varDictId >(.TraceLineParser~hexIdWidth64bit),
            +1 self~reserveCount >(.WithActivationInfo~reserveCountRawWidth) self~lock >1,
            +1 self~rawTrace
    return  .TraceLineParser~isHexId64bit(self~threadId) &,
            .TraceLineParser~isHexId64bit(self~activationId) &,
            .TraceLineParser~isHexId64bit(self~varDictId) &,
            self~reserveCount~datatype("W") &,
            (self~lock == " " | self~lock == "*")


::method parse32bit
    use strict arg -- none
    parse value self~rawLine with,
            1 self~threadId >(.TraceLineParser~hexIdWidth32bit),
            +1 self~activationId >(.TraceLineParser~hexIdWidth32bit),
            +1 self~varDictId >(.TraceLineParser~hexIdWidth32bit),
            +1 self~reserveCount >(.WithActivationInfo~reserveCountRawWidth) self~lock >1,
            +1 self~rawTrace
    return  .TraceLineParser~isHexId32bit(self~threadId) &,
            .TraceLineParser~isHexId32bit(self~activationId) &,
            .TraceLineParser~isHexId32bit(self~varDictId) &,
            self~reserveCount~datatype("W") &,
            (self~lock == " " | self~lock == "*")


::method parseHrId
    use strict arg -- none
    parse value self~rawLine with,
            1 self~threadId >(.Thread~hrIdWidth),
            +1 self~activationId >(.Activation~hrIdWidth),
            +1 self~varDictId >(.VariableDictionary~hrIdWidth),
            +1 self~reserveCount >(.WithActivationInfo~reserveCountHrWidth) self~lock >1,
            +1 self~rawTrace
    return  .Thread~isHrId(self~threadId) &,
            .Activation~isHrId(self~activationId) &,
            .VariableDictionary~isHrId(self~varDictId) &,
            (self~reserveCount~datatype("W") | self~reserveCount~strip == "") &,
            (self~lock == " " | self~lock == "*")


::method clearConcurrencyTrace
    -- The various parsings have stored some invalid values, clear them
    use strict arg -- none
    self~threadId = ""
    self~activationId = ""
    self~varDictId = ""
    self~reserveCount = ""
    self~lock = ""
    self~rawTrace = self~rawLine


::method parse
    use strict arg rawLine
    self~rawLine = rawLine
    currentTrace = .nil

    -- Several concurrency trace formats supported
    concurrencyTrace = "none"
    if self~parse64bit then concurrencyTrace = 64 -- 64-bit pointers
    else if self~parse32bit then concurrencyTrace = 32 -- 32-bit pointers
    else if self~parseHrId then concurrencyTrace = "hr" -- hr ids (parsing a trace already hr-ized)
    else self~clearConcurrencyTrace

    if self~rawTrace~pos("Error") == 1 then currentTrace = .ErrorTrace~new
    else do -- maybe normal trace line
        parse value self~rawTrace with 1 self~lineNumber >6 +1 self~tracePrefix >3 +1 self~restOfTrace
        valid = .TraceLine~isValidLineNumber(self~lineNumber) &,
                .TraceLine~isValidPrefix(self~tracePrefix)
        if \valid then do
            if concurrencyTrace == "none" then currentTrace = .UnknownFormat~new
            else currentTrace = .InvalidTrace~new
        end
        else do -- valid trace line
            if self~tracePrefix == ">I>" then do
                if self~restOfTrace~pos("Routine ") == 1 then do
                    currentTrace = .RoutineActivation~new
                    parse value self~restOfTrace with "Routine " self~routine " in package " self~package
                end
                else if self~restOfTrace~pos("Method ") == 1 then do
                    currentTrace = .MethodActivation~new
                    parse value self~restOfTrace with "Method " self~method ' with scope "' self~scope '" in package ' self~package
                end
                else currentTrace = .UnknownActivation~new
            end
            else currentTrace = .GenericTrace~new
        end
    end

    currentTrace~initializeWith(self)
    return currentTrace


-------------------------------------------------------------------------------
::class TraceLineCsv
-------------------------------------------------------------------------------
-- Helper to generate a CSV line

::constant sep ","

-- Better to have a non-empty value, otherwise filtering may not be good (depending on your favorite tool)
::constant defaultValue "."


::method lineoutTitle class
    use strict arg stream
    stream~charout("thread") ; stream~charout(self~sep)
    stream~charout("activation") ; stream~charout(self~sep)
    stream~charout("varDict") ; stream~charout(self~sep)
    stream~charout("count") ; stream~charout(self~sep)
    stream~charout("lock") ; stream~charout(self~sep)
    stream~charout("kind") ; stream~charout(self~sep)
    stream~charout("scope") ; stream~charout(self~sep)
    stream~charout("executable") ; stream~charout(self~sep)
    stream~charout("line") ; stream~charout(self~sep)
    stream~charout("prefix") ; stream~charout(self~sep)
    stream~charout("source") ; stream~charout(self~sep)
    stream~charout("package") ; stream~charout(self~sep)
    stream~charout("raw") -- ; stream~charout(self~sep)
    stream~lineout("")


::attribute threadId
::attribute activationId
::attribute varDictId
::attribute reserveCount
::attribute lock
::attribute kind -- of executable
::attribute scope -- of executable
::attribute executable
::attribute line
::attribute prefix
::attribute source
::attribute package
::attribute raw


::method init
    self~threadId = ""
    self~activationId = ""
    self~varDictId = ""
    self~reserveCount = ""
    self~lock = ""
    self~kind = ""
    self~scope = ""
    self~executable = ""
    self~line = ""
    self~prefix = ""
    self~source = ""
    self~package = ""
    self~raw = ""


::method quoted
    use strict arg value
    value = value~strip
    if value == "" then value = self~defaultValue
    return .Utility~quoted(value)


::method charout
    use strict arg stream, value
    stream~charout(self~quoted(value))
    stream~charout(self~sep)


::method lineout
    use strict arg stream
    self~charout(stream, self~threadId)
    self~charout(stream, self~activationId)
    self~charout(stream, self~varDictId)
    self~charout(stream, self~reserveCount)
    self~charout(stream, self~lock)
    self~charout(stream, self~kind)
    self~charout(stream, self~scope)
    self~charout(stream, self~executable)
    self~charout(stream, self~line)
    self~charout(stream, self~prefix)
    self~charout(stream, self~source)
    self~charout(stream, self~package)
    self~charout(stream, self~raw)
    stream~lineout("")


-------------------------------------------------------------------------------
::class Thread
-------------------------------------------------------------------------------

::constant hrIdWidth 4 -- width of hr id (used for parsing and rewriting)


-- class attributes
::attribute counter class
::attribute directory class


::method init class
    self~counter = 0
    self~directory = .directory~new


::method fromId class
    use strict arg threadId
    thread = .Thread~directory[threadId]
    if .nil == thread then do
        thread = .Thread~new
        .Thread~directory[threadId] = thread
        thread~id = threadId
        if threadId == "" then thread~hrId = ""
        else if threadId = 0 | threadId == "T0" then thread~hrId = "T0" -- Always use T0 for null pointer
        else do
            .Thread~counter += 1
            thread~hrId = "T".Thread~counter
        end
    end
    return thread


::method isHrId class
    use strict arg threadId
    return threadId~left(1) =="T" & threadId~substr(2)~dataType("W")  -- Ex : T1, T12, T123, ...


-- instance attributes
::attribute id
::attribute hrId -- Human-readable


::method init
    self~id = ""
    self~hrId = ""


-------------------------------------------------------------------------------
::class Activation
-------------------------------------------------------------------------------

::constant hrIdWidth 6 -- max width of hr id (used for parsing and rewriting)


-- class attributes
::attribute counter class
::attribute directory class


::method init class
    self~counter = 0
    self~directory = .directory~new


-- Human-readable activation id
::method fromId class
    use strict arg activationId
    activation = .Activation~directory[activationId]
    if .nil == activation then do
        activation = .Activation~new
        .Activation~directory[activationId] = activation
        activation~id = activationId
        if activationId == "" then activation~hrId = ""
        else if activationId = 0 | activationId == "A0" then activation~hrId = "A0" -- Always use A0 for null pointer
        else do
            .Activation~counter += 1
            activation~hrId = "A".Activation~counter
        end
    end
    return activation


::method isHrId class
    use strict arg activationId
    return activationId~left(1) =="A" & activationId~substr(2)~dataType("W")  -- Ex : A1, A12, A123, ...

-- instance attributes
::attribute id
::attribute hrId -- Human-readable
::attribute kind
::attribute scope
::attribute executable
::attribute package


::method init
    self~id = ""
    self~hrId = ""
    self~kind = ""
    self~scope = ""
    self~executable = ""
    self~package = ""


-------------------------------------------------------------------------------
::class VariableDictionary
-------------------------------------------------------------------------------

::constant hrIdWidth 6 -- max width of hr id (used for parsing and rewriting)


-- class attributes
::attribute counter class
::attribute directory class


::method init class
    self~counter = 0
    self~directory = .directory~new


-- Human-readable varDict id
::method fromId class
    use strict arg varDictId -- can be made of spaces, when parsing hr trace
    varDict = .VariableDictionary~directory[varDictId]
    if .nil == varDict then do
        varDict = .VariableDictionary~new
        .VariableDictionary~directory[varDictId] = varDict
        varDict~id = varDictId
        if varDictId == "" then varDict~hrId = ""
        else if varDictId = 0 | varDictId == "V0" | varDictId = "" then varDict~hrId = "V0" -- Always use V0 for null pointer
        else do
            .VariableDictionary~counter += 1
            varDict~hrId = "V".VariableDictionary~counter
        end
    end
    return varDict


::method isHrId class
    use strict arg varDictId
    if varDictId = "" then return .true -- special case, when parsing hr trace.
    return varDictId~left(1) =="V" & varDictId~substr(2)~dataType("W")  -- Ex : V1, V12, V123, ...

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
--        ErrorTrace
--        InvalidTrace
--        GenericTrace
--            RoutineActivation
--            MethodActivation
--            UnknownActivation


::method isValidLineNumber class
    use strict arg lineNumber
    return lineNumber~datatype("W") | lineNumber~strip == ""


::method isValidPrefix class
    use strict arg prefix
    -- The last "..." is not a standard trace prefix. This is the prefix used by the debug output of SysSemaphore and SysMutex.
    -- New ooRexx5: >K> <R>
    -- Collision: >N> is named argument for executor, namespace for ooRexx5
    return prefix~space(0)~length == 3 & "*-* +++ >I> >>> >=> >.> >A> >C> >E> >F> >L> >M> >N> >O> >P> >V> >K> >R> ..."~pos(prefix) <> 0


::method initializeWith
    use strict arg _traceLineParser
    return


::method lineout
    use strict arg stream, csv, filter
    if csv then do
        csv = .TraceLineCsv~new
        if self~prepareCsv(csv, filter) then csv~lineout(stream)
    end
    else do
        if self~charout(stream, filter) then stream~lineOut("")
    end


::method charout
    use strict arg stream, _filter
    return .false -- nothing displayed here


::method prepareCsv
    use strict arg _csv, _filter
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
    use strict arg stream, filter
    if filter then return .false
    forward class (super) continue
    if result == .true then stream~charout(" ")
    -- Unknown structure : print as-is
    stream~charout(self~rawLine)
    return .true


::method prepareCsv
    use strict arg csv, filter
    if filter then return .false
    forward class (super) continue
    -- Unknown structure : put all in 'raw' column
    csv~raw = self~rawLine
    return .true


-------------------------------------------------------------------------------
::class WithActivationInfo subclass TraceLine
-------------------------------------------------------------------------------

::constant reserveCountRawWidth 5 -- unsigned short : 0...65535 : 5 digits
::constant reserveCountHrWidth 2 -- in practice, I don't think we go above 99 : 2 digits


::attribute threadId
::attribute activationId
::attribute varDictId
::attribute reserveCount
::attribute lock


::method initializeWith
    use strict arg traceLineParser
    self~threadId = traceLineParser~threadId
    self~activationId = traceLineParser~activationId
    self~varDictId = traceLineParser~varDictId
    self~reserveCount = traceLineParser~reserveCount
    self~lock = traceLineParser~lock
    forward class (super)


::method noConcurrencyTrace
    return self~threadId == "",
         & self~activationId == "",
         & self~varDictId == "",
         & self~reserveCount == "",
         & self~lock == ""


::method charout
    use strict arg stream, _filter

    forward class (super) continue
    spaceNeeded = result

    if self~noConcurrencyTrace then return .false

    thread = .Thread~fromId(self~threadId)
    activation = .Activation~fromId(self~activationId)

    varDict = .VariableDictionary~fromId(self~varDictId)
    varDictHrId = varDict~hrId
    if varDictHrId == "V0" then varDictHrId = ""

    reserveCount = self~reserveCount
    if reserveCount = 0 then reserveCount = ""
    if reserveCount <> "" then reserveCount = reserveCount~format(.WithActivationInfo~reserveCountHrWidth)

    if spaceNeeded then stream~charout(" ")
    stream~charout(thread~hrId~left(.Thread~hrIdWidth),
                   activation~hrId~left(.Activation~hrIdWidth),
                   varDictHrId~left(.VariableDictionary~hrIdWidth),
                   reserveCount~left(.WithActivationInfo~reserveCountHrWidth) || self~lock)
    return .true


::method prepareCsv
    use strict arg csv, _filter
    forward class (super) continue
    if self~noConcurrencyTrace then return .false

    thread = .Thread~fromId(self~threadId)
    csv~threadId = thread~hrId

    activation = .Activation~fromId(self~activationId)
    csv~activationId = activation~hrId

    varDict = .VariableDictionary~fromId(self~varDictId)
    if varDict~hrId <> "V0" then csv~varDictId = varDict~hrId

    if self~reserveCount <> 0 then csv~reserveCount = self~reserveCount
    csv~lock = self~lock
    csv~kind = activation~kind
    csv~scope = activation~scope
    csv~executable = activation~executable
    csv~package = activation~package
    return .true


-------------------------------------------------------------------------------
::class ErrorTrace subclass WithActivationInfo
-------------------------------------------------------------------------------

::attribute rawTrace


::method initializeWith
    use strict arg traceLineParser
    self~rawTrace = traceLineParser~rawTrace
    forward class (super)


::method charout
    use strict arg stream, _filter
    forward class (super) continue
    if result == .true then stream~charout(" ")
    stream~charout(self~rawTrace)
    return .true


::method prepareCsv
    use strict arg csv, _filter
    forward class (super) continue
    csv~raw = self~rawTrace
    return .true


-------------------------------------------------------------------------------
::class InvalidTrace subclass WithActivationInfo
-------------------------------------------------------------------------------

::attribute rawTrace


::method initializeWith
    use strict arg traceLineParser
    self~rawTrace = traceLineParser~rawTrace
    forward class (super)


::method charout
    use strict arg stream, filter
    if filter then return .false
    forward class (super) continue
    if result == .true then stream~charout(" ")
    stream~charout(self~rawTrace)
    return .true


::method prepareCsv
    use strict arg csv, filter
    if filter then return .false
    forward class (super) continue
    csv~raw = self~rawTrace
    return .true


-------------------------------------------------------------------------------
::class GenericTrace subclass WithActivationInfo
-------------------------------------------------------------------------------

::attribute lineNumber
::attribute tracePrefix
::attribute restOfTrace


::method initializeWith
    use strict arg traceLineParser
    self~lineNumber = traceLineParser~lineNumber
    self~traceprefix = traceLineParser~traceprefix
    self~restOfTrace = traceLineParser~restOfTrace
    forward class (super)


::method charout
    use strict arg stream, _filter
    forward class (super) continue
    if result == .true then stream~charout(" ")
    stream~charout(self~lineNumber,
                   self~tracePrefix,
                   self~restOfTrace)
    return .true


::method prepareCsv
    use strict arg csv, _filter
    forward class (super) continue
    csv~line = self~lineNumber
    csv~prefix = self~tracePrefix
    csv~source = self~restOfTrace
    return .true


-------------------------------------------------------------------------------
::class RoutineActivation subclass GenericTrace
-------------------------------------------------------------------------------

::attribute routine
::attribute package


::method initializeWith
    use strict arg traceLineParser
    self~routine = traceLineParser~routine
    self~package = traceLineParser~package
    forward class (super) continue

    if self~noConcurrencyTrace then return

    -- Stores other infos of the activation's trace on the activation, for use in following trace lines
    activation = .Activation~fromId(self~activationId)
    activation~kind = "routine"
    activation~scope = ""
    activation~executable = self~routine
    activation~package = self~package


::method prepareCsv
    use strict arg csv, _filter
    forward class (super) continue

    csv~source = "" -- self~restOfTrace -- redundant with kind, executable, package.

    -- The superclass WithActivationInfo manages the following attributes,
    -- but only when the concurrency trace is available.
    -- Here we can store these values even when no concurrency trace (they come from >I> trace)
    -- but this is ONLY for the current trace line, not for the next trace lines.
    csv~kind = "routine"
    csv~executable = self~routine
    csv~package = self~package
    return .true


-------------------------------------------------------------------------------
::class MethodActivation subclass GenericTrace
-------------------------------------------------------------------------------

::attribute method
::attribute scope
::attribute package


::method initializeWith
    use strict arg traceLineParser
    self~method = traceLineParser~method
    self~scope = traceLineParser~scope
    self~package = traceLineParser~package
    forward class (super) continue

    -- Stores other infos of the activation's trace on the activation, for use in following trace lines
    activation = .Activation~fromId(self~activationId)
    activation~kind = "method"
    activation~scope = self~scope
    activation~executable = self~method
    activation~package = self~package


::method prepareCsv
    use strict arg csv, _filter
    forward class (super) continue

    csv~source = "" -- self~restOfTrace -- redundant with kind, scope, executable, package.

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
::class UnknownActivation subclass GenericTrace
-------------------------------------------------------------------------------

