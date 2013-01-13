::requires 'string2args.cls'

::class CommonArguments public subclass Directory
::attribute argIndex    -- current arg index during parsing
::attribute args        -- array of arguments
::attribute errors


::method init
    self~errors = .List~new
    self~initEntries
    
    -- Tokenize the arguments, if needed
    use strict arg callType, arguments -- always an array
    select
        when callType == "COMMAND" & arguments~items == 1 then self~args = String2Args(arguments[1])
        when callType == "SUBROUTINE" & arguments~items == 1 & arguments[1]~isA(.array) then self~args = arguments[1]
        otherwise self~args = arguments
    end
    
    -- Use makeArray to have a non-sparse array,
    -- because omitted parameters have no corresponding index,
    -- and we ignore omitted parameters here.
    loop i=1 to self~args~items
        if self~args[i] == "" then self~args~remove(i)
    end
    self~args = self~args~makeArray
    
    if self~args~items == 0 then do
        self~help = .true
        return
    end

    -- Process the options
    self~argIndex = 1
    do while self~argIndex <= self~args~items
        option = self~args[self~argIndex]
        if option~left(1) <> "-" then leave -- not an option, assume we have reached the end of the options
        if self~parseOption(option) == .false then return
        -- Return now if help requested
        if self~help then return
    end
    self~verifyOptions
    if \self~errors~isEmpty then return

    -- Process the arguments
    self~parseArguments
    

::method initEntries
    -- Entries in the directory, no need to declare them as attributes
    self~setMethod("UNKNOWN", "return ''") -- I want '' instead of .nil when accessing an unset entry
    self~debug = .false
    self~dsssl = .false
    self~dump = .false
    self~help = .false
    self~reportlinks = .false
    self~syntdiag = .false
    self~xslt = .false


::method parseOption
    use strict arg option
    if "-debug"~caseLessEquals(option) then do 
        self~argIndex += 1
        self~debug = .true
        self~debugOption = option
        return .true
    end
    if "-dsssl"~caseLessEquals(option) then do
        self~argIndex += 1
        self~dsssl = .true
        self~dssslOption = option
        return .true
    end
    if "-dump"~caseLessEquals(option) then do
        self~argIndex += 1
        self~dump = .true
        self~dumpOption = option
        return .true
    end
    if "-help"~caseLessEquals(option) then do
        self~argIndex += 1
        self~help = .true
        self~helpOption = option
        return .true
    end
    if "-reportlinks"~caseLessEquals(option) then do
        self~argIndex += 1
        self~reportlinks = .true
        self~reportlinksOption = option
        value = self~args[self~argIndex]
        if value == .nil then value = ""
        if value == "" | value~left(1) == "-" then do
            self~errors~append("[error] Value expected for option "option)
            return .false
        end
        else do
            self~argIndex += 1
            self~reportlinksValue = value
            return .true
        end
    end
    if "-syntdiag"~caseLessEquals(option) then do
        self~argIndex += 1
        self~syntdiag = .true
        self~syntdiagOption = option
        return .true
    end
    if "-xslt"~caseLessEquals(option) then do
        self~argIndex += 1
        self~xslt = .true
        self~xsltOption = option
        return .true
    end
    self~errors~append("[error] Unknown option" option)
    return .false


::method verifyOptions
    if self~dsssl & self~xslt then self~errors~append("[error] You can't specify both "self~dssslOption" and "self~xsltOption)

    
::method parseArguments
    -- Nothing to do here, will be specialized by subclasses

