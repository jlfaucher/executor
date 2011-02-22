/*
This script works with a standard ooRexx, no need of ::extension here.
BUT
only the version with ::extension will let you hook those mixins on the predefined classes.
*/

::requires "factory.cls"

-----------------------------------------------------------------------------
-- Mixins.
-- A Doer is an object who knows how to execute itself (understands "do")

::class RoutineDoer mixinclass Object public

::method doer
    use strict arg context=.nil
    if context <> .nil then raise syntax 93.900 array ("Context not supported")
    return self

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
    use strict arg context=.nil
    if context <> .nil then raise syntax 93.900 array ("Context not supported") 
    return self

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
    parse version v
    use strict arg context=.nil
    parse var self word1 rest
    
    -- For better support of extended classes, must take care of special factories (not needed with ::extension)
    methodFactory = Object.factory(self, .Method)
    routineFactory = Object.factory(self, .Routine)
    
    -- When the source string contains a single word without '(', it's a message name
    if rest == "" & word1~pos("(") == 0 then do
        if context <> .nil then raise syntax 93.900 array ("Context not supported") 
        return self
    end
    if word1~caselessEquals("::method") then do
        if context == .nil then return methodFactory~new("", rest)
        return methodFactory~new("", rest, context)
    end
    if word1~caselessEquals("::routine") then do
        if context == .nil then return routineFactory~new("", rest)
        return routineFactory~new("", rest, context)
    end
    -- Routine by default
    if context == .nil then return routineFactory~new("", self)
    return routineFactory~new("", self, context)

::method do
    use strict arg object, ...
    object~sendWith(self, arg(2,"a"))
    if var("result") then return result

::method doWith
    use strict arg object, array
    object~sendWith(self, array)
    if var("result") then return result

