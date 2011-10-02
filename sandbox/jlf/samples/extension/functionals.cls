/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

--::options trace i
::requires "extension/doers.cls"

-----------------------------------------------------------------------------
-- Mixins
-- Reduce

::class "StringReduce" mixinclass Object public

-- 123~reduceChar("+") -- initial value is the first char (default), returns 6
-- 123~reduceChar(100, "+") -- initial value is 100, returns 106
::method reduceChar
    forward message "reduce" to (self~makearray(""))

-- "10 20 30"~reduceWord("+") -- initial value is the first word (default), returns 60
-- "10 20 30"~reduceWord(100, "+") -- initial value is 100, returns 160
-- "10 20 30"~reduceWord(, "indexed"){arg(1) + arg(2) + arg(3)} -- initial value is the first word (default), index passed as 3rd argument, returns 10 + 20+2 + 30+3 = 65
-- "10 20 30"~reduceWord(0, "indexed"){arg(1) + arg(2) + arg(3)} -- initial value is 0, index passed as 3rd argument, returns 0 + 10+1 + 20+2 + 30+3 = 66
::method reduceWord
    forward message "reduce" to (self~subwords)


::class "CollectionReduce" mixinclass Object public

-- .array~of(10, 20, 30)~reduce("+") -- initial value is the first item (default), returns 60
-- .array~of(10, 20, 30)~reduce(100, "+") -- initial value is 100, returns 160
-- .array~of(10, 20, 30)~reduce(, "indexed"){arg(1) + arg(2) + arg(3)} -- initial value is the first item (default), index passed as 3rd argument, returns 10 + 20+2 + 30+3 = 65
-- .array~of(10, 20, 30)~reduce(0, "indexed"){arg(1) + arg(2) + arg(3)} -- initial value is 0, index passed as 3rd argument, returns 0 + 10+1 + 20+2 + 30+3 = 66
::method reduce
    forward to (self~supplier)


::class "CoactivityReduce" mixinclass Object public

-- {::c .yield[10]; .yield[20]; .yield[30]}~reduce("+") -- initial value is the first item (default), returns 60
-- {::c .yield[10]; .yield[20]; .yield[30]}~reduce(100, "+") -- initial value is 100, returns 160
-- {::c .yield[10]; .yield[20]; .yield[30]}~reduce(, "indexed"){arg(1) + arg(2) + arg(3)} -- initial value is the first item (default), index passed as 3rd argument, returns 10 + 20+2 + 30+3 = 65
-- {::c .yield[10]; .yield[20]; .yield[30]}~reduce(0, "indexed"){arg(1) + arg(2) + arg(3)} -- initial value is 0, index passed as 3rd argument, returns 0 + 10+1 + 20+2 + 30+3 = 66
::method reduce
    forward to (self~supplier)


::class "SupplierReduce" mixinclass Object public

::method reduce
    initial = .nil
    options = ""
    indexed = .false
    if arg() == 3 then use strict arg initial=.nil, options="", action
    else if arg() == 2 then use strict arg initial=.nil, action
    else use strict arg action
    do option over options~subwords
        if "indexed"~caselessAbbrev(option, 3) then indexed = .true
        else raise syntax 93.900 array("Unknown option" option)
    end
    -- parse only once, before iteration
    if action~hasMethod("functionDoer") then doer = action~functionDoer
                                        else doer = action~doer
    if \ self~available then return initial
    if initial <> .nil then r = initial
    else do
        r = self~item
        self~next
    end
    do while self~available
        if indexed then doer~do(r, self~item, self~index)
                   else doer~do(r, self~item)
        if var("result") then r = result
        self~next
    end
    return r


-----------------------------------------------------------------------------
-- Mixins
-- Map

::class "StringMap" mixinclass Object public

::method mapChar
    options = ""
    if arg() == 2 then use strict arg options="", action={arg(1)}
    else use strict arg action={arg(1)}
    do option over options~subwords
        if "inplace"~caselessAbbrev(option, 3) then raise syntax 93.900 array ("inplace not applicable to string")
    end
    return .MutableBuffer~new~mapChar(options "inplace", action, self)~string

-- "one two three"~mapWord{if arg(1)~length > 3 then arg(1)} -- returns "three"
-- "one two three"~mapWord("indexed"){arg(2)":"arg(1)} -- returns "1:one 2:two 3:three"
::method mapWord
    options = ""
    if arg() == 2 then use strict arg options="", action={arg(1)}
    else use strict arg action={arg(1)}
    do option over options~subwords
        if "inplace"~caselessAbbrev(option, 3) then raise syntax 93.900 array ("inplace not applicable to string")
    end
    return .MutableBuffer~new~mapWord(options "inplace", action, self)~string


::class "MutableBufferMap" mixinclass Object public

::method mapChar
    source = .nil
    options = ""
    inplace = .true
    indexed = .false
    if arg() == 3 then use strict arg options="", action={arg(1)}, source=.nil
    else if arg() == 2 then use strict arg options="", action={arg(1)}
    else use strict arg action={arg(1)}
    do option over options~subwords
        if "indexed"~caselessAbbrev(option, 3) then indexed = .true
        else if "inplace"~caselessAbbrev(option, 3) then inplace = .true
        else if "\inplace"~caselessAbbrev(option, 4) then inplace = .false
        else raise syntax 93.900 array("Unknown option" option)
    end
    -- parse only once, before iteration
    if action~hasMethod("functionDoer") then doer = action~functionDoer
                                        else doer = action~doer
    if inplace then do
        r = self
        if source == .nil then source = self~string -- Must do a string copy before the delete(1)
        r~delete(1)
    end
    else do
        r = self~class~new
        if source == .nil then source = self -- No need of string copy here
    end
    supplier = source~makearray("")~supplier
    do while supplier~available
        if indexed then doer~do(supplier~item, supplier~index) -- Most of the time, we need only the item, that's why it's the first arg.
                   else doer~do(supplier~item)
        if var("result") then r~append(result)
        supplier~next
    end
    return r

::method mapWord
    source = .nil
    options = ""
    inplace = .true
    indexed = .false
    if arg() == 3 then use strict arg options="", action={arg(1)}, source=.nil
    else if arg() == 2 then use strict arg options="", action={arg(1)}
    else use strict arg action={arg(1)}
    do option over options~subwords
        if "indexed"~caselessAbbrev(option, 3) then indexed = .true
        else if "inplace"~caselessAbbrev(option, 3) then inplace = .true
        else if "\inplace"~caselessAbbrev(option, 4) then inplace = .false
        else raise syntax 93.900 array("Unknown option" option)
    end
    -- parse only once, before iteration
    if action~hasMethod("functionDoer") then doer = action~functionDoer
                                        else doer = action~doer
    if inplace then do
        r = self
        if source == .nil then source = self~string -- Must do a string copy before the delete(1)
        r~delete(1)
    end
    else do
        r = self~class~new
        if source == .nil then source = self -- No need of string copy here
    end
    supplier = source~subwords~supplier
    first = .true
    do while supplier~available
        if \first then r~append(" ")
        if indexed then doer~do(supplier~item, supplier~index) -- Most of the time, we need only the item, that's why it's the first arg.
                   else doer~do(supplier~item)
        if var("result") then do
            r~append(result)
            first = .false
        end
        supplier~next
    end
    return r


-- Will work with Array, List, Queue, CircularQueue (any collection which supports "append")
-- These 4 classes are subclasses of  OrderedCollection.
-- When inplace == .true the collection is updated in place, otherwise a new collection of the
-- same type as self is created.
::class "OrderedCollectionMap" mixinclass Object public

::method map
    options = ""
    inplace = .false
    indexed = .false
    if arg() == 2 then use strict arg options="", action={arg(1)}
    else use strict arg action={arg(1)}
    do option over options~subwords
        if "indexed"~caselessAbbrev(option, 3) then indexed = .true
        else if "inplace"~caselessAbbrev(option, 3) then inplace = .true
        else raise syntax 93.900 array("Unknown option" option)
    end
    -- parse only once, before iteration
    if action~hasMethod("functionDoer") then doer = action~functionDoer
                                        else doer = action~doer
    if inplace then do
        r = self
        supplier = self~supplier
        r~empty
    end
    else do
        if self~hasMethod("size") then r = self~class~new(self~size)
                                  else r = self~class~new
        supplier = self~supplier
    end
    do while supplier~available
        if indexed then doer~do(supplier~item, supplier~index) -- Most of the time, we need only the item, that's why it's the first arg.
                   else doer~do(supplier~item)
        if var("result") then r~append(result)
        supplier~next
    end
    return r


-----------------------------------------------------------------------------
-- Mixins
-- Repeater, array generator

::class "StringRepeater" mixinclass Object public

-- 3~times{say arg(1)} -- no resulting array because no result returned during the iteration
-- 3~times{1} -- returns .array~of(1,1,1)
-- 3~times{arg(1)} -- returns .array~of(1,2,3)
::method times
    use strict arg action, resultClass=.Array
    -- parse only once, before iteration
    if action~hasMethod("functionDoer") then doer = action~functionDoer
                                        else doer = action~doer
    r = .nil -- no resulting array by default
    do i = 1 to self
        doer~do(i)
        if var("result") then do
            if r == .nil then r = resultClass~new -- first time we get a result, create the resulting collection now
            r~append(result)
        end
    end
    return r

-- 11~upto(13){say arg(1)} -- no resulting array because no result returned during the iteration
-- 11~upto(13){2*arg(1)} -- returns .array~of(22,24,26)
-- 11~upto(13) -- returns .array~of(11,12,13)
-- (-1)~upto(3) -- returns .array~of(-1,0,1,2,3) -- Note that -2 MUST be surrounded by paren or quotes
::method upto
    use strict arg upperLimit, action={arg(1)}, resultClass=.Array
    -- parse only once, before iteration
    if action~hasMethod("functionDoer") then doer = action~functionDoer
                                        else doer = action~doer
    r = .nil -- no resulting array by default
    do i = self to upperLimit
        doer~do(i)
        if var("result") then do
            if r == .nil then r = resultClass~new -- first time we get a result, create the resulting collection now
            r~append(result)
        end
    end
    return r

-- 13~downto(11){say arg(1)} -- no resulting array because no result returned during the iteration
-- 13~downto(11){2*arg(1)} -- returns .array~of(26,24,22)
-- 13~downto(11) -- returns .array~of(13,12,11)
-- 3~upto(-1) -- returns .array~of(3,2,1,0,-1)
::method downto
    use strict arg lowerLimit, action={arg(1)}, resultClass=.Array
    -- parse only once, before iteration
    if action~hasMethod("functionDoer") then doer = action~functionDoer
                                        else doer = action~doer
    r = .nil -- no resulting array by default
    do i = self to lowerLimit by -1
        doer~do(i)
        if var("result") then do
            if r == .nil then r = resultClass~new -- first time we get a result, create the resulting collection now
            r~append(result)
        end
    end
    return r


-----------------------------------------------------------------------------
-- Mixins
-- Iterator, collection generator

-- Works with any collection (unlike map), but can't update in place.
-- If at least one result is returned during the iteration, then a resulting collection is returned.
::class "CollectionIterator" mixinclass Object public

::method each
    options = ""
    if arg() == 2 then use strict arg options="", action={arg(1)}
    else use strict arg action={arg(1)}
    supplier = self~supplier
    -- Some collections, like CircularQueue, requires a size when creating an instance
    if self~hasMethod("size") then size = self~size
                              else size = -1
    forward to (supplier) array(options, action, self~class, size) -- If a resulting collection is created then it will be a new instance of self~class


-- Could be useful to have directly ~each available from a coactivity, instead of doing ~supplier~each.
-- If at least one result is returned during the iteration, then a resulting array is returned.
::class "CoactivityIterator" mixinclass Object public

::method each
    options = ""
    if arg() == 2 then use strict arg options="", action={arg(1)}
    else use strict arg action={arg(1)}
    supplier = self~supplier
    forward to (supplier) array(options, action, .array) -- If a resulting collection is created then it will be a new instance of .array


::class "SupplierIterator" mixinclass Object public

::method each
    options = ""
    indexed = .false
    resultClass = .Array
    size = -1
    if arg() == 4 then use strict arg options="", action={arg(1)}, resultClass=.Array, size=(-1)
    else if arg() == 3 then use strict arg options="", action={arg(1)}, resultClass=.Array
    else if arg() == 2 then use strict arg options="", action={arg(1)}
    else use strict arg action={arg(1)}
    do option over options~subwords
        if "indexed"~caselessAbbrev(option, 3) then indexed = .true
        else raise syntax 93.900 array("Unknown option" option)
    end
    -- parse only once, before iteration
    if action~hasMethod("functionDoer") then doer = action~functionDoer
                                        else doer = action~doer
    r = .nil -- no resulting array by default
    do while self~available
        if indexed then doer~do(self~item, self~index) -- Most of the time, we need only the item, that's why it's the first arg.
                   else doer~do(self~item)
        if var("result") then do
            if r == .nil then do
                -- first time we get a result, create the resulting collection now
                if size <> -1 then r = resultClass~new(size)
                else r = resultClass~new
            end
            if r~isA(.Queue) then r~append(result) -- special constraint : Can't assign at same index, because if the index does not exist in the queue, an error is raised.
            else if r~isA(.List) then r~append(result) -- special constraint : Can't assign at same index, because if the index does not exist in the queue, an error is raised.
            else if r~isA(.SetCollection) then r[result] = result -- special constraint : index and item must be the same object
            else r[self~index] = result
        end
        self~next
    end
    return r

