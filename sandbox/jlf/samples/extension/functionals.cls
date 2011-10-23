/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

--::options trace i
::requires "extension/doers.cls"

-----------------------------------------------------------------------------
-- Mixins
-- Reduce
-- http://en.wikipedia.org/wiki/Fold_(higher-order_function)

------------------------------------------------
::class "StringReducer" mixinclass Object public
------------------------------------------------

-- Iterate over the characters of the string and combine them into one value by applying the given action to (current_value, current_char)
-- 123~reduceC("+") -- initial value is the first char (default), reduce by char, returns 6
-- 123~reduceC(100, "+") -- initial value is 100, reduce by char, returns 106
-- Iterate over the characters of the string and combine them into one value by applying the given action to (current_value, current_char, current_char_pos)
-- 567~reduceCI{arg(1) + arg(2) + arg(3)} -- initial value is the first char (default), reduce by char, index passed as 3rd argument, returns 5 + 6+2 + 7+3 = 23
-- 567~reduceCI(0){arg(1) + arg(2) + arg(3)} -- initial value is 0, reduce by char, index passed as 3rd argument, returns 0 + 5+1 + 6+2 + 7+3 = 24
::method reduceC
    forward message "reduce" to (self~makeArray(""))

-- Iterate over the words of the string and combine them into one value by applying the given action to (current_value, current_word)
-- "10 20 30"~reduceW("+") -- initial value is the first word (default), reduce by word, returns 60
-- "10 20 30"~reduceW(100, "+") -- initial value is 100, reduce by word, returns 160
-- Iterate over the words of the string and combine them into one value by applying the given action to (current_value, current_word, current_word_index)
-- "10 20 30"~reduceWI{arg(1) + arg(2) + arg(3)} -- initial value is the first word (default), reduce by word, index passed as 3rd argument, returns 10 + 20+2 + 30+3 = 65
-- "10 20 30"~reduceWI(0){arg(1) + arg(2) + arg(3)} -- initial value is 0, reduce by word, index passed as 3rd argument, returns 0 + 10+1 + 20+2 + 30+3 = 66
::method reduceW
    forward message "reduce" to (self~subwords)


-------------------------------------------------------
::class "MutableBufferReducer" mixinclass Object public
-------------------------------------------------------

-- Iterate over the characters of the mutable buffer and combine them into one value by applying the given action to (current_value, current_char)
-- .MutableBuffer~new(123)~reduceC("+") -- initial value is the first char (default), reduce by char, returns 6
-- .MutableBuffer~new(123)~reduceC(100, "+") -- initial value is 100, reduce by char, returns 106
-- Iterate over the characters of the mutable buffer and combine them into one value by applying the given action to (current_value, current_char, current_char_pos)
-- .MutableBuffer~new(567)~reduceCI{arg(1) + arg(2) + arg(3)} -- initial value is the first char (default), reduce by char, index passed as 3rd argument, returns 5 + 6+2 + 7+3 = 23
-- .MutableBuffer~new(567)~reduceCI(0){arg(1) + arg(2) + arg(3)} -- initial value is 0, reduce by char, index passed as 3rd argument, returns 0 + 5+1 + 6+2 + 7+3 = 24
::method reduceC
    forward message "reduce" to (self~makeArray(""))

-- Iterate over the words of the mutable buffer and combine them into one value by applying the given action to (current_value, current_word)
-- .MutableBuffer~new("10 20 30")~reduceW("+") -- initial value is the first word (default), reduce by word, returns 60
-- .MutableBuffer~new("10 20 30")~reduceW(100, "+") -- initial value is 100, reduce by word, returns 160
-- Iterate over the words of the mutable buffer and combine them into one value by applying the given action to (current_value, current_word, current_word_index)
-- .MutableBuffer~new("10 20 30")~reduceWI{arg(1) + arg(2) + arg(3)} -- initial value is the first word (default), reduce by word, index passed as 3rd argument, returns 10 + 20+2 + 30+3 = 65
-- .MutableBuffer~new("10 20 30")~reduceWI(0){arg(1) + arg(2) + arg(3)} -- initial value is 0, reduce by word, index passed as 3rd argument, returns 0 + 10+1 + 20+2 + 30+3 = 66
::method reduceW
    forward message "reduce" to (self~subwords)


----------------------------------------------------
::class "CollectionReducer" mixinclass Object public
----------------------------------------------------
-- BEWARE ! the ~reduce method is available on all the collections, but only ordered collections can be reduced using non-commutative operations.
-- Ex : "+" can be used on any collection, but "-" should be used only on ordered collections.

-- Iterate over the items of the collection and combine them into one value by applying the given action to (current_value, current_item)
-- .array~of(10, 20, 30)~reduce("+") -- initial value is the first item (default), returns 60
-- .array~of(10, 20, 30)~reduce(100, "+") -- initial value is 100, returns 160
-- Iterate over the items of the collection and combine them into one value by applying the given action to (current_value, current_item, current_index)
-- .array~of(10, 20, 30)~reduceI{arg(1) + arg(2) + arg(3)} -- initial value is the first item (default), index passed as 3rd argument, returns 10 + 20+2 + 30+3 = 65
-- .array~of(10, 20, 30)~reduceI(0){arg(1) + arg(2) + arg(3)} -- initial value is 0, index passed as 3rd argument, returns 0 + 10+1 + 20+2 + 30+3 = 66
::method reduce
    forward to (self~supplier)


----------------------------------------------------
::class "CoactivityReducer" mixinclass Object public
----------------------------------------------------

-- Iterate over the values yielded by the coactivity and combine them into one value by applying the given action to (current_value, current_yielded_value)
-- {::c .yield[10]; .yield[20]; .yield[30]}~doer~reduce("+") -- initial value is the first item (default), returns 60
-- {::c .yield[10]; .yield[20]; .yield[30]}~doer~reduce(100, "+") -- initial value is 100, returns 160
-- Iterate over the values yielded by the coactivity and combine them into one value by applying the given action to (current_value, current_yielded_value, current_yielded_index)
-- {::c .yield[10]; .yield[20]; .yield[30]}~doer~reduceI{arg(1) + arg(2) + arg(3)} -- initial value is the first item (default), index passed as 3rd argument, returns 10 + 20+2 + 30+3 = 65
-- {::c .yield[10]; .yield[20]; .yield[30]}~doer~reduceI(0){arg(1) + arg(2) + arg(3)} -- initial value is 0, index passed as 3rd argument, returns 0 + 10+1 + 20+2 + 30+3 = 66
::method reduce
    forward to (self~supplier)


--------------------------------------------------
::class "SupplierReducer" mixinclass Object public
--------------------------------------------------

-- Iterate over the items of the supplier and combine them into one value by applying the given action to (current_value, current_item)
-- When the action understands ~functionDoer then a third parameter current_index is passed.
::method reduce
    if arg() == 2 then do
        use strict arg initial, action
        return self~reduceImpl(action, initial)
    end
    else do
        use strict arg action
        return self~reduceImpl(action)
    end

::method reduceImpl private
    use strict arg action, initial=.nil
    -- parse only once, before iteration
    if action~hasMethod("functionDoer") then do ; doer = action~functionDoer("use arg accu, value, index") ; indexed = .true ; end
                                        else do ; doer = action~doer ; indexed = .false ; end
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
-- http://en.wikipedia.org/wiki/Map_(higher-order_function)
-- The result returned by ~map method is of the same type as the self object.
-- A String or MutableBuffer can be filtered (when no result returned by the given action).
-- A Collection can't be filtered : If the given action doesn't return a result, then the current value is unchanged.
-- If you need to filter the values of a Collection, then use the ~each method.

-----------------------------------------------
::class "StringMapper" mixinclass Object public
-----------------------------------------------

-- Iterate over the characters of the string and apply the given action to (current_char)
-- "abcdefghijklmnopqrstuvwxyz"~mapC{arg(1)~verify('aeiouy')} -- returns "01110111011111011111011101"
-- Iterate over the characters of the string and apply the given action to (current_char, current_char_pos)
-- "abcdefghijk"~mapCI{arg(2)":"arg(1)" "} -- returns "1:a 2:b 3:c 4:d 5:e 6:f 7:g 8:h 9:i 10:j 11:k "
::method mapC
    use strict arg action
    return .MutableBuffer~new~mapCImpl(self, action)~string

-- Not applicable to a string
--::method mapCR

-- Iterate over the words of the string and apply the given action to (current_word)
-- "one two three"~mapW{if arg(1)~length > 3 then arg(1)} -- returns "three"
-- Iterate over the words of the string and apply the given action to (current_word, current_word_index)
-- "one two three"~mapWI{arg(2)":"arg(1)} -- returns "1:one 2:two 3:three"
::method mapW
    use strict arg action
    return .MutableBuffer~new~mapWImpl(self, action)~string

-- Not applicable to a string
--::method mapWR


------------------------------------------------------
::class "MutableBufferMapper" mixinclass Object public
------------------------------------------------------

-- Iterate over the characters of the mutable buffer and apply the given action to (current_char)
-- .MutableBuffer~new("abcdefghijklmnopqrstuvwxyz")~mapC{arg(1)~verify('aeiouy')} -- returns "01110111011111011111011101"
-- Iterate over the characters of the mutable buffer and apply the given action to (current_char, current_char_pos)
-- .MutableBuffer~new("abcdefghijk")~mapCI{arg(2)":"arg(1)" "} -- returns "1:a 2:b 3:c 4:d 5:e 6:f 7:g 8:h 9:i 10:j 11:k "
::method mapC
    use strict arg action
    return .MutableBuffer~new~mapCImpl(self, action)

-- Iterate over the characters of the mutable buffer and apply the given action to (current_char) in-place
-- .MutableBuffer~new("abcdefghijklmnopqrstuvwxyz")~mapCR{arg(1)~verify('aeiouy')} -- returns "01110111011111011111011101"
-- Iterate over the characters of the mutable buffer and apply the given action to (current_char, current_char_pos) in-place
-- .MutableBuffer~new("abcdefghijk")~mapCRI{arg(2)":"arg(1)" "} -- returns "1:a 2:b 3:c 4:d 5:e 6:f 7:g 8:h 9:i 10:j 11:k "
::method mapCR
    use strict arg action
    return self~mapCImpl(self~string, action)

-- Iterate over the words of the mutable buffer and apply the given action to (current_char)
-- .MutableBuffer~new("one two three")~mapW{if arg(1)~length > 3 then arg(1)} -- returns "three"
-- Iterate over the words of the mutable buffer and apply the given action to (current_char, current_char_pos)
-- .MutableBuffer~new("one two three")~mapWI{arg(2)":"arg(1)} -- returns "1:one 2:two 3:three"
::method mapW
    use strict arg action
    return .MutableBuffer~new~mapWImpl(self, action)

-- Iterate over the words of the mutable buffer and apply the given action to (current_char) in-place
-- .MutableBuffer~new("one two three")~mapWR{if arg(1)~length > 3 then arg(1)} -- returns "three"
-- Iterate over the words of the mutable buffer and apply the given action to (current_char, current_char_pos) in-place
-- .MutableBuffer~new("one two three")~mapWRI{arg(2)":"arg(1)} -- returns "1:one 2:two 3:three"
::method mapWR
    use strict arg action
    return self~mapWImpl(self~string, action)

::method mapCImpl -- not private because called by String~map
    use strict arg source, action
    -- parse only once, before iteration
    if action~hasMethod("functionDoer") then do ; doer = action~functionDoer("use arg value, index") ; indexed = .true ; end
                                        else do ; doer = action~doer ; indexed = .false ; end
    self~delete(1)
    supplier = source~makearray("")~supplier -- really not optimized but...
    do while supplier~available
        if indexed then doer~do(supplier~item, supplier~index) -- Most of the time, we need only the item, that's why it's the first arg.
                   else doer~do(supplier~item)
        if var("result") then self~append(result)
        supplier~next
    end
    return self

::method mapWImpl -- not private because called by String~map
    use strict arg source, action
    -- parse only once, before iteration
    if action~hasMethod("functionDoer") then do ; doer = action~functionDoer("use arg value, index") ; indexed = .true ; end
                                        else do ; doer = action~doer ; indexed = .false ; end
    self~delete(1)
    supplier = source~subwords~supplier -- really not optimized but...
    first = .true
    do while supplier~available
        if indexed then doer~do(supplier~item, supplier~index) -- Most of the time, we need only the item, that's why it's the first arg.
                   else doer~do(supplier~item)
        if var("result") then do
            doResult = result
            if \first then self~append(" ")
            self~append(doResult)
            first = .false
        end
        supplier~next
    end
    return self


---------------------------------------------------
::class "CollectionMapper" mixinclass Object public
---------------------------------------------------

-- Iterate over the items of a copy of the collection and apply the given action to (current_item)
-- .array~of(1,2,3)~map{2*arg(1)} -- returns .array~of(2,4,6)
-- Iterate over the items of a copy of the collection and apply the given action to (current_item, current_index)
-- .array~of(1,2,3)~mapI{2*arg(1) + arg(2)} -- returns .array~of(3,6,9)
::method map
    use strict arg action
    return self~copy~mapImpl(self~supplier, action)

-- Iterate over the items of the collection and apply the given action to (current_item) in-place
-- .array~of(1,2,3)~mapR{2*arg(1)} -- returns .array~of(2,4,6)
-- Iterate over the items of the collection and apply the given action to (current_item, current_index) in-place
-- .array~of(1,2,3)~mapRI{2*arg(1) + arg(2)} -- returns .array~of(3,6,9)
::method mapR
    use strict arg action
    return self~mapImpl(self~supplier, action)

-- Always in-place (if needed, do a copy of the target collection before applying this method).
-- If no value is returned by the given action, then the current item is unchanged (no filtering).
::method mapImpl private
    use strict arg supplier, action
    -- parse only once, before iteration
    if action~hasMethod("functionDoer") then do ; doer = action~functionDoer("use arg value, index") ; indexed = .true ; end
                                        else do ; doer = action~doer ; indexed = .false ; end
    if self~isA(.SetCollection) | self~isA(.Relation) then self~empty
    do while supplier~available
        newItem = supplier~item
        if indexed then doer~do(supplier~item, supplier~index) -- Most of the time, we need only the item, that's why it's the first arg.
                   else doer~do(supplier~item)
        if var("result") then newItem = result
        if self~isA(.SetCollection) then self[newItem] = newItem -- special constraint : index and item must be the same object
                                    else self[supplier~index] = newItem
        supplier~next
    end
    return self


-----------------------------------------------------------------------------
-- Mixins
-- Repeater, collector, filter.

-------------------------------------------------
::class "StringRepeater" mixinclass Object public
-------------------------------------------------

-- Repeat self times the given action (self is a number).
-- If at least one result is returned by the action during the loop, then an array of results is returned.
-- 3~times{say arg(1)} -- no resulting array because no result returned during the iteration
-- 3~times{1} -- returns .array~of(1,1,1)
-- 3~times{arg(1)} -- returns .array~of(1,2,3)
::method times
    use strict arg action={arg(1)}
    forward to 1 message "upto" array(self, action)

-- Lazy repeater : returns a coactivity.
-- Repeat self times the given action (self is a number).
-- When the action returns a result during the loop, this result is yielded.
-- The next result will be calculated only when requested.
-- c = 1000000~times.yield
-- say c~resume -- 1
-- say c~resume -- 2
-- ...
::method times.yield
    use strict arg action={arg(1)}
    forward to 1 message "yield.upto" array(self, action)

-- Repeat the given action from self up to upper limit (self and upper limit are numbers).
-- If at least one result is returned by the action during the loop, then an array of results is returned.
-- 11~upto(13){say arg(1)} -- no resulting array because no result returned during the iteration
-- 11~upto(13){2*arg(1)} -- returns .array~of(22,24,26)
-- 11~upto(13) -- returns .array~of(11,12,13)
-- (-1)~upto(3) -- returns .array~of(-1,0,1,2,3) -- Note that -1 MUST be surrounded by paren or quotes
::method upto
    use strict arg upperLimit, action={arg(1)}
    -- parse only once, before iteration
    if action~hasMethod("functionDoer") then doer = action~functionDoer("use arg value")
                                        else doer = action~doer
    collectedItems = .nil -- no resulting array by default
    do i = self to upperLimit
        doer~do(i)
        if var("result") then do
            doResult = result
            if collectedItems == .nil then collectedItems = .Array~new -- first time we get a result, create the resulting array now
            collectedItems~append(doResult)
        end
    end
    if collectedItems <> .nil then return collectedItems

-- Lazy repeater : returns a coactivity.
-- Repeat the given action from self up to upper limit (self and upper limit are numbers).
-- When the action returns a result during the loop, this result is yielded.
-- The next result will be calculated only when requested.
-- c = 11~yield.upto(1000000)
-- say c~resume -- 11
-- say c~resume -- 12
-- ...
::method yield.upto -- coactive
    use strict arg upperLimit, action={arg(1)}
    c = .Coactivity~new{
        -- expose self upperLimit action        -- to activate when closure supported
        use strict arg self, upperLimit, action -- to remove when closure supported
        .yield[]                                -- to remove when closure supported
        -- parse only once, before iteration
        if action~hasMethod("functionDoer") then doer = action~functionDoer("use arg value")
                                            else doer = action~doer
        do i = self to upperLimit
            doer~do(i)
            if var("result") then .yield[result]
        end
    }
    c~resume(self, upperLimit, action) -- to remove when closure supported
    return c

-- Repeat the given action from self down to lower limit (self and lower limit are numbers).
-- If at least one result is returned by the action during the loop, then an array of results is returned.
-- 13~downto(11){say arg(1)} -- no resulting array because no result returned during the iteration
-- 13~downto(11){2*arg(1)} -- returns .array~of(26,24,22)
-- 13~downto(11) -- returns .array~of(13,12,11)
-- 3~upto(-1) -- returns .array~of(3,2,1,0,-1)
::method downto
    use strict arg lowerLimit, action={arg(1)}
    -- parse only once, before iteration
    if action~hasMethod("functionDoer") then doer = action~functionDoer("use arg value")
                                        else doer = action~doer
    collectedItems = .nil -- no resulting array by default
    do i = self to lowerLimit by -1
        doer~do(i)
        if var("result") then do
            doResult = result
            if collectedItems == .nil then collectedItems = .Array~new -- first time we get a result, create the resulting array now
            collectedItems~append(doResult)
        end
    end
    if collectedItems <> .nil then return collectedItems

-- Lazy repeater : returns a coactivity.
-- Repeat the given action from self down to lower limit (self and lower limit are numbers).
-- When the action returns a result during the loop, this result is yielded.
-- The next result will be calculated only when requested.
-- c = 1000000~yield.downto(11)
-- say c~resume -- 1000000
-- say c~resume -- 999999
-- ...
::method yield.downto -- coactive
    use strict arg lowerLimit, action={arg(1)}
    c = .Coactivity~new{
        -- expose self lowerLimit action        -- to activate when closure supported
        use strict arg self, lowerLimit, action -- to remove when closure supported
        .yield[]                                -- to remove when closure supported
        -- parse only once, before iteration
        if action~hasMethod("functionDoer") then doer = action~functionDoer("use arg value")
                                            else doer = action~doer
        do i = self to lowerLimit by -1
            doer~do(i)
            if var("result") then .yield[result]
        end
    }
    c~resume(self, lowerLimit, action) -- to remove when closure supported
    return c


-----------------------------------------------------------------------------
-- Mixins
-- Iterator, collector, filter.
-- Whatever the object being iterated over, the ~each method returns an array
-- (if at least one value was returned by the given action during the iteration).
-- If you need a result object which is of the same type as the iterated object,
-- then use ~map.

-------------------------------------------------
::class "StringIterator" mixinclass Object public
-------------------------------------------------

-- Iterate over the characters of the string and apply the given action to (current_char)
-- When the action understands ~functionDoer then a second parameter current_char_pos is passed.
-- If at least one result is returned by the action during the iteration, then an array of results is returned.
::method eachC
    forward message "each" to (self~makeArray(""))

-- Iterate over the characters of the string and apply the given action to (current_char, current_char_pos)
-- If at least one result is returned by the action during the iteration, then an array of results and indexes is returned.
-- result[1] == array of results
-- result[2] == array of indexes
-- Both arrays contains the same number of items, where result[2][n] is the index of result[1][n].
::method eachCI
    forward message "eachI" to (self~makeArray(""))

-- Iterate over the words of the string and apply the given action to (current_word)
-- When the action understands ~functionDoer then a second parameter current_word_index is passed.
-- If at least one result is returned by the action during the iteration, then an array of results is returned.
::method eachW
    forward message "each" to (self~subwords)

-- Iterate over the words of the string and apply the given action to (current_word, current_word_index)
-- If at least one result is returned by the action during the iteration, then an array of results and indexes is returned.
-- result[1] == array of results
-- result[2] == array of indexes
-- Both arrays contains the same number of items, where result[2][n] is the index of result[1][n].
::method eachWI
    forward message "eachI" to (self~subwords)


--------------------------------------------------------
::class "MutableBufferIterator" mixinclass Object public
--------------------------------------------------------

-- Iterate over the characters of the mutable buffer and apply the given action to (current_char)
-- When the action understands ~functionDoer then a second parameter current_char_pos is passed.
-- If at least one result is returned by the action during the iteration, then an array of results is returned.
::method eachC
    forward message "each" to (self~makeArray(""))

-- Iterate over the characters of the mutable buffer and apply the given action to (current_char, current_char_pos)
-- If at least one result is returned by the action during the iteration, then an array of results and indexes is returned.
-- result[1] == array of results
-- result[2] == array of indexes
-- Both arrays contains the same number of items, where result[2][n] is the index of result[1][n].
::method eachCI
    forward message "eachI" to (self~makeArray(""))

-- Iterate over the words of the mutable buffer and apply the given action to (current_word)
-- When the action understands ~functionDoer then a second parameter current_word_index is passed.
-- If at least one result is returned by the action during the iteration, then an array of results is returned.
::method eachW
    forward message "each" to (self~subwords)

-- Iterate over the words of the mutable buffer and apply the given action to (current_word, current_word_index)
-- If at least one result is returned by the action during the iteration, then an array of results and indexes is returned.
-- result[1] == array of results
-- result[2] == array of indexes
-- Both arrays contains the same number of items, where result[2][n] is the index of result[1][n].
::method eachWI
    forward message "eachI" to (self~subwords)


-----------------------------------------------------
::class "CollectionIterator" mixinclass Object public
-----------------------------------------------------

-- Iterate over the items of the collection and apply the given action to (current_item).
-- When the action understands ~functionDoer then a second parameter current_index is passed.
-- If at least one result is returned by the action during the iteration, then an array of results is returned.
::method each
    forward to (self~supplier)

-- Iterate over the items of the collection and apply the given action to (current_item, current_index).
-- If at least one result is returned by the action during the iteration, then an array of results and indexes is returned.
-- result[1] == array of results
-- result[2] == array of indexes
-- Both arrays contains the same number of items, where result[2][n] is the index of result[1][n].
::method eachI
    forward to (self~supplier)


-----------------------------------------------------
::class "CoactivityIterator" mixinclass Object public
-----------------------------------------------------

-- Iterate over the values yielded by the coactivity and apply the given action to (current_yielded_value).
-- When the action understands ~functionDoer then a second parameter current_yielded_index is passed.
-- If at least one result is returned by the action during the iteration, then an array of results is returned.
::method each
    forward to (self~supplier)

-- Iterate over the values yielded by the coactivity and apply the given action to (current_yielded_value, current_yielded_index).
-- If at least one result is returned by the action during the iteration, then an array of results and indexes is returned.
-- result[1] == array of results
-- result[2] == array of indexes
-- Both arrays contains the same number of items, where result[2][n] is the index of result[1][n].
::method eachI
    forward to (self~supplier)


---------------------------------------------------
::class "SupplierIterator" mixinclass Object public
---------------------------------------------------

-- Iterate over then items of the supplier and apply the given action to (current_item).
-- When the action understands ~functionDoer then a second parameter current_index is passed.
-- If at least one result is returned by the action during the iteration, then an array of results is returned.
::method each
    use strict arg action={arg(1)}
    self~eachImpl(action, .false)
    if var("result") then return result

-- Iterate over the items of the supplier and apply the given action to (current_item, current_index).
-- If at least one result is returned by the action during the iteration, then an array of results and indexes is returned.
-- result[1] == array of results
-- result[2] == array of indexes
-- Both arrays contains the same number of items, where result[2][n] is the origin index of result[1][n].
::method eachI
    use strict arg action={arg(1)}
    self~eachImpl(action, .true)
    if var("result") then return result

::method eachImpl private
    use strict arg action={arg(1)}, returnIndex=.false
    -- parse only once, before iteration
    if action~hasMethod("functionDoer") then do ; doer = action~functionDoer("use arg value, index") ; indexed = .true ; end
                                        else do ; doer = action~doer ; indexed = .false ; end
    collectedItems = .nil -- no resulting array by default
    do while self~available
        if indexed then doer~do(self~item, self~index) -- Most of the time, we need only the item, that's why it's the first arg.
                   else doer~do(self~item)
        if var("result") then do
            doResult = result
            if collectedItems == .nil then do
                -- first time we get a result, create the resulting array now
                collectedItems = .Array~new
                if returnIndex then collectedIndexes = .Array~new
            end
            collectedItems~append(doResult)
            if returnIndex then collectedIndexes~append(self~index)
        end
        self~next
    end
    if collectedItems <> .nil then do
        if returnIndex then return .Array~of(collectedItems, collectedIndexes)
        return collectedItems
    end

