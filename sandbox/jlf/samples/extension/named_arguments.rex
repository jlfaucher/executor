/*
Named arguments
*/

-------------------
-- Instruction CALL
-------------------
call title "Call an internal procedure"
call interpret 'call myprocedure'
call interpret 'call myprocedure 1, 2, 3'
call interpret 'call myprocedure 1, 2, a3:3'
call interpret 'call myprocedure 1, a2:2, a3:3'
call interpret 'call myprocedure 1, a2:(2*5/4)**5, a3:.array~new(3,3)'
call interpret 'call myprocedure , , 3, ,'
call interpret 'call myprocedure , , 3, , a5:5'
---
call interpret 'call myprocedure 1, 2, 3, {}'
call interpret 'call myprocedure 1, 2, {}, a3:3'
call interpret 'call myprocedure 1, {}, a2:2, a3:3'

-------------------------------------
-- Instruction CALL with continuation
-------------------------------------
call title "Continuation of the interpreted string"
call interpret 'call myprocedure 1,',
               'a2:2, a3:3'
call interpret 'call myprocedure 1, a2',
               ':2, a3:3'
call interpret 'call myprocedure 1, a2:',
               '2, a3:3'
call interpret 'call myprocedure 1, a2:2,',
               'a3:3'

-------------------------------------
-- Instruction CALL with continuation
-------------------------------------
call title "Continuation of the CALL instruction"
say "call myprocedure 1,,"
say "     a2:2, a3:3"
call myprocedure 1,,
     a2:2, a3:3
say
say
say "call myprocedure 1, a2,"
say "     :2, a3:3"
call myprocedure 1, a2,
     :2, a3:3
say
say
say "call myprocedure 1, a2:,"
say "     2, a3:3"
call myprocedure 1, a2:,
     2, a3:3
say
say
say "call myprocedure 1, a2:2,,"
say "     a3:3"
call myprocedure 1, a2:2,,
     a3:3
say
say

----------------
-- Function call
----------------
call title "Call an internal procedure as a function"
call interpret 'r = myprocedure()'
call interpret 'r = myprocedure(1, 2, 3)'
call interpret 'r = myprocedure(1, 2, a3:3)'
call interpret 'r = myprocedure(1, a2:2, a3:3)'
call interpret 'r = myprocedure(1, a2:(2*5/4)**5, a3:.array~new(3,3))'
call interpret 'r = myprocedure( , , 3, ,)'
call interpret 'r = myprocedure( , , 3, , a5:5)'
---
call interpret 'r = myprocedure(1, 2, 3){}'
call interpret 'r = myprocedure(1, 2, a3:3){}'
call interpret 'r = myprocedure(1, a2:2, a3:3){}'

----------------------------------
-- Function call with continuation
----------------------------------
call title "Continuation of the interpreted string"
call interpret 'r=myprocedure(1,',
               'a2:2, a3:3)'
call interpret 'r = myprocedure(1, a2',
               ':2, a3:3)'
call interpret 'r = myprocedure(1, a2:',
               '2, a3:3)'
call interpret 'r = myprocedure(1, a2:2,',
               'a3:3)'

----------------------------------
-- Function call with continuation
----------------------------------
call title "Continuation of the function call"
say "r = myprocedure(1,,"
say "     a2:2, a3:3)"
r = myprocedure(1,,
     a2:2, a3:3)
say
say
say "r = myprocedure(1, a2,"
say "     :2, a3:3)"
r = myprocedure(1, a2,
     :2, a3:3)
say
say
say "r = myprocedure(1, a2:,"
say "     2, a3:3)"
r = myprocedure(1, a2:,
     2, a3:3)
say
say
say "r = myprocedure(1, a2:2,,"
say "     a3:3)"
r = myprocedure(1, a2:2,,
     a3:3)
say
say

-------------------
-- Instruction CALL
-------------------
call title "Call a routine"
call interpret 'call myroutine'
call interpret 'call myroutine 1, 2, 3'
call interpret 'call myroutine 1, 2, a3:3'
call interpret 'call myroutine 1, a2:2, a3:3'
call interpret 'call myroutine 1, a2:(2*5/4)**5, a3:.array~new(3,3)'
call interpret 'call myroutine , , 3, ,'
call interpret 'call myroutine , , 3, , a5:5'

-----------
-- Function
-----------
call title "Call a routine as a function"
call interpret 'r = myroutine()'
call interpret 'r = myroutine(1, 2, 3)'
call interpret 'r = myroutine(1, 2, a3:3)'
call interpret 'r = myroutine(1, a2:2, a3:3)'
call interpret 'r = myroutine(1, a2:(2*5/4)**5, a3:.array~new(3,3))'
call interpret 'r = myroutine( , , 3, ,)'
call interpret 'r = myroutine( , , 3, , a5:5)'
call interpret 'r = myroutine(1, 2, 3){}'
call interpret 'r = myroutine(1, 2, a3:3){}'
call interpret 'r = myroutine(1, a2:2, a3:3){}'

---------------
-- Message term
---------------
call title "Call a method using a message term"
call interpret 'r = .myclass~mymethod'
call interpret 'r = .myclass~mymethod()'
call interpret 'r = .myclass~mymethod(1, 2, 3)'
call interpret 'r = .myclass~mymethod(1, 2, a3:3)'
call interpret 'r = .myclass~mymethod(1, a2:2, a3:3)'
call interpret 'r = .myclass~mymethod(1, a2:(2*5/4)**5, a3:.array~new(3,3))'
call interpret 'r = .myclass~mymethod( , , 3, ,)'
call interpret 'r = .myclass~mymethod( , , 3, , a5:5)'
call interpret 'r = .myclass~mymethod(1, 2, 3){}'
call interpret 'r = .myclass~mymethod(1, 2, a3:3){}'
call interpret 'r = .myclass~mymethod(1, a2:2, a3:3){}'

----------------------
-- Instruction FORWARD
----------------------
call title "Forward a message"
call interpret 'r = .myclass~forwardArray'
call interpret 'r = .myclass~forwardNamedArguments'
call interpret 'r = .myclass~forwardPositionalNamedArguments'
call interpret 'r = .myclass~forwardNamedPositionalArguments'

------------------
-- Instruction USE
------------------
call title "Instruction USE"
call interpret 'call usePositionalNamed 1, , 3, , a5:5, a6:6'
call interpret 'call useStrictPositionalNamed 1, , 3, , a5:5, a6:6'
call interpret 'call useNamed_SimpleSymbol v1:1, v3:3, v5:5'
call interpret 'call useAutoNamed_SimpleSymbol v1:1, v3:3, v5:5'
call interpret 'call useNamed_Stem_CompoundSymbol stem.v1:1, stem.:0, stem.v3:3, stem.v5:5'
call interpret 'call useAutoNamed_Stem_CompoundSymbol stem.v1:1, stem.:0, stem.v3:3, stem.v5:5' -
             , 'The automatic variables stem.v3 and stem.v5 should be created (TODO)'


-----------------
-- UNKNOWN method
-----------------
call title "Unknown method"
call interpret 'r = .myclass~foo'
call interpret 'r = .myclass~foo()'
call interpret 'r = .myclass~foo(1, 2, 3)'
call interpret 'r = .myclass~foo(1, 2, a3:3)'
call interpret 'r = .myclass~foo(1, a2:2, a3:3)'
call interpret 'r = .myclass~foo(1, a2:(2*5/4)**5, a3:.array~new(3,3))'
call interpret 'r = .myclass~foo( , , 3, ,)'
call interpret 'r = .myclass~foo( , , 3, , a5:5)'
call interpret 'r = .myclass~foo(1, 2, 3){}'
call interpret 'r = .myclass~foo(1, 2, a3:3){}'
call interpret 'r = .myclass~foo(1, a2:2, a3:3){}'

--------------
-- Message~new
--------------
-- todo...

-------------------------
-- Message~namedArguments
-------------------------
-- todo...

-----------------------------
-- Object~run floating method
-----------------------------
call title "Run a floating method"
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"])'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "I")'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "I", 1, 2, 3)'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "I", 1, 2, a3:3)'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "I", 1, a2:2, a3:3)'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "I", 1, a2:(2*5/4)**5, a3:.array~new(3,3))'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "I", , , 3, ,)'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "I", , , 3, , a5:5)'
---
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "I", 1, 2, 3){}'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "I", 1, 2, a3:3){}'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "I", 1, a2:2, a3:3){}'
---
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "A", .array~new)'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "A", (1, 2, 3))'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "A", (1, 2), "D", .directory~of(a3:3))'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "A", .array~of(1), "D", .directory~of(a2:2, a3:3))'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "A", .array~of(1), "D", .directory~of(a2:(2*5/4)**5, a3:.array~new(3,3)))'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "A", ( , , 3, ,))'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "A", ( , , 3, ,), "D", .directory~of(a5:5))'

------------------
-- Object~SendWith
------------------
call title "Call a method using sendWith"
call interpret 'r = .myclass~sendWith("mymethod", .array~new)'
call interpret 'r = .myclass~sendWith("mymethod", (1, 2, 3))'
call interpret 'r = .myclass~sendWith("mymethod", (1, 2), namedArguments:.directory~of(a3:3))'
call interpret 'r = .myclass~sendWith("mymethod", .array~of(1), namedArguments:.directory~of(a2:2, a3:3))'
call interpret 'r = .myclass~sendWith("mymethod", .array~of(1), namedArguments:.directory~of(a2:(2*5/4)**5, a3:.array~new(3,3)))'
call interpret 'r = .myclass~sendWith("mymethod", ( , , 3, ,))'
call interpret 'r = .myclass~sendWith("mymethod", ( , , 3, ,), namedArguments:.directory~of(a5:5))'
---
call interpret 'r = .myclass~sendWith("mymethod", (1, 2, 3, {}))'
call interpret 'r = .myclass~sendWith("mymethod", (1, 2, {}), namedArguments:.directory~of(a3:3))'
call interpret 'r = .myclass~sendWith("mymethod", (1, {}), namedArguments:.directory~of(a2:2, a3:3))'

-------------------
-- Object~startWith
-------------------
-- todo...

-------------------
-- Routine~callWith
-------------------
-- todo...

---------------------
-- Context~namedArgs=
---------------------
-- todo...

---------------------------
-- StackFrame~nameArguments
---------------------------
-- todo...

------------------------
-- Security manager CALL
------------------------
-- todo...

--------------------------
-- Security manager METHOD
--------------------------
-- todo...

--------
-- Block
--------
call title "Call a block"
call interpret '{call sayArg .context}~rawExecutable~call'
call interpret '{call sayArg .context}~rawExecutable~call()'
call interpret '{call sayArg .context}~rawExecutable~call(1, 2, 3)'
call interpret '{call sayArg .context}~rawExecutable~call(1, 2, a3:3)'
call interpret '{call sayArg .context}~rawExecutable~call(1, a2:2, a3:3)'
call interpret '{call sayArg .context}~rawExecutable~call(1, a2:(2*5/4)**5, a3:.array~new(3,3))'
call interpret '{call sayArg .context}~rawExecutable~call( , , 3, ,)'
call interpret '{call sayArg .context}~rawExecutable~call( , , 3, , a5:5)'
---
call interpret '{call sayArg .context}~rawExecutable~call(1, 2, 3){}'
call interpret '{call sayArg .context}~rawExecutable~call(1, 2, a3:3){}'
call interpret '{call sayArg .context}~rawExecutable~call(1, a2:2, a3:3){}'

--------------------------
-- Trapped expected errors
--------------------------
call title "Trapped expected errors"

-- no error, should raise an error
call interpret 'call myprocedure , , 3, , a5:5,' -
             , 'Should raise an error because of the trailing comma (TODO)'
call interpret 'call myroutine , , 3, , a5:5,' -
             , 'Should raise an error because of the trailing comma (TODO)'
call interpret 'call myprocedure .envSymbol:1' -
             , 'Should raise an error because an environment symbol is not allowed (TODO)'

-- call with named arguments
call interpret 'call myprocedure 1, a2:2, a3:' -
             , 'Error 35.900:  Named argument: expected expression after colon'
call interpret 'call myprocedure 1, a2:2, 3' -
             , 'Error 35.900:  Named argument: expected symbol followed by colon'
call interpret 'call myprocedure a1:1, a1:2' -
               'Error 35.900:  Named argument: the name "A1" is passed more than once'
call interpret 'call myprocedure a1:1, , a3:3' -
             , 'Error 35.900: Named argument: expected symbol followed by colon'
call interpret 'call myprocedure instance~method:1' -
             , 'Error 20.917: Symbol expected after superclass colon (:)'

-- Method 'sendWith'
call interpret 'r = .myclass~sendWith("mymethod")' -
             , 'Error 93.903: Missing argument in method; argument 2 is required'
call interpret 'r = .myclass~sendWith("mymethod", .object /* not an array */, namedArguments:.directory~of(a3:3))' -
             , 'Error 98.913: Unable to convert object "The Object class" to a single-dimensional array value'
call interpret 'r = .myclass~sendWith("mymethod", (1, 2), namedArguments: "not a directory")' -
             , 'Error 98.900: sendWith: The value of NAMEDARGUMENTS must be a directory or NIL'


-- Instruction 'forward'
source = 'forward message "mymethod" namedArguments continue'
call interpret 'm = .method~new("",' quoted(source)')' -
             , 'Error 35.1:    Incorrect expression detected at "CONTINUE"'
source = 'forward message "mymethod" namedArguments'
call interpret 'm = .method~new("",' quoted(source)')' -
             , 'Error 35.900:  Missing expression following NAMEDARGUMENTS keyword of a FORWARD instruction'
source = 'forward message "mymethod" array ( 10, 20, 30, a1:40, a2:50 ) namedArguments (.directory~of(a1:1, a2:2) continue'
call interpret 'm = .method~new("",' quoted(source)')' -
             , 'Error 25.918: Duplicate [NAMED]ARGUMENTS or ARRAY keyword found'
call interpret 'r = .myclass~forwardNamedArgumentsNotDirectory' -
             , "Error 98.900: FORWARD: The value of 'NAMEDARGUMENTS' must be a directory or NIL"

-- Method 'run'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "A", (1, 2, 3)){}' -
             , 'Error 93.938: Method argument 4 must have a string value'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "A", (1, 2), "D", .directory~of(a3:3)){}' -
             , 'Error 93.902: Too many arguments in invocation of method; 5 expected'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "A", .array~of(1), "D", .directory~of(a2:2, a3:3)){}' -
             , 'Error 93.902: Too many arguments in invocation of method; 5 expected'

-- Instruction 'use named'
call interpret 'call useNamed_EnvironmentSymbolNotAllowed' -
             , 'Error 31.3: Variable symbol must not start with a "."; found ".ENVSYMBOL"'
call interpret 'call useNamed_MessageTermNotAllowed' -
             , 'Error 87.2: The USE NAMED instruction requires a comma-separated list of variable symbols'
call interpret 'call useNamed_SkippedArgumentNotAllowed' -
             , 'Error 87.1: Skipped variables are not allowed by the USE NAMED instruction'
return

--------------------------------------------------------------------------------

myprocedure:
    call sayArg .context
    return ""

--------------------------------------------------------------------------------

interpret: procedure
    signal on syntax name error
    source = arg(1)
    expected = arg(2)
    say source
    interpret source
    if expected <> "" then say "Expected:" expected
    say; say
    return
    error:
    call sayCondition condition("O")
    if expected <> "" then say "Expected:" expected
    say; say
    return

--------------------------------------------------------------------------------

::routine myroutine
    call sayArg .context
    return ""

--------------------------------------------------------------------------------
:: routine usePositionalNamed
    call sayArg .context
    call indent
    say 'use arg p1, p2, p3, p4'
         use arg p1, p2, p3, p4
    call indent
    say 'use named arg a5, a6'
         use named arg a5, a6
    call sayCollection "variables", .context~variables
    return ""

--------------------------------------------------------------------------------
:: routine useStrictPositionalNamed
    call sayArg .context
    call indent
    say 'use strict arg p1, p2=2, p3, p4=4'
         use strict arg p1, p2=2, p3, p4=4
    call indent
    say 'use strict named arg a5, a6'
         use strict named arg a5, a6
    call sayCollection "variables", .context~variables
    return ""

--------------------------------------------------------------------------------
:: routine useNamed_SimpleSymbol
    call sayArg .context
    call indent
    say 'use named arg v1, v2=2'
         use named arg v1, v2=2
    call sayCollection "variables", .context~variables
    return ""

--------------------------------------------------------------------------------
:: routine useAutoNamed_SimpleSymbol
    call sayArg .context
    call indent
    say 'use auto named arg v1, v2=2'
         use auto named arg v1, v2=2
    call sayCollection "variables", .context~variables
    return ""

--------------------------------------------------------------------------------
:: routine useNamed_Stem_CompoundSymbol
    call sayArg .context
    call indent
    say 'use named arg stem., stem.v1, stem.v2=2'
         use named arg stem., stem.v1, stem.v2=2
    call sayCollection "variables", .context~variables
    call sayCollection "stem", stem.
    return ""

--------------------------------------------------------------------------------
:: routine useAutoNamed_Stem_CompoundSymbol
    call sayArg .context
    call indent
    say 'use auto named arg stem., stem.v1, stem.v2=2'
         use auto named arg stem., stem.v1, stem.v2=2
    call sayCollection "variables", .context~variables
    call sayCollection "stem", stem.
    return ""

--------------------------------------------------------------------------------
:: routine useNamed_EnvironmentSymbolNotAllowed
    call indent
    say                 'use named arg .envSymbol'
    m = .method~new("", 'use named arg .envSymbol')

--------------------------------------------------------------------------------
:: routine useNamed_MessageTermNotAllowed
    call indent
    say                 'use named arg instance~method'
    m = .method~new("", 'use named arg instance~method')

--------------------------------------------------------------------------------
:: routine useNamed_SkippedArgumentNotAllowed
    call indent
    say                 'use named arg n1,,n3'
    m = .method~new("", 'use named arg n1,,n3')

--------------------------------------------------------------------------------

::method myFloatingMethod
    call sayArg .context
    return ""

--------------------------------------------------------------------------------

::class myclass
::method mymethod class
    call sayArg .context
    return ""

::method forwardArray class
    call indent
    say 'forward message "mymethod" array ( 10, 20, 30, a1:40, a2:50 ) continue'
         forward message "mymethod" array ( 10, 20, 30, a1:40, a2:50 ) continue
    return ""

::method forwardNamedArguments class
    call indent
    say 'forward message "mymethod" namedArguments (.directory~of(a1:1, a2:2)) continue'
         forward message "mymethod" namedArguments (.directory~of(a1:1, a2:2)) continue
    return ""

::method forwardNamedArgumentsNotDirectory class
    call indent
    say 'forward message "mymethod" namedArguments ("not a directory") continue'
         forward message "mymethod" namedArguments ("not a directory") continue
    return ""

::method forwardPositionalNamedArguments class
    call indent
    say 'forward message "mymethod" arguments ((1,2)) namedArguments (.directory~of(a1:1, a2:2)) continue'
         forward message "mymethod" arguments ((1,2)) namedArguments (.directory~of(a1:1, a2:2)) continue
    return ""

::method forwardNamedPositionalArguments class
    call indent
    say 'forward message "mymethod" namedArguments (.directory~of(a1:1, a2:2)) arguments ((1,2)) continue'
         forward message "mymethod" namedArguments (.directory~of(a1:1, a2:2)) arguments ((1,2)) continue
    return ""

::method myrun class
    -- 'run' is a private method, must be called from another method of myclass, hence 'myrun'
    forward message ("run")

::method unknown class
    use arg name, arguments
    -- use named arg namedArguments
    namedArguments = .context~namedArgs["NAMEDARGUMENTS"]

    call indent 1
    say "method 'unknown'"
    call sayArg .context, 1

    -- call sayCollection "initial positional", arguments, 1
    -- call sayCollection "initial named", namedArguments, 1

    call indent 1
    say "method 'unknown' forward to (.myfooclass) message (name) arguments (arguments) namedArguments (namedArguments)"
    forward to(.myfooclass) message (name) arguments (arguments) namedArguments (namedArguments)

--------------------------------------------------------------------------------

::class myfooclass
::method foo class
    call sayArg .context, 1
    return ""

--------------------------------------------------------------------------------

::routine quoted
    return "'"arg(1)"'"

::routine indent
    use strict arg level=1
    do level
        call charout , "    "
    end

::routine sayArg
    use strict arg context, indentLevel=0
    positionalArgs = context~args
    namedArgs = context~namedArgs
    call sayCollection "positional", positionalArgs, indentLevel
    call sayCollection "named", namedArgs, indentLevel

::routine sayCollection
    use strict arg kind, collection, indentLevel=0
    call indent indentLevel+1
    if collection~isa(.array) then say kind "count="collection~items "size="collection~size
    else if collection <> .nil then say kind "count="collection~items
    else say kind "count=0"

    if collection == .nil then return

    do i over collection~allIndexes~sort
        call indent indentLevel+2
        say i ":" collection[i]
    end

::routine sayCondition
    use strict arg condition
    if condition~condition <> "SYNTAX" then call sayTrapped condition~condition
    if condition~description <> .nil, condition~description <> "" then call sayTrapped condition~description
    -- For SYNTAX conditions
    if condition~message <> .nil then call sayTrapped condition~message
    else if condition~errortext <> .nil then call sayTrapped condition~errortext
    if condition~code <> .nil then call sayTrapped "Code=" condition~code

::routine sayTrapped
    use strict arg value
    call indent
    say "[trapped]" value

::routine title
    use arg text, width=80
    say copies("*", width)
    say "*"center(text, width-2)"*"
    say copies("*", width)
    say

--------------------------------------------------------------------------------

-- .directory~of(a1:1, a2,2)
-- Next step : Modify the parser to support directly a directory literal (a1:1, a2:2)
::extension Directory
::method of class
    use strict arg -- no positional argument
    return .context~namedArgs
