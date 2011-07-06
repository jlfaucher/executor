/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

--::options trace i

-----------------------------------------------------------------------------
-- Mixins.
-- A Doer is an object who knows how to execute itself (understands "do")

::class RoutineDoer mixinclass Object public

::method doer
    use strict arg -- none
    return self

::method needsObject
    return .false -- No need to pass an object as first argument when calling do or doWith

::method do
    self~callWith(arg(1,"a"))
    if var("result") then return result

::method doWith
    use strict arg array
    self~callWith(array)
    if var("result") then return result


/*
To investigate :
The method 'run' is a private method. So can be called only from another method of object...
"hello"~run("::method say self"~doer) --> Error : Object "hello" does not understand message "RUN" (ok, 'run' is private)
"::method say self"~doer~do("hello") --> No error, display "hello" (so the private method is visible ?)
*/
::class MethodDoer mixinclass Object public

::method doer
    use strict arg -- none
    return self

::method needsObject
    return .true -- Must pass an object as first argument when calling do or doWith

::method do
    use strict arg object, ...
    object~run(self, "a", arg(2,"a"))
    if var("result") then return result

::method doWith
    use strict arg object, array
    object~run(self, "a", array)
    if var("result") then return result


::class StringDoer mixinclass Object public

::method doer
    use strict arg -- none
    return self -- When used as a doer, a string is a message

::method needsObject
    return .true -- Must pass an object as first argument when calling do or doWith

::method do
    use strict arg object, ...
    object~sendWith(self, arg(2,"a"))
    if var("result") then return result

::method doWith
    use strict arg object, array
    object~sendWith(self, array)
    if var("result") then return result


::class RexxContextualSourceDoer mixinclass Object public

::method doer
    use strict arg -- none
    parse value self~source with word1 rest
    
    if word1~caselessEquals("::method") then return .Method~new("", rest, self~package)
    if word1~caselessEquals("::routine") then return .Routine~new("", rest, self~package)
    -- Routine by default
    return .Routine~new("", self~source, self~package)

