--::options trace i
::requires "concurrency/coactivity.cls"
::requires "concurrency/busy.cls"

--------------------------------------------------------------------------------
/*
An example of coactivity whose entry point is a routine.
*/

::routine multiplier public
    -- Note that the multiplier is passed as argument only to the first invocation
    use strict arg multiplier
    call busy "A"
    .yield["The multiplier" multiplier "has been assigned and will be reused in future invocations"]

    use strict arg description, value
    call busy "B"
    .yield["The result of the" description "for" value "is" multiplier * value]

    use strict arg description, value
    call busy "C"
    .yield["The result of the" description "for" value "is" multiplier * value]

    use strict arg description, value
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

    use strict arg description, value
    call busy "A"
    .yield["The result of the" description "for" value "is" self~multiplier * value]

    use strict arg description, value
    call busy "B"
    .yield["The result of the" description "for" value "is" self~multiplier * value]

    use strict arg description, value
    call busy "C"
    return "The result of the" description "for" value "is" self~multiplier * value

