/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

--::options trace i
::options NOMACROSPACE
::requires "concurrency/coactivity.cls"


-----------------------------------------------------------------------------
-- Mixin.
/*
A DoerFactory is an object which knows how to create a doer.
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
-- A Doer is an object which knows how to execute itself (understands "do")
-- This is an abstraction of routine, method, message, coactivity, closure.

::class "Doer" mixinclass Object public inherit DoerFactory

::method needsObject abstract
::method do abstract
::method doWith abstract
::method source abstract

-- Used by higher-order functions, to decide which arguments to pass
::method arity unguarded
    expose arity
    if arg() <> 0 then do
        guard on
        use strict arg arity -- store the arity
        return self -- for convenience, return the doer itself
    end
    else if \var("arity") then return -1 -- unknown arity
    else return arity

-- Tilde call
::method "~()" unguarded
    forward message "do"

::method trampoline unguarded
    doer = self
    if self~hasMethod("functionDoer") then doer=self~functionDoer -- Add support for implicit return
    forward message "do" to (doer) continue -- any number of arguments supported for the first call
    if \var("result") then return
    v = result
    -- The test \v~needsObject lets eliminate the StringDoers (and the MethodDoers, but the point is on StringDoers) :
    -- when you return a String, you don't want the error "Not enough arguments in method; 1 expected".
    do while v~isA(.Doer), \v~needsObject
        if v~hasMethod("functionDoer") then v=v~functionDoer -- Add support for implicit return
        v~do -- here, no args. Most of the time, v will be a closure which holds all the needed informations.
        if \var("result") then return
        v = result
    end
    return v

::method partial unguarded
    args1 = arg(1, "a")
    return {expose args1 self
            args2 = arg(1, "a")
            args = partialMergeArrays(args1, args2)
            -- Must forward explicitely to (self) otherwise stack overflow because forwarded to the closure itself.
            forward message "do" arguments (args) to (self)
           }~doer


::routine partialMergeArrays
    use strict arg args1, args2
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
    return args


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

/*
Inspired by http://mvanier.livejournal.com/2897.html.
Y = λf.(λx.f (λv.((x x) v))) (λx.f (λv.((x x) v)))

(define Y
  (lambda (f)
    ( (lambda (x) (f (lambda (v) ((x x) v))))
      (lambda (x) (f (lambda (v) ((x x) v)))))))

Equivalent form:

(define Y
  (lambda (f)
    ( (lambda (a) (a a))
      (lambda (x) (f (lambda (y) ((x x) y)))))))

The Y combinator allows recursion to be defined as a set of rewrite rules.
It takes a single argument, which is a function that isn't recursive (JLF : here, no argument, use self which is a Doer).
It returns a version of the function which is recursive.

Example :
    say {use arg f; return {expose f; use arg n; if n==0 then return 1; else return n * f~(n-1) } }~Y~(10)

Remember : ooRexx supports anonymous recursion, no need of the Y combinator in the real life...
    say { use arg n; if n==0 then return 1; else return n * .context~executable~(n-1)}~(10)
*/
::method Y unguarded
    use strict arg verbose=.false
    if verbose then trace i
    f = self -- to be closer to the notation (would be passed by parameter to lambda_f when implemented by a function instead of a method)
    return {use arg a ; return a~(a)} ~ {
        expose f verbose
        if verbose then trace i
        use strict arg x
        return f ~ { expose x verbose; if verbose then trace i ; use strict arg v ; return x~(x)~(v) }
    }

-- Y combinator with memoization
::method YM unguarded
    use strict arg verbose=.false
    if verbose then trace i
    f = self -- to be closer to the notation (would be passed by parameter to lambda_f when implemented by a function instead of a method)
    table = .Table~new
    return {use arg a ; return a~(a)} ~ {
        expose f verbose table
        if verbose then trace i
        use strict arg x
        return f ~ { expose x verbose table
                     if verbose then trace i
                     use strict arg v
                     r = table[v]
                     if r <> .nil then return r
                     r = x~(x)~(v)
                     table[v] = r
                     return r}
    }


-----------------------------------------------------------------------------
-- Mixin.

/*
Remember :
The method 'run' is a private method. So can be called only from another method of object...
"hello"~run(aMethod) --> Error : Object "hello" does not understand message "RUN" (ok, 'run' is private)
aMethod~do("hello") --> No error, display "hello" (so the private method is visible ?)
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
    forward to (object) message "sendWith" array (self, arg(2,"a"))

::method doWith unguarded
    use strict arg object, array
    forward to (object) message "sendWith" array (self, array)

::method source unguarded
    return self -- When used as a doer, a string is a message. Assume the message is the source.


-----------------------------------------------------------------------------
-- Mixin.

::class "RexxBlockDoer" mixinclass Object public inherit DoerFactory Doer

::method init
    expose executable
    executable = .nil
    self~init:super

::method doer unguarded
    expose executable
    if .nil <> executable then return executable
    use strict arg -- none
    executable = self~sourceDoer
    return executable

::method executable unguarded
    expose executable
    return executable

/*
Helper to create a doer from a source, after transformation of the source if requested.
Possible transformations :
- Insert a clause at the begining (takes care of the expose instruction, keep it always as
  first instruction).
- Insert a clause at the end.
*/
::method sourceDoer unguarded
    use strict arg clauseBefore="", clauseAfter="", context=.nil
    if .nil == context then context = self~package -- lookup scope

    kind = self~kind
    rawExecutable = self~rawExecutable
    if clauseBefore <> "" | clauseAfter <> "" | .nil == rawExecutable then do
        sourceArray = self~source -- always an array, even if empty or just one line
        clauser = .Clauser~new(sourceArray)
        kind = .SourceLiteralParser~kind(clauser)

        -- If the clause is an "expose" clause then skip it (must remain the first clause, always)
        if clauser~clauseAvailable then do
            clause = clauser~clause
            if .Clauser~isExposeClause(clause) then clauser~nextClause
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
    else if kind == "r.co" then return .Coactivity~new(rawExecutable)
    else if kind == "cl" then return .Closure~new(self~variables, rawExecutable)
    else if kind == "cl.co" then return .Coactivity~new(.Closure~new(self~variables, rawExecutable))
    return .nil -- should never happen

::method functionDoer
    expose executable
    if .nil <> executable then return executable
    use strict arg clauseBefore="", clauseAfter=""
    clauseBefore ||= ' ; options "NOCOMMANDS"'
    clauseAfter ||= ' ; if var("result") then return result'
    executable = self~sourceDoer(clauseBefore, clauseAfter)
    return executable

::method actionDoer
    expose executable
    if .nil <> executable then return executable
    use strict arg clauseBefore="", clauseAfter=""
    executable = self~sourceDoer(clauseBefore, clauseAfter)
    return executable

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
    1~pipe(.inject {{::coactivity expose item ; do forever ; .yield[item] ; item += 1 ; end}} iterateAfter | .take 10 | .console)
                                                                                                ****
In this example, the block passed to .inject returns another block whose doer is a coactivity.
The option "iterateAfter" checks if the current item has the "supplier" method. If yes, then it iterates over the items returned by the supplier.
A RexxBlock has no "supplier" method, but its doer may have one. This is the case in this example.
Without this redefinition, I should write :
                                                                                                ****
    1~pipe(.inject {{::coactivity expose item ; do forever ; .yield[item] ; item += 1 ; end}~doer} iterateAfter | .take 10 | .console)
                                                                                                ****
*/
::method hasMethod unguarded
    use strict arg methodName
    if self~hasMethod:super(methodName) then return .true
    forward to (self~doer)

/*
Normally, it's not a good idea to define an "unknown" method on a mixin class...
But here, I think it's ok to do that...
I find more natural to support directly blocks in the following samples (no need to send the message ~doer to the block) :
{::coactivity i=1 ; do forever; .yield[i]; i += 1 ; end}~take(5)~iterator~each{say item}
{::coactivity i=1 ; do forever; .yield[i]; i += 1 ; end}~select{item//2 == 0}~take(5)~iterator~each{say item}
*/
::method unknown unguarded
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
    forward message "resume"

::method doWith unguarded
    use strict arg array
    forward message "resume" arguments (array)

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
    if .nil <> variables then do
        !_closure.variableNames_! = ""
        do v over variables
            !_closure.variableNames_! ||= " "v
        end
        self~initVariables(variables)
    end
    if .nil <> action then do
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
    if .nil == doMethod then return .nil
    return doMethod~source

::method variables
    expose !_closure.variableNames_! (!_closure.variableNames_!)
    -- Must use variable names that will not collide with user-defined variables
    !_closure.directory_! = .Directory~new
    do !_closure.variableName_! over !_closure.variableNames_! ~ subwords
        !_closure.directory_! ~ put(value(!_closure.variableName_!), !_closure.variableName_!)
    end
    return !_closure.directory_!
