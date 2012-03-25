/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

--::options trace i
::options NOMACROSPACE
::requires "concurrency/coactivity.cls"


-----------------------------------------------------------------------------
-- Mixin.
/*
A DoerFactory is an object who knows how to create a doer.
A doer can be created from :
- a RexxBlock :
  Can be costly since the interpreter must parse the source and create an AST.
  But you do it only once... After, you get an executable in your hands, which you can use
  as a target for the 'do' message.
- an executable (Routine or Method) :
  No cost, this is for convenience, the doer is the executable itself.
- a wrapper of executable (Coactivity, Closure) :
  No cost, this is for convenience, the doer is the wrapper itself.

Examples :
See doers-samples.rex
*/

::class "DoerFactory" mixinclass Object public

::method doer abstract


-----------------------------------------------------------------------------
-- Mixin.
-- A Doer is an object who knows how to execute itself (understands "do")
-- This is an abstraction of routine, method, message, coactivity, closure.

::class "Doer" mixinclass Object public inherit DoerFactory

::method needsObject abstract
::method do abstract
::method doWith abstract
::method source abstract

-- Used by higher-order functions, to decide which arguments to pass
::method arity
    expose arity
    if arg() <> 0 then do
        use strict arg arity -- store the arity
        return self -- for convenience, return the doer itself
    end
    else if \var("arity") then return -1 -- unknown arity
    else return arity

-- Tilde call
::method "~()" unguarded
    forward message "do"

::method trampoline unguarded
    forward message "do" continue -- any number of arguments supported for the first call
    if \var("result") then return
    v = result
    -- The test \v~needsObject lets eliminate the StringDoers (and the MethodDoers, but the point is on StringDoers) : 
    -- when you return a String, you don't want the error "Not enough arguments in method; 1 expected".
    do while v~isA(.Doer), \v~needsObject
        v~do -- here, no args. Most of the time, v will be a closure which holds all the needed informations.
        if \var("result") then return
        v = result
    end
    return v

::method partial unguarded
    args1 = arg(1, "a")
    return {::closure
            expose args1 self
            args2 = arg(1, "a")
            size2 = args2~size
            if size2 == 0 then args = args1
            else do
                args = args1~copy
                index1 = 1
                index2 = 1
                do while index2 <= size2
                    do while args~hasIndex(index1)
                        index1 += 1
                    end
                    if args2~hasIndex(index2) then args[index1] = args2[index2]
                    index1 += 1
                    index2 += 1
                end
            end
            -- Must forward explicitely to (self) otherwise stack overflow because forwarded to the closure itself.
            forward message "do" arguments (args) to (self)
           }~doer


-----------------------------------------------------------------------------
-- Mixin.

::class "RoutineDoer" mixinclass Object public inherit Doer

::method doer unguarded
    use strict arg -- none
    return self

::method needsObject unguarded
    return .false -- No need to pass an object as first argument when calling do or doWith

::method do unguarded
    forward message "call"

::method doWith unguarded
    forward message "callWith"


-----------------------------------------------------------------------------
-- Mixin.

/*
Remember :
The method 'run' is a private method. So can be called only from another method of object...
"hello"~run({::method say self}~doer) --> Error : Object "hello" does not understand message "RUN" (ok, 'run' is private)
{::method say self}~doer~do("hello") --> No error, display "hello" (so the private method is visible ?)
--> It's because the ~run method is called from the ~do method which has been added by extension.
*/
::class "MethodDoer" mixinclass Object public inherit Doer

::method doer unguarded
    use strict arg -- none
    return self

::method needsObject unguarded
    return .true -- Must pass an object as first argument when calling do or doWith

::method do unguarded
    use strict arg object, ...
    forward to (object) message "run" array (self, "a", arg(2,"a"))

::method doWith unguarded
    use strict arg object, array
    forward to (object) message "run" array (self, "a", array) 


-----------------------------------------------------------------------------
-- Mixin.

::class "StringDoer" mixinclass Object public inherit Doer

::method doer unguarded
    use strict arg -- none
    return self -- When used as a doer factory, a string is a message

::method needsObject unguarded
    return .true -- Must pass an object as first argument when calling do or doWith

::method do unguarded
    use strict arg object, ...
    forward to (object) message ("sendWith") array (self, arg(2,"a"))

::method doWith unguarded
    use strict arg object, array
    forward to (object) message "sendWith" array (self, array)

::method source unguarded
    return self -- When used as a doer, a string is a message. Assume the message is the source.


-----------------------------------------------------------------------------
-- Mixin.

::class "RexxBlockDoer" mixinclass Object public inherit DoerFactory Doer

::method doer unguarded
    use strict arg object=.nil -- optional object, needed when the source is tagged ::method.coactive
    if self~executable <> .nil then return self~executable
    objectSpecified = arg(1, "e") -- object explicitely passed ?
    self~executable = self~sourceDoer( , , , objectSpecified, object)
    return self~executable

/*
Helper to create a doer from a source, after transformation of the source if requested.
Possible transformations :
- Insert a clause at the begining (takes care of the expose instruction, keep it always as
  first instruction).
- Insert a clause at the end.
*/
::method sourceDoer unguarded
    use strict arg clauseBefore="", clauseAfter="", context=.nil, objectSpecified = .false, object = .nil
    if context == .nil then context = self~package -- lookup scope

    kind = self~kind
    rawExecutable = self~rawExecutable
    if clauseBefore <> "" | clauseAfter <> "" | rawExecutable == .nil then do
        sourceArray = self~source -- always an array, even if empty or just one line
        clauser = .Clauser~new(sourceArray)
        kind = .SourceLiteralParser~kind(clauser)
        
        -- If the clause is an "expose" clause then skip it (must remain the first clause, always)
        if clauser~clauseAvailable then do
            clause = clauser~clause
            parse lower var clause word rest
            if word == "expose" & \ isAssignment(rest) then clauser~nextClause
        end
    
        -- Insert the 'clauseBefore', if any
        if clauseBefore <> "" then do
            if clauser~clauseAvailable then clauser~clause = clauseBefore ";" clauser~clause
            else sourceArray~append(clauseBefore)
        end
    
        -- Insert the 'clauseAfter', if any
        if clauseAfter <> "" then sourceArray~append(clauseAfter)
        
        rawExecutable = .SourceLiteralParser~rawExecutable(kind, sourceArray, context)
    end

    -- Returns the executable
    if kind == "r" then return rawExecutable
    else if kind == "r.c" then return .Coactivity~new(rawExecutable)
    else if kind == "m" then return rawExecutable
    else if kind == "m.c" then do
        if \objectSpecified then raise syntax 93.900 array("No object specified")
        return .Coactivity~new(rawExecutable, , object)
    end
    else if kind == "cl" then return .Closure~new(self~variables, rawExecutable)
    else if kind == "cl.c" then return .Coactivity~new(.Closure~new(self~variables, rawExecutable))
    return .nil -- should never happen

::method functionDoer unguarded
    use strict arg clauseBefore="", clauseAfter="", object=.nil-- optional object, needed when the source is tagged ::method.coactive
    objectSpecified = arg(3, "e") -- object explicitely passed ?
    clauseBefore ||= ' ; options "NOCOMMANDS"'
    clauseAfter ||= ' ; if var("result") then return result'
    self~executable = self~sourceDoer(clauseBefore, clauseAfter, , objectSpecified, object)
    return self~executable

::method actionDoer unguarded
    use strict arg clauseBefore="", clauseAfter="", object=.nil-- optional object, needed when the source is tagged ::method.coactive
    objectSpecified = arg(3, "e") -- object explicitely passed ?
    self~executable = self~sourceDoer(clauseBefore, clauseAfter, , objectSpecified, object)
    return self~executable

-- Even if unknown is defined, must explicitely provide a concrete implementation because abstract
::method needsObject unguarded
    forward to (self~doer)

-- Even if unknown is defined, must explicitely provide a concrete implementation because abstract
::method do unguarded
    forward to (self~doer)

-- Even if unknown is defined, must explicitely provide a concrete implementation because abstract
::method doWith unguarded
    forward to (self~doer)

/*
I want to support that (no ~doer in the following expression) :
                                                                                                ****
    1~pipe(.inject {{::closure.coactive expose item ; do forever ; .yield[item] ; item += 1 ; end}} iterateAfter | .take 10 | .console)
                                                                                                ****
In this example, the block passed to .inject returns another block whose doer is a coactivity. 
The option "iterateAfter" checks if the current item has the "supplier" method. If yes, then it iterates over the items returned by the supplier.
A RexxBlock has no "supplier" method, but its doer may have one. This is the case in this example. 
Without this redefinition, I should write :
                                                                                                ****
    1~pipe(.inject {{::closure.coactive expose item ; do forever ; .yield[item] ; item += 1 ; end}~doer} iterateAfter | .take 10 | .console)
                                                                                                ****
*/
::method hasMethod
    use strict arg methodName
    if self~hasMethod:super(methodName) then return .true
    /*if methodName~caselessEquals("SUPPLIER") then*/ forward to (self~doer)
    return .false

::method supplier unguarded
    forward to (self~doer)

/*
Normally, it's not a good idea to define an "unknown" method on a mixin class...
But here, I think it's ok to do that...
I find more natural to support directly blocks in the following samples (no need to send the message ~doer to the block) : 
{::coactivity i=1 ; do forever; .yield[i]; i += 1 ; end}~take(5)~iterator~each{say item}
{::coactivity i=1 ; do forever; .yield[i]; i += 1 ; end}~select{item//2 == 0}~take(5)~iterator~each{say item}
*/
::method unknown
    use arg msg, args
    forward message (msg) arguments (args) to (self~doer)


-----------------------------------------------------------------------------
-- Mixin.

::class "CoactivityDoer" mixinclass Object public inherit Doer

::method doer unguarded
    use strict arg -- none
    return self

::method needsObject unguarded
    return .false -- No need to pass an object as first argument when calling do or doWith

::method do unguarded
    forward message ("resume")

::method doWith unguarded
    use strict arg array
    forward message ("resume") arguments (array)

::method source unguarded
    return self~executable~source


-----------------------------------------------------------------------------
-- Closure by value : not yet a real closure but useful anyway 
-- (assuming that only closures by reference are real closures...)
-- good point, no risk of race conditions...
 
::class "Closure" public inherit Doer

::method init
    expose !_closure.variableNames_!
    use strict arg variables=.nil, action=.nil
    if variables <> .nil then do
        !_closure.variableNames_! = ""
        do v over variables
            !_closure.variableNames_! ||= " "v
        end
        self~initVariables(variables)
    end
    if action <> .nil then do
        method = action~doer
        self~setMethod("do", method, "Object")
    end

::method initVariables
    expose !_closure.variableNames_! (!_closure.variableNames_!)
    -- Must use variable names that will not collide with user-defined variables
    use strict arg !_closure.variables_!
    !_closure.supplier_! = !_closure.variables_!~supplier
    do while !_closure.supplier_!~available
        call value !_closure.supplier_!~index, !_closure.supplier_!~item
        !_closure.supplier_!~next
    end

::method setMethod public unguarded -- override the private setMethod inherited from Object to make it public
    forward class (super)

::method doer unguarded
    use strict arg -- none
    return self

::method needsObject unguarded
    return .false -- The closure itself is the object

::method doWith unguarded
    use strict arg array
    forward message "do" arguments (array)

::method source unguarded
    doMethod = self~instanceMethod("do")
    if doMethod == .nil then return .nil
    return doMethod~source


-----------------------------------------------------------------------------
::routine isAssignment
    use strict arg str
    left1 = str~left(1)
    left2 = str~left(2)
    left3 = str~left(3)
    if left2 == "==" then return .false
    if left1 == "=" then return .true
    if "+= -= *= /= %= &= |="~pos(left2) <> 0 then return .true
    if "//= ||= &&="~pos(left3) <> 0 then return .true
    return .false


