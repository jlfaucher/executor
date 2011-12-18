-- By default (no tag) the executable is a routine.
-- This routine is created by the interpreter when parsing the literal source (immediate parsing).
source = {use strict arg name, greetings; say "hello" name || greetings}
say source~class -- The RexxContextualSource class
say source~rawExecutable -- a Routine
say source~executable -- .nil, not yet cached
doer = source~doer -- no cost, returns directly the executable created by the interpreter at parsing time.
say doer~class -- The Routine class
doer~do("John", ", how are you ?") -- hello John, how are you ?
say

-- Same as previous but more compact
source = {use strict arg name, greetings; say "hello" name || greetings}
source~("John", ", how are you ?") -- hello John, how are you ?
say

-- Still more compact
{use strict arg name, greetings; say "hello" name || greetings}~("John", ", how are you ?") -- hello John, how are you ?
say

-- Here, ::method is a tag to indicate that the executable must be a method
-- The first argument passed with ~do is the object, available in self.
-- The rest of the ~do's arguments are passed to the method as arg(1), arg(2), ...
-- Minimal abbreviation is ::m
source = {::method use strict arg greetings; say "hello" self || greetings}
doer = source~doer
say doer~class -- The Method class
doer~do("John", ", how are you ?") -- hello John, how are you ?
say

-- Here, ::coactivity is a tag to indicate that the doer must be a coactivity (whose executable is a routine by default).
-- Minimal abbreviation is ::c
source = {::coactivity
          say "hello" arg(1) || arg(2)
          arg = .yield[]
          say "good bye" arg[1] || arg[2]
         }
doer = source~doer
say doer~class -- The Coactivity class
say doer~executable -- a Routine
doer~do("John", ", how are you ?") -- hello John, how are you ?
doer~do("Kathie", ", see you soon.") -- good bye Kathie, see you soon.
doer~do("Keith") -- <nothing done, the coactivity is ended>
say

-- ::routine.coactive (coactive routine) is equivalent to ::coactivity.
-- Minimal abbreviation is ::r.c
source = {::routine.coactive
          say "hello" arg(1) || arg(2)
          arg = .yield[]
          say "good bye" arg[1] || arg[2]
         }
doer = source~doer
say doer~class -- The Coactivity class
say doer~executable -- a Routine
doer~do("John", ", how are you ?") -- hello John, how are you ?
doer~do("Kathie", ", see you soon.") -- good bye Kathie, see you soon.
doer~do("Keith") -- <nothing done, the coactivity is ended>
say

-- Here, ::method.coactive is a tag to indicate that the doer must be a coactivity whose executable is a method.
-- The object on which the method is run is passed using the ~doer method.
-- Minimal abbreviation is ::m.c
source = {::method.coactive
          say self 'says "hello' arg(1) || arg(2)'"'
          arg = .yield[]
          say self 'says "good bye' arg[1] || arg[2]'"'
         }
doer = source~doer("The boss")
say doer~class -- The Coactivity class
say doer~executable -- A Method
doer~do("John", ", how are you ?") -- The boss says "hello John, how are you ?"
doer~do("Kathie", ", see you soon.") -- The boss says "good bye Kathie, see you soon."
doer~do("Keith") -- <nothing done, the coactivity is ended>
say

-- When used as a doer, a string is a message
source = "length"
doer = source~doer
say doer~class -- The String class
say doer~do("John") -- 4
say source~("John") -- 4
say

-- Implicit arguments and implicit return.
-- The original source
--    x~length
-- becomes :
--    use strict arg x ; options "NOCOMMANDS" ; x~length
--    return result
source = {x~length}
doer = source~sourceDoer('use strict arg x ; options NOCOMMANDS', "return result")
say doer~class -- The Routine class
say doer~do("John") -- 4
say

-- The method sourceDoer takes care of the expose instruction : keep it always as first instruction
-- The original source
--    ::method expose a b ; x*(a+b)
-- becomes :
--    expose a b  ; use strict arg x ; options "NOCOMMANDS"; x*(a+b)
--    return result
source = {::method expose a b ; x*(a+b)}
doer = source~sourceDoer('use strict arg x ; options "NOCOMMANDS"', "return result")
say doer~class -- The Method class
say doer~source~tostring
say

-- The method functionDoer (which calls sourceDoer) takes care of the implicit return
source = {x~length}
doer = source~functionDoer("use strict arg x")
say doer~class -- The Routine class
say doer~do("John") -- 4
say

-- closure by value
-- Minimal abbreviation is ::cl
-- Output is :
--    RexxContextualSource:1 --> Closure:2 --> 1 4
--    RexxContextualSource:3 --> Closure:4 --> 2 4
--    RexxContextualSource:5 --> Closure:6 --> 3 4
--    RexxContextualSource:7 --> Closure:8 --> 4 4
-- i contains a non mutable value (different value captured at each iteration).
-- literalSources contains a reference to a mutableValue (same value captured at each iteration).
pool = .queue~new
indexer = {::closure
    expose pool
    use strict arg value
    index = pool~index(value)
    if index == .nil then index = pool~append(value)
    return index
}
literalSources = .array~new
do i=1 to 4
    literalSources[i] = {::closure 
                         expose indexer literalSources i
                         use strict arg source, doer
                         call charout , source~class~id":"indexer~(source)
                         call charout , " --> "
                         call charout , doer~class~id":"indexer~(doer)
                         call charout , " --> "
                         call charout , i literalSources~items
                         say
                        }
end
do literalSource over literalSources
    doer = literalSource~doer
    doer~do(literalSource, doer)
end
say

-- Coactive closure
-- Minimal abbreviation is ::cl.c
v = 1
w = 2
source = {::closure.coactive expose v w ; .yield[v] ; .yield[w]}
doer = source~doer
say doer~class -- The Coactivity class
say doer~executable -- a Closure
say doer~do -- 1
say doer~do -- 2
doer~do -- no result
say

::requires "extension/extensions.cls"

