/*
This script needs a modified ooRexx interpreter which allows to extend predefined ooRexx classes.
Something similar to C# extension methods :
http://msdn.microsoft.com/en-us/library/bb383977.aspx
http://weblogs.asp.net/scottgu/archive/2007/03/13/new-orcas-language-feature-extension-methods.aspx

Second version v2 :
Routine and Method are directly doers : RoutineCaller and MethodRunner no longer needed
*/


-----------------------------------------------------------------------------
-- Extends the behavior of predefined classes

-- A Doer is an object which knows how to execute itself (understands "do")
.Routine~define("do", 'return self~callWith(arg(1,"a"))')
.Method~define("do", 'use strict arg object, ... ; return object~run(self, "a", arg(2,"a"))')
-- Note : a Message can't be a Doer directly, must use an intermediate class MessageNameSender

-- These methods returns a Doer object.
.Routine~define("doer", "return self")
.Method~define("doer", "return self")
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
    if word1~caselessEquals("::method") then return .Method~new("", rest)
    if word1~caselessEquals("::routine") then return .Routine~new("", rest)
    -- Routine by default
    return .Routine~new("", self)


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

-- Doer for sending a message name
::class MessageNameSender
::attribute messageName
::method init
    use strict arg messageName
    self~messageName = messageName
::method do
    use strict arg object, ...
    return object~sendWith(self~messageName, arg(2,"a"))

