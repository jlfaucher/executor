/*
This script works with a standard ooRexx, but has drawbacks compared to doers.cls.
*/

--::options trace i

-----------------------------------------------------------------------------
/*
Extract from rexxref, .Routine~new : 
The context allows the created routine to inherit class and routine lookup scope from another source. If
specified, context can be a Method object, a Routine object, or a Package object. If not specified, the
newly created method will inherit the class and routine search scope from the caller of new method.

So, by default, any routine created by StringDoer will have a lookup scope limited to the doers package,
because the routines are created from here, not from the caller's package. 
StringDoer~doer accepts a context parameter to let the caller pass its own lookup scope, but this is
tedious to pass it explicitely.
That's why I provide this routine which lets see from doers the same packages/methods/routines as the caller.
Usage from caller's package :
call Doers.AddVisibilityFrom(.context)

Note : this is a temporary workaround. The good approach is to add support for first-class 
expressions/instructions that are parsed in place, instead of being parsed by StringDoer..
https://sourceforge.net/mailarchive/message.php?msg_id=19912031
*/

::routine Doers.AddVisibilityFrom public
    use strict arg package -- can be a .Package or a .RexxContext
    if package~isA(.RexxContext) then package = package~package
    do p over package~importedPackages
        .context~package~addPackage(p)
    end
    classes = package~classes
    do c over classes
        .context~package~addClass(c, classes[c])
    end
    routines = package~routines
    do r over routines
        .context~package~addRoutine(r, routines[r])
    end
    
-----------------------------------------------------------------------------
-- Mixins.
-- A Doer is an object which knows how to execute itself (understands "do")

::class RoutineDoer mixinclass Object public

::method init
    -- Enhancement by delegation (wrapper) when ~enhanced can't be used
    expose routine
    use arg routine=.nil

::method doer
    use strict arg context=.nil
    if context <> .nil then raise syntax 93.900 array ("Context not supported")
    return self

::method needsObject
    return .false -- No need to pass an object as first argument when calling do or doWith

::method do
    expose routine -- In some cases, the "real" routine is encapsulated
    if var("routine"), routine <> .nil then self = routine 
    self~callWith(arg(1,"a"))
    if var("result") then return result

::method doWith
    expose routine -- In some cases, the "real" routine is encapsulated
    use strict arg array
    if var("routine"), routine <> .nil then self = routine 
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
    use strict arg context=.nil
    parse var self word1 rest
    
    -- When the source string contains a single word without '(', it's a message name
    if rest == "" & word1~pos("(") == 0 then do
        if context <> .nil then raise syntax 93.900 array ("Context not supported") 
        return self
    end
    if word1~caselessEquals("::method") then do
        if context == .nil then return .Method~enhanced(.MethodDoer~methods(.nil), "", rest)
        if context~isA(.RexxContext) then context = context~package
        return .Method~enhanced(.MethodDoer~methods(.nil), "", rest, context)
    end
    if word1~caselessEquals("::routine") then do
        if context == .nil then return .Routine~enhanced(.RoutineDoer~methods(.nil), "", rest)
        if context~isA(.RexxContext) then context = context~package
        return .Routine~enhanced(.RoutineDoer~methods(.nil), "", rest, context)
    end
    -- Routine by default
    -- To support extended classes, must convert self to a "real" string
    -- (if self is an ExtendedString then .Routine~new will not accept it).
    if context == .nil then return .Routine~enhanced(.RoutineDoer~methods(.nil), "", self~string)
    if context~isA(.RexxContext) then context = context~package
    return .Routine~enhanced(.RoutineDoer~methods(.nil), "", self~string, context)

::method needsObject
    return .true -- Must pass an object as first argument when calling do or doWith

::method do
    use strict arg object, ...
    -- ~sendWith doesn't accept a subclass of String : must convert self to a String
    object~sendWith(self~string, arg(2,"a"))
    if var("result") then return result

::method doWith
    use strict arg object, array
    -- ~sendWith doesn't accept a subclass of String : must convert self to a String
    object~sendWith(self~string, array)
    if var("result") then return result

