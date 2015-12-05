-- By default (no tag) the executable is a routine.
block = {use strict arg name, greetings; say "hello" name || greetings}
say block~class -- The RexxBlock class
say block~rawExecutable -- a Routine
say block~executable -- .nil, not yet cached
doer = block~doer -- no cost, returns directly the executable created by the interpreter at parsing time.
say doer~class -- The Routine class
doer~do("John", ", how are you ?") -- hello John, how are you ?
say

-- Same as previous but more compact
block = {use strict arg name, greetings; say "hello" name || greetings}
block~("John", ", how are you ?") -- hello John, how are you ?
say

-- Still more compact
{use strict arg name, greetings; say "hello" name || greetings}~("John", ", how are you ?") -- hello John, how are you ?
say

-- Here, ::coactivity is a tag to indicate that the doer must be a coactivity (whose executable is a routine by default).
-- Minimal abbreviation is ::co
block = {::coactivity
          say "hello" arg(1) || arg(2)
          .yield[]
          say "good bye" arg(1) || arg(2)
         }
doer = block~doer
say doer~class -- The Coactivity class
say doer~executable -- a Routine
doer~do("John", ", how are you ?") -- hello John, how are you ?
doer~do("Kathie", ", see you soon.") -- good bye Kathie, see you soon.
doer~do("Keith") -- <nothing done, the coactivity is ended>
say

-- ::routine.coactive (coactive routine) is equivalent to ::coactivity.
-- Minimal abbreviation is ::r.co
block = {::routine.coactive
          say "hello" arg(1) || arg(2)
          .yield[]
          say "good bye" arg(1) || arg(2)
         }
doer = block~doer
say doer~class -- The Coactivity class
say doer~executable -- a Routine
doer~do("John", ", how are you ?") -- hello John, how are you ?
doer~do("Kathie", ", see you soon.") -- good bye Kathie, see you soon.
doer~do("Keith") -- <nothing done, the coactivity is ended>
say

-- When used as a doer, a string is a message
block = "length"
doer = block~doer
say doer~class -- The String class
say doer~do("John") -- 4
say block~("John") -- 4
say

-- Implicit arguments and implicit return.
-- The original source
--    x~length
-- becomes :
--    use strict arg x ; options "NOCOMMANDS" ; x~length
--    return result
block = {x~length}
doer = block~sourceDoer('use strict arg x ; options NOCOMMANDS', "return result")
say doer~class -- The Routine class
say doer~do("John") -- 4
say

-- The method functionDoer (which calls sourceDoer) takes care of the implicit return
block = {x~length}
doer = block~functionDoer("use strict arg x")
say doer~class -- The Routine class
say doer~do("John") -- 4
say

-- closure by value
-- Minimal abbreviation is ::cl
-- Output is :
--    RexxBlock:1 --> Closure:2 --> 1 4
--    RexxBlock:3 --> Closure:4 --> 2 4
--    RexxBlock:5 --> Closure:6 --> 3 4
--    RexxBlock:7 --> Closure:8 --> 4 4
-- i contains a non mutable value (different value captured at each iteration).
-- blocks contains a reference to a mutableValue (same value captured at each iteration).
pool = .queue~new
indexer = {::closure
            expose pool
            use strict arg value
            index = pool~index(value)
            if index == .nil then index = pool~append(value)
            return index
}
blocks = .array~new
do i=1 to 4
    blocks[i] = {::closure
                 expose indexer blocks i
                 use strict arg block, doer
                 call charout , block~class~id":"indexer~(block)
                 call charout , " --> "
                 call charout , doer~class~id":"indexer~(doer)
                 call charout , " --> "
                 call charout , i blocks~items
                 say
                        }
end
do block over blocks
    doer = block~doer
    doer~do(block, doer)
end
say

-- Coactive closure
-- Minimal abbreviation is ::cl.co
v = 1
w = 2
block = {::closure.coactive expose v w ; .yield[v] ; .yield[w]}
doer = block~doer
say doer~class -- The Coactivity class
say doer~executable -- a Closure
say doer~do -- 1
say doer~do -- 2
doer~do -- no result
say

::requires "extension/extensions.cls"

