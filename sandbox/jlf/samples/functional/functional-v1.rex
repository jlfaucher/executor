/*
This script needs a modified ooRexx interpreter which allows to extend predefined ooRexx classes.
Something similar to C# extension methods :
http://msdn.microsoft.com/en-us/library/bb383977.aspx
http://weblogs.asp.net/scottgu/archive/2007/03/13/new-orcas-language-feature-extension-methods.aspx

Initial version v1 :
Use an intermediate class for Routine and Method : RoutineCaller and MethodRunner
See version v2 where Routine and Method are directly doers : RoutineCaller and MethodRunner no longer needed
*/


-----------------------------------------------------------------------------
-- Extends the behavior of predefined classes

-- A Doer is an object which knows how to execute itself (understands "do")
-- These methods returns a Doer object.
.Routine~define("doer", "return .RoutineCaller~new(self)")
.Method~define("doer", "return .MethodRunner~new(self)")
.String~define("doer", .methods~StringDoer)

-- Higher-order action "reduce"
.String~define("reduce", .methods~StringReduce)
.Collection~define("reduce", .methods~CollectionReduce)

-- Higher-order action "map"
-- Can be defined on any collection which supports "first" and "next"
.Array~define("map", .methods~Map)
.List~define("map", .methods~Map)
.Queue~define("map", .methods~Map)
.CircularQueue~define("map", .methods~Map)


-----------------------------------------------------------------------------
-- Doer factories

::method StringDoer
    parse var self word1 rest
    -- When the source string contains a single word, it's a message name
    if rest == "" then return .MessageNameSender~new(self)
    if word1~caselessEquals("::method") then do
        method = .Method~new("", rest)
        return .MethodRunner~new(method)
    end
    if word1~caselessEquals("::routine") then do
        routine = .Routine~new("", rest)
        return .RoutineCaller~new(routine)
    end
    -- Routine by default
    routine = .Routine~new("", self)
    return .RoutineCaller~new(routine)


-----------------------------------------------------------------------------
-- Higher-order actions

::method CollectionReduce
    use strict arg action
    doer = action~doer -- parse only once, before iteration
    supplier = self~supplier
    if \ supplier~available then return .nil
    r = supplier~item
    supplier~next
    do while supplier~available
        r = doer~do(r, supplier~item)
        supplier~next
    end
    return r


::method StringReduce
    use strict arg action
    return self~makearray("")~reduce(action)


-- Will work with Array, List, Queue, CircularQueue (any collection which supports "first" and "next")
-- I don't use a supplier because it works on a snapshot of the collection and is not done for updating the collection
-- (when inplace == .true the collection is updated in place)
::method Map
    use strict arg action, inplace=.false
    doer = action~doer -- parse only once, before iteration
    r = self
    if \inplace then r = self~copy
    current = self~first
    do while .nil <> current
        r[current] = doer~do(self[current])
        current = self~next(current)
    end
    return r


-----------------------------------------------------------------------------
-- Doer classes

-- Doer for calling a routine
::class RoutineCaller
::attribute routine
::method init
    use strict arg routine
    self~routine = routine
::method do
   return self~routine~callWith(arg(1,"a"))


-- Doer for running a method
::class MethodRunner
::attribute method
::method init
    use strict arg method
    self~method = method
::method do
    use strict arg object, ...
    return object~run(self~method, "a", arg(2,"a"))


-- Doer for sending a message name
::class MessageNameSender
::attribute messageName
::method init
    use strict arg messageName
    self~messageName = messageName
::method do
    use strict arg object, ...
    return object~sendWith(self~messageName, arg(2,"a"))

