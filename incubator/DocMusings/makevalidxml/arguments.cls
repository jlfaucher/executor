::requires 'string2args.rex'

::class CommonArguments public subclass Directory
::attribute args

::method init
    self~setMethod("UNKNOWN", "return ''") -- I want '' instead of .nil when accessing an unset entry
    self~debug = .false
    self~dsssl = .false
    self~dump = .false
    self~errors = .List~new
    self~help = .false
    self~syntdiag = .false
    self~xslt = .false
    
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

::method parseOption
    use strict arg option
    select
        when "-debug"~caseLessEquals(option) then do 
            self~debug = .true
            self~debugOption = option
        end
        when "-dsssl"~caseLessEquals(option) then do
            self~dsssl = .true
            self~dssslOption = option
        end
        when "-dump"~caseLessEquals(option) then do
            self~dump = .true
            self~dumpOption = option
        end
        when "-help"~caseLessEquals(option) then do
            self~help = .true
            self~helpOption = option
        end
        when "-syntdiag"~caseLessEquals(option) then do
            self~syntdiag = .true
            self~syntdiagOption = option
        end
        when "-xslt"~caseLessEquals(option) then do
            self~xslt = .true
            self~xsltOption = option
        end
        otherwise return 0
    end
    return 1

::method verifyOptions
    self~errors~empty
    if self~dsssl & self~xslt then self~errors~append("[error] You can't specify both "self~dssslOption" and "self~xsltOption)
    return self~errors~isEmpty
