--::options trace i
::requires "concurrency/coactivity.cls"
::requires "concurrency/busy.cls"

--------------------------------------------------------------------------------
/*
An example of coactivity whose entry point is a routine.
*/

::routine multiplier public
    -- for the first call, the traditional arguments declaration can be used.
    -- for the following calls, it's less declarative : you get only an array returned by yield.
    -- I'd like to use the traditional arguments declaration everywhere...
    
    -- Note that the multiplier is passed as argument only to the first invocation
    use strict arg multiplier
    call busy "A"
    args = .Coactivity~yield("The multiplier" multiplier "has been assigned and will be reused in future invocations") 

    -- use strict arg description, value    
    description = args[1]
    value = args[2]
    call busy "B"
    args = .Coactivity~yield("The result of the" description "for" value "is" multiplier * value)

    -- use strict arg description, value    
    description = args[1]
    value = args[2]
    call busy "C"
    args = .Coactivity~yield("The result of the" description "for" value "is" multiplier * value)

    -- use strict arg description, value    
    description = args[1]
    value = args[2]
    call busy "D"
    return "The result of the" description "for" value "is" multiplier * value

--------------------------------------------------------------------------------
/*
An example of coactivity defined as a subclass of .Coactivity.
The entry point is the default entry point : 'main' method.
*/

::class Multiplier public inherit Coactivity
::attribute multiplier

::method init
    use strict arg multiplier
    self~multiplier = multiplier
    self~init:super
    
::method main
    -- Here, self is the coactivity.
    
    -- for the first call, the traditional arguments declaration can be used
    -- for the following calls, it's less declarative : you get only an array returned by yield
    -- I'd like to use the traditional arguments declaration everywhere...
    
    use strict arg description, value
    call busy "A"
    args = .Coactivity~yield("The result of the" description "for" value "is" self~multiplier * value)

    -- use strict arg description, value    
    description = args[1]
    value = args[2]
    call busy "B"
    args = .Coactivity~yield("The result of the" description "for" value "is" self~multiplier * value)

    -- use strict arg description, value    
    description = args[1]
    value = args[2]
    call busy "C"
    return "The result of the" description "for" value "is" self~multiplier * value

::method onTerminate
    say "When the method onTerminate is defined, then it's called automatically when the coactivity is terminated."

