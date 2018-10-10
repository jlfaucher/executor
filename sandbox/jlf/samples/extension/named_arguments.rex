/*
Named arguments
*/


call interpret 'call myprocedure'
call interpret 'call myprocedure 1, 2, 3'
call interpret 'call myprocedure 1, 2, a3:3'
call interpret 'call myprocedure 1, a2:2, a3:3'
call interpret 'call myprocedure 1, a2:(2*5/4)**5, a3:.array~new(3,3)'
call interpret 'call myprocedure , , 3, ,'
call interpret 'call myprocedure , , 3, , a5:5'

call interpret 'r = myprocedure()'
call interpret 'r = myprocedure(1, 2, 3)'
call interpret 'r = myprocedure(1, 2, a3:3)'
call interpret 'r = myprocedure(1, a2:2, a3:3)'
call interpret 'r = myprocedure(1, a2:(2*5/4)**5, a3:.array~new(3,3))'
call interpret 'r = myprocedure(1, 2, 3){}'
call interpret 'r = myprocedure(1, 2, a3:3){}'
call interpret 'r = myprocedure(1, a2:2, a3:3){}'
call interpret 'r = myprocedure( , , 3, ,)'
call interpret 'r = myprocedure( , , 3, , a5:5)'

call interpret 'call myroutine'
call interpret 'call myroutine 1, 2, 3'
call interpret 'call myroutine 1, 2, a3:3'
call interpret 'call myroutine 1, a2:2, a3:3'
call interpret 'call myroutine 1, a2:(2*5/4)**5, a3:.array~new(3,3)'
call interpret 'call myroutine , , 3, ,'
call interpret 'call myroutine , , 3, , a5:5'

call interpret 'r = myroutine()'
call interpret 'r = myroutine(1, 2, 3)'
call interpret 'r = myroutine(1, 2, a3:3)'
call interpret 'r = myroutine(1, a2:2, a3:3)'
call interpret 'r = myroutine(1, a2:(2*5/4)**5, a3:.array~new(3,3))'
call interpret 'r = myroutine(1, 2, 3){}'
call interpret 'r = myroutine(1, 2, a3:3){}'
call interpret 'r = myroutine(1, a2:2, a3:3){}'
call interpret 'r = myroutine( , , 3, ,)'
call interpret 'r = myroutine( , , 3, , a5:5)'

call interpret 'r = .myclass~mymethod'
call interpret 'r = .myclass~mymethod()'
call interpret 'r = .myclass~mymethod(1, 2, 3)'
call interpret 'r = .myclass~mymethod(1, 2, a3:3)'
call interpret 'r = .myclass~mymethod(1, a2:2, a3:3)'
call interpret 'r = .myclass~mymethod(1, a2:(2*5/4)**5, a3:.array~new(3,3))'
call interpret 'r = .myclass~mymethod(1, 2, 3){}'
call interpret 'r = .myclass~mymethod(1, 2, a3:3){}'
call interpret 'r = .myclass~mymethod(1, a2:2, a3:3){}'
call interpret 'r = .myclass~mymethod( , , 3, ,)'
call interpret 'r = .myclass~mymethod( , , 3, , a5:5)'

-- Forward
call interpret 'r = .myclass~forwardArray'
call interpret 'r = .myclass~forwardNamedArguments'
call interpret 'r = .myclass~forwardPositionalNamedArguments'
call interpret 'r = .myclass~forwardNamedPositionalArguments'

-- Unknown method
call interpret 'r = .myclass~foo'
call interpret 'r = .myclass~foo()'
call interpret 'r = .myclass~foo(1, 2, 3)'
call interpret 'r = .myclass~foo(1, 2, a3:3)'
call interpret 'r = .myclass~foo(1, a2:2, a3:3)'
call interpret 'r = .myclass~foo(1, a2:(2*5/4)**5, a3:.array~new(3,3))'
call interpret 'r = .myclass~foo(1, 2, 3){}'
call interpret 'r = .myclass~foo(1, 2, a3:3){}'
call interpret 'r = .myclass~foo(1, a2:2, a3:3){}'
call interpret 'r = .myclass~foo( , , 3, ,)'
call interpret 'r = .myclass~foo( , , 3, , a5:5)'

-- Block
call interpret '{call sayArg .context}~rawExecutable~call'
call interpret '{call sayArg .context}~rawExecutable~call{}'
call interpret '{call sayArg .context}~rawExecutable~call(1, 2, a3:3)'
call interpret '{call sayArg .context}~rawExecutable~call(1, a2:2, a3:3)'
call interpret '{call sayArg .context}~rawExecutable~call(1, a2:(2*5/4)**5, a3:.array~new(3,3))'
call interpret '{call sayArg .context}~rawExecutable~call(1, 2, 3){}'
call interpret '{call sayArg .context}~rawExecutable~call(1, 2, a3:3){}'
call interpret '{call sayArg .context}~rawExecutable~call(1, a2:2, a3:3){}'
call interpret '{call sayArg .context}~rawExecutable~call( , , 3, ,)'
call interpret '{call sayArg .context}~rawExecutable~call( , , 3, , a5:5)'

-- no error, should raise an error
call interpret 'call myprocedure , , 3, , a5:5,'
call interpret 'call myroutine , , 3, , a5:5,'

-- Error 35: Invalid expression
call interpret 'call myprocedure 1, a2:2, a3:'                  -- Error 35.900:  Named argument: expected expression after colon
call interpret 'call myprocedure 1, a2:2, 3'                    -- Error 35.900:  Named argument: expected symbol followed by colon

-- Error 35: Invalid expression
source = 'forward message "mymethod" namedArguments continue'
call interpret 'm = .method~new("",' quoted(source)')'          -- Error 35.1:    Incorrect expression detected at "CONTINUE"
source = 'forward message "mymethod" namedArguments'
call interpret 'm = .method~new("",' quoted(source)')'          -- Error 35.900:  Missing expression following NAMEDARGUMENTS keyword of a FORWARD instruction

-- Error 25: Invalid subkeyword found
source = 'forward message "mymethod" array ( 10, 20, 30, a1:40, a2:50 ) namedArguments (.directory~new~~put(1,"a1")~~put(2,"a2")) continue'
call interpret 'm = .method~new("",' quoted(source)')'          -- Error 25.918: Duplicate [NAMED]ARGUMENTS or ARRAY keyword found

-- Error 98: Execution error
call interpret 'r = .myclass~forwardNamedArgumentsNotDirectory' -- Error 98.900: FORWARD namedArguments must be a directory

return

--------------------------------------------------------------------------------

myprocedure:
    call sayArg .context
    return ""

--------------------------------------------------------------------------------

interpret:
    signal on syntax name error
    say arg(1)
    interpret arg(1)
    say; say
    return
    error:
    call sayCondition condition("O")
    say; say
    return

--------------------------------------------------------------------------------

::routine myroutine
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
    say 'forward message "mymethod" namedArguments (.directory~new~~put(1,"a1")~~put(2,"a2")) continue'
         forward message "mymethod" namedArguments (.directory~new~~put(1,"a1")~~put(2,"a2")) continue
    return ""

::method forwardNamedArgumentsNotDirectory class
    call indent
    say 'forward message "mymethod" namedArguments ("not a directory") continue'
         forward message "mymethod" namedArguments ("not a directory") continue
    return ""

::method forwardPositionalNamedArguments class
    call indent
    say 'forward message "mymethod" arguments ((1,2)) namedArguments (.directory~new~~put(1,"a1")~~put(2,"a2")) continue'
         forward message "mymethod" arguments ((1,2)) namedArguments (.directory~new~~put(1,"a1")~~put(2,"a2")) continue
    return ""

::method forwardNamedPositionalArguments class
    call indent
    say 'forward message "mymethod" namedArguments (.directory~new~~put(1,"a1")~~put(2,"a2")) arguments ((1,2)) continue'
         forward message "mymethod" namedArguments (.directory~new~~put(1,"a1")~~put(2,"a2")) arguments ((1,2)) continue
    return ""

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

    supplier = collection~supplier
    do while supplier~available
        call indent indentLevel+2
        say supplier~index ":" supplier~item
        supplier~next
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
