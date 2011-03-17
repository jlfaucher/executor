/**** 
Usage :
    tracer [-csv] [-filter] [<traceFile>]

Description :
    Convert a trace to an annotated trace.
    If no <traceFile> is specified then read from stdin.
    The annotated trace is sent to stdout.

    Use -csv to generate a CSV output.

    Use -filter to filter out the lines which are not a trace

    The expected input format is something like that :
    0000f5fc 7efb0180 7eeee7a0  00000         >I> Routine D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\generator\coroutine.cls in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\generator\coroutine.cls
    0000f5fc 7efb0180 7eeee7a0  00000         >I> Routine A_ROUTINE in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\generator\coroutine.cls
    0000f5fc 7efb29f8 7eeee7a0  00001*        >I> Method INIT with scope "The COROUTINE class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\generator\coroutine.cls
    0000f5fc 7efb29f8 7eeee7a0  00001*     44 *-* self~table = .IdentityTable~new
    00010244 00000000 00000000  00000  Error 99 running D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\trace\doit.rex line 17:  Translation error
    00010244 00000000 00000000  00000  Error 99.916:  Unrecognized directive instruction

    See RexxActivity::traceOutput
    Utilities::snprintf(buffer, sizeof buffer - 1, "%8.8x %8.8x %8.8x %5.5hu%c ", 
                                                   SysCurrentThreadId(),
                                                   (unsigned int)activation,
                                                   (activation) ? activation->getVariableDictionary() : NULL,
                                                   (activation) ? activation->getReserveCount() : 0,
                                                   (activation && activation->isObjectScopeLocked()) ? '*' : ' ');

    The same format with human-readable ids is also supported :
    T1   A1                   >I> Routine D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\generator\coroutine.cls in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\generator\coroutine.cls
    T1   A1                   >I> Routine A_ROUTINE in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\generator\coroutine.cls
    T1   A2     V1     1*          >I> Method INIT with scope "The COROUTINE class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\generator\coroutine.cls
    T1   A2     V1     1*       44 *-* self~table = .IdentityTable~new
    T2   A0                 Error 99 running D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\trace\doit.rex line 17:  Translation error
    T2   A0                 Error 99.916:  Unrecognized directive instruction

Examples :
    (Remember : you MUST redirect stderr to stdout with 2>&1)
    rexx my_traced_script.rex 2>&1 | rexx tracer

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

if csv then .TraceLineCsv~lineoutTitle(streamOut)
do while streamIn~state="READY"
    rawLine=streamIn~linein
    currentTrace = .nil

    -- Try first with hex ids    
    parse var rawLine,
            1 threadId >(.Thread~hexIdWidth),
            +1 activationId >(.Activation~hexIdWidth),
            +1 varDictId >(.VariableDictionary~hexIdWidth),
            +1 reserveCount >(.WithActivationInfo~reserveCountRawWidth) lock >1,
            +1 trace
    if \.Thread~isHexId(threadId) |,
            \.Activation~isHexId(activationId) |,
            \.VariableDictionary~isHexId(varDictId) |,
            \reserveCount~datatype("N") |,
            (lock <> " " & lock <> "*") then
    do
        -- Try with hr ids (to support parsing a trace already hr-ized)
        parse var rawLine,
                1 threadId >(.Thread~hrIdWidth),
                +1 activationId >(.Activation~hrIdWidth),
                +1 varDictId >(.VariableDictionary~hrIdWidth),
                +1 reserveCount >(.WithActivationInfo~reserveCountHrWidth) lock >1,
                +1 trace
        if \.Thread~isHrId(threadId) |,
                \.Activation~isHrId(activationId) |,
                \.VariableDictionary~isHrId(varDictId) |,
                (\reserveCount~datatype("N") & reserveCount~strip <> "") |,
                (lock <> " " & lock <> "*") then currentTrace = .UnknownFormat~new
    end
    if currentTrace == .nil then do
        if trace~pos("Error") == 1 then currentTrace = .ErrorTrace~new
        else do -- normal trace line
            parse var trace 1 lineNumber >6 +1 tracePrefix >3 +1 restOfTrace
            if \.TraceLine~isValidPrefix(tracePrefix) then currentTrace = .UnknownTracePrefix~new
            else do
                if tracePrefix == ">I>" then do
                    if restOfTrace~pos("Routine ") == 1 then do
                        currentTrace = .RoutineActivation~new
                        parse var restOfTrace"Routine " currentTrace~routine " in package " currentTrace~package
                    end
                    else if restOfTrace~pos("Method ") == 1 then do
                        currentTrace = .MethodActivation~new
                        parse var restOfTrace "Method " currentTrace~method ' with scope "' currentTrace~scope '" in package ' currentTrace~package
                    end
                    else currentTrace = .UnknownActivation~new
                end
                else currentTrace = .GenericTrace~new
                currentTrace~lineNumber = lineNumber
                currentTrace~tracePrefix = tracePrefix
                currentTrace~restOfTrace = restOfTrace
            end
        end

        currentTrace~threadId = threadId~strip
        currentTrace~activationId = activationId~strip
        currentTrace~varDictId = varDictId~strip
        currentTrace~reserveCount = reserveCount~strip
        currentTrace~lock = lock
        currentTrace~trace = trace
    end
    currentTrace~rawLine = rawLine
    currentTrace~allAssigned
    currentTrace~lineOut(streamOut, csv, filter)
end

return 0


--::options trace i

-------------------------------------------------------------------------------
::class Utility

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
    self~threadId = .TraceLineCsv~defaultValue
    self~activationId = .TraceLineCsv~defaultValue
    self~varDictId = .TraceLineCsv~defaultValue
    self~reserveCount = .TraceLineCsv~defaultValue
    self~lock = .TraceLineCsv~defaultValue
    self~kind = .TraceLineCsv~defaultValue
    self~scope = .TraceLineCsv~defaultValue
    self~executable = .TraceLineCsv~defaultValue
    self~line = .TraceLineCsv~defaultValue
    self~prefix = .TraceLineCsv~defaultValue
    self~source = .TraceLineCsv~defaultValue
    self~package = .TraceLineCsv~defaultValue
    self~raw = .TraceLineCsv~defaultValue

::method lineout
    use strict arg stream
    stream~charout(.Utility~quoted(self~threadId)) ; stream~charout(self~sep)
    stream~charout(.Utility~quoted(self~activationId)) ; stream~charout(self~sep)
    stream~charout(.Utility~quoted(self~varDictId)) ; stream~charout(self~sep)
    stream~charout(.Utility~quoted(self~reserveCount)) ; stream~charout(self~sep)
    stream~charout(.Utility~quoted(self~lock)) ; stream~charout(self~sep)
    stream~charout(.Utility~quoted(self~kind)) ; stream~charout(self~sep)
    stream~charout(.Utility~quoted(self~scope)) ; stream~charout(self~sep)
    stream~charout(.Utility~quoted(self~executable)) ; stream~charout(self~sep)
    stream~charout(.Utility~quoted(self~line)) ; stream~charout(self~sep)
    stream~charout(.Utility~quoted(self~prefix)) ; stream~charout(self~sep)
    stream~charout(.Utility~quoted(self~source)) ; stream~charout(self~sep)
    stream~charout(.Utility~quoted(self~package)) ; stream~charout(self~sep)
    stream~charout(.Utility~quoted(self~raw)) -- ; stream~charout(self~sep)
    stream~lineout("")

    
-------------------------------------------------------------------------------
::class Thread
-------------------------------------------------------------------------------

::constant hexIdWidth 8 -- width of hex id (used for parsing)
::constant hrIdWidth 4 -- width of hr id (used for parsing and rewriting)

::attribute counter class
::attribute directory class

::method init class
    self~counter = 0
    self~directory = .directory~new

::method fromId class
    use strict arg threadId
    thread = .Thread~directory[threadId]
    if thread == .nil then do
        thread = .Thread~new
        .Thread~directory[threadId] = thread
        thread~id = threadId
        if threadId = 0 | threadId == "T0" then thread~hrId = "T0" -- Always use T0 for null pointer
        else do
            .Thread~counter += 1
            thread~hrId = "T".Thread~counter
        end
    end
    return thread

::method isHexId class
    use strict arg threadId
    return .Utility~isHex(threadId, .Thread~hexIdWidth) -- Ex : 0001654c
    
::method isHrId class
    use strict arg threadId
    return threadId~left(1) =="T" & threadId~substr(2)~dataType("9")  -- Ex : T1, T12, T123, ...
    
::attribute id
::attribute hrId -- Human-readable

::method init
    self~id = ""
    self~hrId = ""


-------------------------------------------------------------------------------
::class Activation
-------------------------------------------------------------------------------

::constant hexIdWidth 8 -- max width of hex id (used for parsing)
::constant hrIdWidth 6 -- max width of hr id (used for parsing and rewriting)

::attribute counter class
::attribute directory class

::method init class
    self~counter = 0
    self~directory = .directory~new

-- Human-readable activation id
::method fromId class
    use strict arg activationId
    activation = .Activation~directory[activationId]
    if activation == .nil then do
        activation = .Activation~new
        .Activation~directory[activationId] = activation
        activation~id = activationId
        if activationId = 0 | activationId == "A0" then activation~hrId = "A0" -- Always use A0 for null pointer
        else do
            .Activation~counter += 1
            activation~hrId = "A".Activation~counter
        end
    end
    return activation

::method isHexId class
    use strict arg activationId
    return .Utility~isHex(activationId, .Activation~hexIdWidth) -- Ex : 0001654c
    
::method isHrId class
    use strict arg activationId
    return activationId~left(1) =="A" & activationId~substr(2)~dataType("9")  -- Ex : A1, A12, A123, ...
    
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

::constant hexIdWidth 8 -- max width of hex id (used for parsing)
::constant hrIdWidth 6 -- max width of hr id (used for parsing and rewriting)

::attribute counter class
::attribute directory class

::method init class
    self~counter = 0
    self~directory = .directory~new

-- Human-readable varDict id
::method fromId class
    use strict arg varDictId -- can be made of spaces, when parsing hr trace
    varDict = .VariableDictionary~directory[varDictId]
    if varDict == .nil then do
        varDict = .VariableDictionary~new
        .VariableDictionary~directory[varDictId] = varDict
        varDict~id = varDictId
        if varDictId = 0 | varDictId == "V0" | varDictId = "" then varDict~hrId = "V0" -- Always use V0 for null pointer
        else do
            .VariableDictionary~counter += 1
            varDict~hrId = "V".VariableDictionary~counter
        end
    end
    return varDict

::method isHexId class
    use strict arg varDictId
    return .Utility~isHex(varDictId, .VariableDictionary~hexIdWidth) -- Ex : 0001654c
    
::method isHrId class
    use strict arg varDictId
    if varDictId = "" then return .true -- special case, when parsing hr trace.
    return varDictId~left(1) =="V" & varDictId~substr(2)~dataType("9")  -- Ex : V1, V12, V123, ...
    
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
--        UnknowTracePrefix
--        GenericTrace
--            RoutineActivation
--            MethodActivation
--            UnknownActivation


::method isValidPrefix class
    use strict arg prefix
    -- The last "..." is not a standard trace prefix. This is the prefix used by the debug output of SysSemaphore and SysMutex.
    return prefix~space(0)~length == 3 & "*-* +++ >I> >>> >=> >.> >A> >C> >E> >F> >L> >M> >O> >P> >V> ..."~pos(prefix) <> 0 

::attribute rawLine

::method init
    self~rawline = ""

::method allAssigned
    -- Called when all the attributes have been assigned a value
    return

::method lineout
    use strict arg stream, csv, filter
    if csv then do
        csv = .TraceLineCsv~new
        if self~prepareCsv(csv, filter) then csv~lineout(stream)
    end
    else do
        self~lineOutText(stream, filter)
    end

::method prepareCsv abstract

::method lineOutText abstract


-------------------------------------------------------------------------------
::class UnknownFormat subclass TraceLine
-------------------------------------------------------------------------------

::method lineoutText
    use strict arg stream, filter
    -- Unknown structure : print as-is
    if \filter then stream~lineOut(self~rawLine)

::method prepareCsv
    use strict arg csv, filter
    -- Unknown structure : put all in 'raw' column
    csv~raw = self~rawLine
    return \filter


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
::attribute trace

::method init
    self~threadId = ""
    self~activationId = ""
    self~varDictId = ""
    self~reserveCount = ""
    self~lock = ""
    self~trace = ""

::method lineoutText
    use strict arg stream, filter

    thread = .Thread~fromId(self~threadId)
    activation = .Activation~fromId(self~activationId)

    varDict = .VariableDictionary~fromId(self~varDictId)
    varDictHrId = varDict~hrId
    if varDictHrId == "V0" then varDictHrId = ""

    reserveCount = self~reserveCount
    if reserveCount = 0 then reserveCount = ""
    if reserveCount <> "" then reserveCount = reserveCount~format(.WithActivationInfo~reserveCountHrWidth) 

    stream~lineOut(thread~hrId~left(.Thread~hrIdWidth),
                   activation~hrId~left(.Activation~hrIdWidth),
                   varDictHrId~left(.VariableDictionary~hrIdWidth),
                   reserveCount~left(.WithActivationInfo~reserveCountHrWidth) || self~lock,
                   self~trace)

::method prepareCsv
    use strict arg csv, filter
    -- if \self~prepareCsv:super(csv, filter) then return .false
    thread = .Thread~fromId(self~threadId)
    activation = .Activation~fromId(self~activationId)
    varDict = .VariableDictionary~fromId(self~varDictId)
    csv~threadId = thread~hrId
    csv~activationId = activation~hrId
    if varDict~hrId <> "V0" then csv~varDictId = varDict~hrId
    if self~reserveCount <> 0 then csv~reserveCount = self~reserveCount
    csv~lock = self~lock
    csv~kind = activation~kind
    csv~scope = activation~scope
    csv~executable = activation~executable
    csv~package = activation~package
    trace off
    return .true


-------------------------------------------------------------------------------
::class ErrorTrace subclass WithActivationInfo
-------------------------------------------------------------------------------

::method lineoutText
    use strict arg stream, filter
    if \filter then self~lineoutText:super(stream, filter)

::method prepareCsv
    use strict arg csv, filter
    if \self~prepareCsv:super(csv, filter) then return .false
    csv~raw = self~trace
    return .true


-------------------------------------------------------------------------------
::class UnknownTracePrefix subclass WithActivationInfo
-------------------------------------------------------------------------------

::method lineoutText
    use strict arg stream, filter
    if \filter then self~lineoutText:super(stream, filter)

::method prepareCsv
    use strict arg csv, filter
    if \self~prepareCsv:super(csv, filter) then return .false
    csv~raw = self~trace
    return .true


-------------------------------------------------------------------------------
::class GenericTrace subclass WithActivationInfo
-------------------------------------------------------------------------------

::attribute lineNumber
::attribute tracePrefix
::attribute restOfTrace

::method init
    self~init:super
    self~lineNumber = ""
    self~traceprefix = ""
    self~restOfTrace = ""

::method prepareCsv
    use strict arg csv, filter
    if \self~prepareCsv:super(csv, filter) then return .false
    csv~line = self~lineNumber
    csv~prefix = self~tracePrefix
    csv~source = self~restOfTrace
    return .true


-------------------------------------------------------------------------------
::class RoutineActivation subclass GenericTrace
-------------------------------------------------------------------------------

::attribute routine
::attribute package

::method init
    self~init:super
    self~routine = ""
    self~package = ""

::method allAssigned
    -- Stores other infos of the activation's trace on the activation, for use in following trace lines
    use strict arg -- no arg
    self~allAssigned:super
    activation = .Activation~fromId(self~activationId)
    activation~kind = "routine"
    activation~scope = ""
    activation~executable = self~routine
    activation~package = self~package


-------------------------------------------------------------------------------
::class MethodActivation subclass GenericTrace
-------------------------------------------------------------------------------

::attribute method
::attribute scope
::attribute package

::method init
    self~init:super
    self~scope = ""
    self~package = ""

::method allAssigned
    -- Stores other infos of the activation's trace on the activation, for use in following trace lines
    use strict arg -- no arg
    self~allAssigned:super
    activation = .Activation~fromId(self~activationId)
    activation~kind = "method"
    activation~scope = self~scope
    activation~executable = self~method
    activation~package = self~package


-------------------------------------------------------------------------------
::class UnknownActivation subclass GenericTrace
-------------------------------------------------------------------------------

