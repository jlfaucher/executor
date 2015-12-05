/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

--::options trace i
::options NOMACROSPACE
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
-- 567~reduceC{arg(1) + arg(2) + arg(3)} -- initial value is the first char (default), reduce by char, index passed as 3rd argument, returns 5 + 6+2 + 7+3 = 23
-- 567~reduceC(0){arg(1) + arg(2) + arg(3)} -- initial value is 0, reduce by char, index passed as 3rd argument, returns 0 + 5+1 + 6+2 + 7+3 = 24
::method reduceC unguarded
    forward message "reduce" to (self~makeArray(""))

-- Iterate over the words of the string and combine them into one value by applying the given action to (current_value, current_word)
-- "10 20 30"~reduceW("+") -- initial value is the first word (default), reduce by word, returns 60
-- "10 20 30"~reduceW(100, "+") -- initial value is 100, reduce by word, returns 160
-- Iterate over the words of the string and combine them into one value by applying the given action to (current_value, current_word, current_word_index)
-- "10 20 30"~reduceW{arg(1) + arg(2) + arg(3)} -- initial value is the first word (default), reduce by word, index passed as 3rd argument, returns 10 + 20+2 + 30+3 = 65
-- "10 20 30"~reduceW(0){arg(1) + arg(2) + arg(3)} -- initial value is 0, reduce by word, index passed as 3rd argument, returns 0 + 10+1 + 20+2 + 30+3 = 66
::method reduceW unguarded
    forward message "reduce" to (self~subwords)


-------------------------------------------------------
::class "MutableBufferReducer" mixinclass Object public
-------------------------------------------------------

-- Iterate over the characters of the mutable buffer and combine them into one value by applying the given action to (current_value, current_char)
-- .MutableBuffer~new(123)~reduceC("+") -- initial value is the first char (default), reduce by char, returns 6
-- .MutableBuffer~new(123)~reduceC(100, "+") -- initial value is 100, reduce by char, returns 106
-- Iterate over the characters of the mutable buffer and combine them into one value by applying the given action to (current_value, current_char, current_char_pos)
-- .MutableBuffer~new(567)~reduceC{arg(1) + arg(2) + arg(3)} -- initial value is the first char (default), reduce by char, index passed as 3rd argument, returns 5 + 6+2 + 7+3 = 23
-- .MutableBuffer~new(567)~reduceC(0){arg(1) + arg(2) + arg(3)} -- initial value is 0, reduce by char, index passed as 3rd argument, returns 0 + 5+1 + 6+2 + 7+3 = 24
::method reduceC unguarded
    forward message "reduce" to (self~makeArray(""))

-- Iterate over the words of the mutable buffer and combine them into one value by applying the given action to (current_value, current_word)
-- .MutableBuffer~new("10 20 30")~reduceW("+") -- initial value is the first word (default), reduce by word, returns 60
-- .MutableBuffer~new("10 20 30")~reduceW(100, "+") -- initial value is 100, reduce by word, returns 160
-- Iterate over the words of the mutable buffer and combine them into one value by applying the given action to (current_value, current_word, current_word_index)
-- .MutableBuffer~new("10 20 30")~reduceW{arg(1) + arg(2) + arg(3)} -- initial value is the first word (default), reduce by word, index passed as 3rd argument, returns 10 + 20+2 + 30+3 = 65
-- .MutableBuffer~new("10 20 30")~reduceW(0){arg(1) + arg(2) + arg(3)} -- initial value is 0, reduce by word, index passed as 3rd argument, returns 0 + 10+1 + 20+2 + 30+3 = 66
::method reduceW unguarded
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
-- .array~of(10, 20, 30)~reduce{arg(1) + arg(2) + arg(3)} -- initial value is the first item (default), index passed as 3rd argument, returns 10 + 20+2 + 30+3 = 65
-- .array~of(10, 20, 30)~reduce(0){arg(1) + arg(2) + arg(3)} -- initial value is 0, index passed as 3rd argument, returns 0 + 10+1 + 20+2 + 30+3 = 66
::method reduce unguarded
    forward to (self~supplier)


----------------------------------------------------
::class "CoactivityReducer" mixinclass Object public
----------------------------------------------------

-- Iterate over the values yielded by the coactivity and combine them into one value by applying the given action to (current_value, current_yielded_value)
-- {::coactivity .yield[10]; .yield[20]; .yield[30]}~reduce("+") -- initial value is the first item (default), returns 60
-- {::coactivity .yield[10]; .yield[20]; .yield[30]}~reduce(100, "+") -- initial value is 100, returns 160
-- Iterate over the values yielded by the coactivity and combine them into one value by applying the given action to (current_value, current_yielded_value, current_yielded_index)
-- {::coactivity .yield[10]; .yield[20]; .yield[30]}~reduce{arg(1) + arg(2) + arg(3)} -- initial value is the first item (default), index passed as 3rd argument, returns 10 + 20+2 + 30+3 = 65
-- {::coactivity .yield[10]; .yield[20]; .yield[30]}~reduce(0){arg(1) + arg(2) + arg(3)} -- initial value is 0, index passed as 3rd argument, returns 0 + 10+1 + 20+2 + 30+3 = 66
::method reduce unguarded
    forward to (self~supplier)


--------------------------------------------------
::class "SupplierReducer" mixinclass Object public
--------------------------------------------------

-- Iterate over the items of the supplier and combine them into one value by applying the given action to (current_value, current_item)
::method reduce unguarded
    if arg() == 2 then do
        use strict arg initial, action
        return self~reduceImpl(action, initial)
    end
    else do
        use strict arg action
        return self~reduceImpl(action)
    end

::method reduceImpl private unguarded
    use strict arg action, initial=.nil
    if \ self~available then return initial
    -- parse only once, before iteration
    if action~hasMethod("functionDoer") then doer = action~functionDoer("use arg accu, item, index")~arity(3)
                                        else doer = action~doer
    arity = doer~arity
    if .nil <> initial then accu = initial
    else do
        accu = self~item
        self~next
    end
    do while self~available
        if arity >=3 then doer~do(accu, self~item, self~index)
                     else doer~do(accu, self~item)
        if var("result") then accu = result
        self~next
    end
    return accu


-----------------------------------------------------------------------------
-- Mixins
-- Map
-- http://en.wikipedia.org/wiki/Map_(higher-order_function)
-- The result returned by ~map method is of the same type as the self object.
-- A String or MutableBuffer can be filtered (when no result returned by the given action).
-- A Collection can be filtered : If the given action doesn't return a result, then the current value is removed.

-----------------------------------------------
::class "StringMapper" mixinclass Object public
-----------------------------------------------

-- Iterate over the characters of the string and apply the given action to (current_char)
-- "abcdefghijklmnopqrstuvwxyz"~mapC{arg(1)~verify('aeiouy')} -- returns "01110111011111011111011101"
-- Iterate over the characters of the string and apply the given action to (current_char, current_char_pos)
-- "abcdefghijk"~mapC{arg(2)":"arg(1)" "} -- returns "1:a 2:b 3:c 4:d 5:e 6:f 7:g 8:h 9:i 10:j 11:k "
::method mapC unguarded
    use strict arg action={arg(1)}
    return .MutableBuffer~new~mapCImpl(self, action)~string

-- Not applicable to a string
--::method mapCR

-- Iterate over the words of the string and apply the given action to (current_word)
-- "one two three"~mapW{if arg(1)~length > 3 then arg(1)} -- returns "three"
-- Iterate over the words of the string and apply the given action to (current_word, current_word_index)
-- "one two three"~mapW{arg(2)":"arg(1)} -- returns "1:one 2:two 3:three"
::method mapW unguarded
    use strict arg action={arg(1)}
    return .MutableBuffer~new~mapWImpl(self, action)~string

-- Not applicable to a string
--::method mapWR


------------------------------------------------------
::class "MutableBufferMapper" mixinclass Object public
------------------------------------------------------

-- Iterate over the characters of the mutable buffer and apply the given action to (current_char)
-- .MutableBuffer~new("abcdefghijklmnopqrstuvwxyz")~mapC{arg(1)~verify('aeiouy')} -- returns "01110111011111011111011101"
-- Iterate over the characters of the mutable buffer and apply the given action to (current_char, current_char_pos)
-- .MutableBuffer~new("abcdefghijk")~mapC{arg(2)":"arg(1)" "} -- returns "1:a 2:b 3:c 4:d 5:e 6:f 7:g 8:h 9:i 10:j 11:k "
::method mapC unguarded
    use strict arg action={arg(1)}
    return .MutableBuffer~new~mapCImpl(self, action)

-- Iterate over the characters of the mutable buffer and apply the given action to (current_char) in-place
-- .MutableBuffer~new("abcdefghijklmnopqrstuvwxyz")~mapCR{arg(1)~verify('aeiouy')} -- returns "01110111011111011111011101"
-- Iterate over the characters of the mutable buffer and apply the given action to (current_char, current_char_pos) in-place
-- .MutableBuffer~new("abcdefghijk")~mapCR{arg(2)":"arg(1)" "} -- returns "1:a 2:b 3:c 4:d 5:e 6:f 7:g 8:h 9:i 10:j 11:k "
::method mapCR
    use strict arg action={arg(1)}
    return self~mapCImpl(self~string, action)

-- Iterate over the words of the mutable buffer and apply the given action to (current_char)
-- .MutableBuffer~new("one two three")~mapW{if arg(1)~length > 3 then arg(1)} -- returns "three"
-- Iterate over the words of the mutable buffer and apply the given action to (current_char, current_char_pos)
-- .MutableBuffer~new("one two three")~mapW{arg(2)":"arg(1)} -- returns "1:one 2:two 3:three"
::method mapW unguarded
    use strict arg action={arg(1)}
    return .MutableBuffer~new~mapWImpl(self, action)

-- Iterate over the words of the mutable buffer and apply the given action to (current_char) in-place
-- .MutableBuffer~new("one two three")~mapWR{if arg(1)~length > 3 then arg(1)} -- returns "three"
-- Iterate over the words of the mutable buffer and apply the given action to (current_char, current_char_pos) in-place
-- .MutableBuffer~new("one two three")~mapWR{arg(2)":"arg(1)} -- returns "1:one 2:two 3:three"
::method mapWR
    use strict arg action={arg(1)}
    return self~mapWImpl(self~string, action)

::method mapCImpl -- not private because called by String~map
    use strict arg source, action
    -- parse only once, before iteration
    if action~hasMethod("functionDoer") then doer = action~functionDoer("use arg item, index")~arity(2)
                                        else doer = action~doer
    arity = doer~arity
    self~delete(1)
    supplier = source~makearray("")~supplier -- really not optimized but...
    do while supplier~available
        if arity >= 2 then doer~do(supplier~item, supplier~index) -- Most of the time, we need only the item, that's why it's the first arg.
                      else doer~do(supplier~item)
        if var("result") then self~append(result)
        supplier~next
    end
    return self

::method mapWImpl -- not private because called by String~map
    use strict arg source, action
    -- parse only once, before iteration
    if action~hasMethod("functionDoer") then doer = action~functionDoer("use arg item, index")~arity(2)
                                        else doer = action~doer
    arity = doer~arity
    self~delete(1)
    supplier = source~subwords~supplier -- really not optimized but...
    first = .true
    do while supplier~available
        if arity >= 2 then doer~do(supplier~item, supplier~index) -- Most of the time, we need only the item, that's why it's the first arg.
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
-- .array~of(1,2,3)~map{2*arg(1) + arg(2)} -- returns .array~of(3,6,9)
::method map unguarded
    use strict arg action={arg(1)}
    return self~copy~mapImpl(self~supplier, action)

-- Iterate over the items of the collection and apply the given action to (current_item) in-place
-- .array~of(1,2,3)~mapR{2*arg(1)} -- returns .array~of(2,4,6)
-- Iterate over the items of the collection and apply the given action to (current_item, current_index) in-place
-- .array~of(1,2,3)~mapR{2*arg(1) + arg(2)} -- returns .array~of(3,6,9)
::method mapR
    use strict arg action={arg(1)}
    return self~mapImpl(self~supplier, action)

-- Always in-place (if needed, do a copy of the target collection before applying this method).
-- If no value is returned by the given action, then the current item is deleted.
::method mapImpl private
    use strict arg supplier, action
    -- parse only once, before iteration
    if action~hasMethod("functionDoer") then doer = action~functionDoer("use arg item, index")~arity(2)
                                        else doer = action~doer
    arity = doer~arity
    if self~isA(.SetCollection) | self~isA(.Relation) then self~empty
    do while supplier~available -- REMEMBER: That works good because the supplier has taken a SNAPSHOT of the collection before calling ~empty.
        newItem = supplier~item
        if arity >= 2 then doer~do(supplier~item, supplier~index) -- Most of the time, we need only the item, that's why it's the first arg.
                      else doer~do(supplier~item)
        if var("result") then do
            newItem = result
            if self~isA(.SetCollection) then self[newItem] = newItem -- special constraint : index and item must be the same object
                                        else self[supplier~index] = newItem
        end
        else do
            self~remove(supplier~index)
        end
        supplier~next
    end
    return self


-----------------------------------------------------------------------------
-- Mixins
-- Iterator, collector, filter.
-- These methods iterate over the items of the target object and apply an action to each item.
-- These methods returns an array. If you need a result object which is of the same type as the iterated object, then use ~map.

-------------------------------------------------
::class "StringIterator" mixinclass Object public
-------------------------------------------------

-- Iterate over the characters of the string and apply the given action to (current_char)
-- An array of results is returned (can be empty).
::method eachC unguarded
    forward message "each" to (self~makeArray(""))

-- Iterate over the characters of the string and apply the given action to (current_char, current_char_pos)
-- An array of pairs (result, index) is returned (can be empty).
::method eachCI unguarded
    forward message "eachI" to (self~makeArray(""))

-- Iterate over the words of the string and apply the given action to (current_word)
-- A array of results is returned (can be empty).
::method eachW unguarded
    forward message "each" to (self~subwords)

-- Iterate over the words of the string and apply the given action to (current_word, current_word_index)
-- An array of pairs (result, index) is returned (can be empty).
::method eachWI unguarded
    forward message "eachI" to (self~subwords)


--------------------------------------------------------
::class "MutableBufferIterator" mixinclass Object public
--------------------------------------------------------

-- Iterate over the characters of the mutable buffer and apply the given action to (current_char)
-- An array of results is returned (can be empty).
::method eachC unguarded
    forward message "each" to (self~makeArray(""))

-- Iterate over the characters of the mutable buffer and apply the given action to (current_char, current_char_pos)
-- An array of pairs (result, index) is returned (can be empty).
::method eachCI unguarded
    forward message "eachI" to (self~makeArray(""))

-- Iterate over the words of the mutable buffer and apply the given action to (current_word)
-- An array of results is returned (can be empty).
::method eachW unguarded
    forward message "each" to (self~subwords)

-- Iterate over the words of the mutable buffer and apply the given action to (current_word, current_word_index)
-- An array of pairs (result, word_index) is returned (can be empty).
::method eachWI unguarded
    forward message "eachI" to (self~subwords)


-----------------------------------------------------
::class "CollectionIterator" mixinclass Object public
-----------------------------------------------------

-- Iterate over the items of the collection and apply the given action to (current_item).
-- An array of results is returned (can be empty).
::method each unguarded
    forward to (self~supplier)

-- Iterate over the items of the collection and apply the given action to (current_item, current_index).
-- An array of pairs (result, index) is returned (can be empty).
::method eachI unguarded
    forward to (self~supplier)


---------------------------------------------------
::class "SupplierIterator" mixinclass Object public
---------------------------------------------------

-- Iterate over the items of the supplier and apply the given action to (current_item).
-- An array of results is returned (can be empty).
::method each unguarded
    use strict arg action={arg(1)}
    return self~eachImpl(action, .false)

-- Iterate over the items of the supplier and apply the given action to (current_item, current_index).
-- An array of pairs (result, index) is returned (can be empty).
::method eachI unguarded
    use strict arg action={arg(1)}
    return self~eachImpl(action, .true)

::method eachImpl private unguarded
    use strict arg action, returnIndex=.false
    -- parse only once, before iteration
    if action~hasMethod("functionDoer") then doer = action~functionDoer("use arg item, index")~arity(2)
                                        else doer = action~doer
    arity = doer~arity
    collectedItems = .Array~new
    do while self~available
        item = self~item
        index = self~index
        if arity >= 2 then doer~do(item, index) -- Most of the time, we need only the item, that's why it's the first arg.
                      else doer~do(item)
        if var("result") then do
            doResult = result
            if returnIndex then newItem = .array~of(doResult, index)
                           else newItem = doResult
            collectedItems~append(newItem)
        end
        self~next
    end
    return collectedItems


-----------------------------------------------------------------------------
-- Mixins
-- Filter.

-----------------------------------------------
::class "StringFilter" mixinclass Object public
-----------------------------------------------

::method dropC unguarded
    forward message "drop" to (self~makeArray(""))

::method dropCI unguarded
    forward message "dropI" to (self~makeArray(""))

::method dropLastC unguarded
    forward message "dropLast" to (self~makeArray(""))

::method dropLastCI unguarded
    forward message "dropLastI" to (self~makeArray(""))

::method dropUntilC unguarded
    forward message "dropUntil" to (self~makeArray(""))

::method dropUntilCI unguarded
    forward message "dropUntilI" to (self~makeArray(""))

::method dropWhileC unguarded
    forward message "dropWhile" to (self~makeArray(""))

::method dropWhileCI unguarded
    forward message "dropWhileI" to (self~makeArray(""))

-- Iterate over the characters of the string and reject the characters for which the given filter applied to (current_char) returns true.
-- An array of not rejected characters is returned (can be empty).
::method rejectC unguarded
    forward message "reject" to (self~makeArray(""))

-- Iterate over the characters of the string and reject the characters for which the given filter applied to (current_char, current_char_pos) returns true.
-- An array of pairs (not rejected character, char_pos) is returned (can be empty).
::method rejectCI unguarded
    forward message "rejectI" to (self~makeArray(""))

-- Iterate over the characters of the string and select the characters for which the given filter applied to (current_char) returns true.
-- An array of selected characters is returned (can be empty).
::method selectC unguarded
    forward message "select" to (self~makeArray(""))

-- Iterate over the characters of the string and select the characters for which the given filter applied to (current_char, current_char_pos) returns true.
-- An array of pairs (selected character, char_pos) is returned (can be empty).
::method selectCI unguarded
    forward message "selectI" to (self~makeArray(""))

::method takeC unguarded
    forward message "take" to (self~makeArray(""))

::method takeCI unguarded
    forward message "takeI" to (self~makeArray(""))

::method takeLastC unguarded
    forward message "takeLast" to (self~makeArray(""))

::method takeLastCI unguarded
    forward message "takeLastI" to (self~makeArray(""))

::method untilC unguarded
    forward message "until" to (self~makeArray(""))

::method untilCI unguarded
    forward message "untilI" to (self~makeArray(""))

::method whileC unguarded
    forward message "while" to (self~makeArray(""))

::method whileCI unguarded
    forward message "whileI" to (self~makeArray(""))

::method dropW unguarded
    forward message "drop" to (self~subwords)

::method dropWI unguarded
    forward message "dropI" to (self~subwords)

::method dropLastW unguarded
    forward message "dropLast" to (self~subwords)

::method dropLastWI unguarded
    forward message "dropLastI" to (self~subwords)

::method dropUntilW unguarded
    forward message "dropUntil" to (self~subwords)

::method dropUntilWI unguarded
    forward message "dropUntilI" to (self~subwords)

::method dropWhileW unguarded
    forward message "dropWhile" to (self~subwords)

::method dropWhileWI unguarded
    forward message "dropWhileI" to (self~subwords)

-- Iterate over the words of the string and reject the words for which the given filter applied to (current_word) returns true.
-- An array of not rejected words is returned (can be empty).
::method rejectW unguarded
    forward message "reject" to (self~subwords)

-- Iterate over the words of the string and reject the words for which the given filter applied to (current_word, current_word_index) returns true.
-- An array of pairs (not rejected word, word_index) is returned (can be empty).
::method rejectWI unguarded
    forward message "rejectI" to (self~subwords)

-- Iterate over the words of the string and select the words for which the given filter applied to (current_word) returns true.
-- An array of selected words is returned (can be empty).
::method selectW unguarded
    forward message "select" to (self~subwords)

-- Iterate over the words of the string and select the words for which the given filter applied to (current_word, current_word_index) returns true.
-- An array of pairs (selected word, word_index) is returned (can be empty).
::method selectWI unguarded
    forward message "selectI" to (self~subwords)

::method takeW unguarded
    forward message "take" to (self~subwords)

::method takeWI unguarded
    forward message "takeI" to (self~subwords)

::method takeLastW unguarded
    forward message "takeLast" to (self~subwords)

::method takeLastWI unguarded
    forward message "takeLastI" to (self~subwords)

::method untilW unguarded
    forward message "until" to (self~subwords)

::method untilWI unguarded
    forward message "untilI" to (self~subwords)

::method whileW unguarded
    forward message "while" to (self~subwords)

::method whileWI unguarded
    forward message "whileI" to (self~subwords)


------------------------------------------------------
::class "MutableBufferFilter" mixinclass Object public
------------------------------------------------------

::method dropC unguarded
    forward message "drop" to (self~makeArray(""))

::method dropCI unguarded
    forward message "dropI" to (self~makeArray(""))

::method dropLastC unguarded
    forward message "dropLast" to (self~makeArray(""))

::method dropLastCI unguarded
    forward message "dropLastI" to (self~makeArray(""))

::method dropUntilC unguarded
    forward message "dropUntil" to (self~makeArray(""))

::method dropUntilCI unguarded
    forward message "dropUntilI" to (self~makeArray(""))

::method dropWhileC unguarded
    forward message "dropWhile" to (self~makeArray(""))

::method dropWhileCI unguarded
    forward message "dropWhileI" to (self~makeArray(""))

-- Iterate over the characters of the mutable buffer and reject the characters for which the given filter applied to (current_char) returns true.
-- An array of not rejected characters is returned (can be empty).
::method rejectC unguarded
    forward message "reject" to (self~makeArray(""))

-- Iterate over the characters of the mutable buffer and reject the characters for which the given filter applied to (current_char, current_char_pos) returns true.
-- An array of pairs (not rejected character, char_pos) is returned (can be empty).
::method rejectCI unguarded
    forward message "rejectI" to (self~makeArray(""))

-- Iterate over the characters of the mutable buffer and select the characters for which the given filter applied to (current_char) returns true.
-- An array of selected characters is returned (can be empty).
::method selectC unguarded
    forward message "select" to (self~makeArray(""))

-- Iterate over the characters of the mutable buffer and select the characters for which the given filter applied to (current_char, current_char_pos) returns true.
-- An array of pairs (selected character, char_pos) is returned (can be empty).
::method selectCI unguarded
    forward message "selectI" to (self~makeArray(""))

::method takeC unguarded
    forward message "take" to (self~makeArray(""))

::method takeCI unguarded
    forward message "takeI" to (self~makeArray(""))

::method takeLastC unguarded
    forward message "takeLast" to (self~makeArray(""))

::method takeLastCI unguarded
    forward message "takeLastI" to (self~makeArray(""))

::method untilC unguarded
    forward message "until" to (self~makeArray(""))

::method untilCI unguarded
    forward message "untilI" to (self~makeArray(""))

::method whileC unguarded
    forward message "while" to (self~makeArray(""))

::method whileCI unguarded
    forward message "whileI" to (self~makeArray(""))

::method dropW unguarded
    forward message "drop" to (self~subwords)

::method dropWI unguarded
    forward message "dropI" to (self~subwords)

::method dropLastW unguarded
    forward message "dropLast" to (self~subwords)

::method dropLastWI unguarded
    forward message "dropLastI" to (self~subwords)

::method dropUntilW unguarded
    forward message "dropUntil" to (self~subwords)

::method dropUntilWI unguarded
    forward message "dropUntilI" to (self~subwords)

::method dropWhileW unguarded
    forward message "dropWhile" to (self~subwords)

::method dropWhileWI unguarded
    forward message "dropWhileI" to (self~subwords)

-- Iterate over the words of the mutable buffer and reject the words for which the given filter applied to (current_word) returns true.
-- An array of not rejected words is returned (can be empty).
::method rejectW unguarded
    forward message "reject" to (self~subwords)

-- Iterate over the words of the mutable buffer and reject the words for which the given filter applied to (current_word, current_word_index) returns true.
-- An array of pairs (not rejected word, word_index) is returned (can be empty).
::method rejectWI unguarded
    forward message "rejectI" to (self~subwords)

-- Iterate over the words of the mutable buffer and select the words for which the given filter applied to (current_word) returns true.
-- An array of selected words is returned (can be empty).
::method selectW unguarded
    forward message "select" to (self~subwords)

-- Iterate over the words of the mutable buffer and select the words for which the given filter applied to (current_word, current_word_index) returns true.
-- An array of pairs (selected word, word_index) is returned (can be empty).
::method selectWI unguarded
    forward message "selectI" to (self~subwords)

::method takeW unguarded
    forward message "take" to (self~subwords)

::method takeWI unguarded
    forward message "takeI" to (self~subwords)

::method takeLastW unguarded
    forward message "takeLast" to (self~subwords)

::method takeLastWI unguarded
    forward message "takeLastI" to (self~subwords)

::method untilW unguarded
    forward message "until" to (self~subwords)

::method untilWI unguarded
    forward message "untilI" to (self~subwords)

::method whileW unguarded
    forward message "while" to (self~subwords)

::method whileWI unguarded
    forward message "whileI" to (self~subwords)


---------------------------------------------------
::class "CollectionFilter" mixinclass Object public
---------------------------------------------------

-- Iterate over the items of the collection and reject the items for which the given filter applied to (current_item) returns true.
-- An array of not rejected items is returned (can be empty).
::method reject unguarded
    forward to (self~supplier)

-- Iterate over the items of the collection and reject the items for which the given filter applied to (current_item, current_index) returns true.
-- An array of pairs (not rejected item, index) is returned (can be empty).
::method rejectI unguarded
    forward to (self~supplier)

-- Iterate over the items of the collection and select the items for which the given filter applied to (current_item) returns true.
-- An array of selected items is returned (can be empty).
::method select unguarded
    forward to (self~supplier)

-- Iterate over the items of the collection and select the items for which the given filter applied to (current_item, current_index) returns true.
-- An array of pairs (selected item, index) is returned (can be empty).
::method selectI unguarded
    forward to (self~supplier)


---------------------------------------------------
::class "OrderedCollectionFilter" mixinclass Object public
---------------------------------------------------
-- If you really want to apply this kind of filters on not ordered collections
-- then do : myNotOrderedCollection~supplier~<filter>

::method drop unguarded
    forward to (self~supplier)

::method dropI unguarded
    forward to (self~supplier)

::method dropLast unguarded
    forward to (self~supplier)

::method dropLastI unguarded
    forward to (self~supplier)

::method dropUntil unguarded
    forward to (self~supplier)

::method dropUntilI unguarded
    forward to (self~supplier)

::method dropWhile unguarded
    forward to (self~supplier)

::method dropWhileI unguarded
    forward to (self~supplier)

::method take unguarded
    forward to (self~supplier)

::method takeI unguarded
    forward to (self~supplier)

::method takeLast unguarded
    forward to (self~supplier)

::method takeLastI unguarded
    forward to (self~supplier)

::method until unguarded
    forward to (self~supplier)

::method untilI unguarded
    forward to (self~supplier)

::method while unguarded
    forward to (self~supplier)

::method whileI unguarded
    forward to (self~supplier)


-------------------------------------------------
::class "SupplierFilter" mixinclass Object public
-------------------------------------------------
-- No distinction between ordered and not ordered...
-- By definition, the items returned by a supplier are ordered.

::method drop unguarded
    use strict arg count=1
    return self~dropFirstImpl(count, .false)

::method dropI unguarded
    use strict arg count=1
    return self~dropFirstImpl(count, .true)

::method dropLast unguarded
    use strict arg count=1
    return self~dropLastImpl(count, .false)

::method dropLastI unguarded
    use strict arg count=1
    return self~dropLastImpl(count, .true)

::method dropUntil unguarded
    use strict arg predicate
    return self~dropUntilImpl(predicate, .false)

::method dropUntilI unguarded
    use strict arg predicate
    return self~dropUntilImpl(predicate, .true)

::method dropWhile unguarded
    use strict arg predicate
    return self~dropWhileImpl(predicate, .false)

::method dropWhileI unguarded
    use strict arg predicate
    return self~dropWhileImpl(predicate, .true)

-- Iterate over the items of the supplier and reject the items for which the given filter applied to (current_item) returns true.
-- An array of not rejected items is returned (can be empty).
::method reject unguarded
    use strict arg predicate
    return self~rejectImpl(predicate, .false)

-- Iterate over the items of the supplier and reject the items for which the given filter applied to (current_item, current_index) returns true.
-- An array of pairs (not rejected item, index) is returned (can be empty).
::method rejectI unguarded
    use strict arg predicate
    return self~rejectImpl(predicate, .true)

-- Iterate over the items of the supplier and select the items for which the given filter applied to (current_item) returns true.
-- An array of selected items is returned (can be empty).
::method select unguarded
    use strict arg predicate
    return self~selectImpl(predicate, .false)

-- Iterate over the items of the supplier and select the items for which the given filter applied to (current_item, current_index) returns true.
-- An array of pairs (selected item, index) is returned (can be empty).
::method selectI unguarded
    use strict arg predicate
    return self~selectImpl(predicate, .true)

::method take unguarded
    use strict arg count=1
    return self~takeFirstImpl(count, .false)

::method takeI unguarded
    use strict arg count=1
    return self~takeFirstImpl(count, .true)

::method takeLast unguarded
    use strict arg count=1
    return self~takeLastImpl(count, .false)

::method takeLastI unguarded
    use strict arg count=1
    return self~takeLastImpl(count, .true)

::method until unguarded
    use strict arg predicate
    return self~takeUntilImpl(predicate, .false)

::method untilI unguarded
    use strict arg predicate
    return self~takeUntilImpl(predicate, .true)

::method while unguarded
    use strict arg predicate
    return self~takeWhileImpl(predicate, .false)

::method whileI unguarded
    use strict arg predicate
    return self~takeWhileImpl(predicate, .true)

::method dropFirstImpl private unguarded
    use strict arg count, returnIndex
    collectedItems = .Array~new
    do while count > 0, self~available
        count -= 1
        self~next
    end
    do while self~available
        item = self~item
        index = self~index
        if returnIndex then newItem = .array~of(item, index)
                       else newItem = item
        collectedItems~append(newItem)
        self~next
    end
    return collectedItems

::method dropLastImpl private unguarded
    use strict arg count, returnIndex
    collectedItems = .Array~new
    buffer = .circularQueue~new(count)
    do while self~available
        item = self~item
        index = self~index
        if returnIndex then newItem = .array~of(item, index)
                       else newItem = item
        if buffer~items == count then collectedItems~append(buffer~queue(newItem))
                                 else buffer~queue(newItem)
        self~next
    end
    return collectedItems

::method dropUntilImpl private unguarded
    use strict arg predicate, returnIndex
    if predicate~hasMethod("functionDoer") then doer = predicate~functionDoer("use arg item, index")~arity(2)
                                           else doer = predicate~doer
    arity = doer~arity
    collectedItems = .Array~new
    do while self~available
        item = self~item
        index = self~index
        self~next -- do it before testing the predicate
        if arity >= 2 then logicalValue = doer~do(item, index)
                      else logicalValue = doer~do(item)
        if logicalValue then leave
    end
    do while self~available
        item = self~item
        index = self~index
        if returnIndex then newItem = .array~of(item, index)
                       else newItem = item
        collectedItems~append(newItem)
        self~next
    end
    return collectedItems

::method dropWhileImpl private unguarded
    use strict arg predicate, returnIndex
    if predicate~hasMethod("functionDoer") then doer = predicate~functionDoer("use arg item, index")~arity(2)
                                           else doer = predicate~doer
    arity = doer~arity
    collectedItems = .Array~new
    do while self~available
        item = self~item
        index = self~index
        if arity >= 2 then logicalValue = doer~do(item, index)
                      else logicalValue = doer~do(item)
        if \ logicalValue then leave
        self~next
    end
    do while self~available
        item = self~item
        index = self~index
        if returnIndex then newItem = .array~of(item, index)
                       else newItem = item
        collectedItems~append(newItem)
        self~next
    end
    return collectedItems

::method rejectImpl private unguarded
    use strict arg action, returnIndex=.false
    -- parse only once, before iteration
    if action~hasMethod("functionDoer") then doer = action~functionDoer("use arg item, index")~arity(2)
                                        else doer = action~doer
    arity = doer~arity
    collectedItems = .Array~new
    do while self~available
        item = self~item
        index = self~index
        if arity >=2 then doer~do(item, index) -- Most of the time, we need only the item, that's why it's the first arg.
                     else doer~do(item)
        if var("result") then do
            doResult = result
            if \doResult then do
                if returnIndex then newItem = .array~of(item, index)
                               else newItem = item
                collectedItems~append(newItem)
            end
        end
        self~next
    end
    return collectedItems

::method selectImpl private unguarded
    use strict arg action, returnIndex=.false
    -- parse only once, before iteration
    if action~hasMethod("functionDoer") then doer = action~functionDoer("use arg item, index")~arity(2)
                                        else doer = action~doer
    arity = doer~arity
    collectedItems = .Array~new
    do while self~available
        item = self~item
        index = self~index
        if arity >= 2 then doer~do(item, index) -- Most of the time, we need only the item, that's why it's the first arg.
                      else doer~do(item)
        if var("result") then do
            doResult = result
            if doResult then do
                if returnIndex then newItem = .array~of(item, index)
                               else newItem = item
                collectedItems~append(newItem)
            end
        end
        self~next
    end
    return collectedItems

::method takeFirstImpl private unguarded
    use strict arg count, returnIndex
    collectedItems = .Array~new
    do while count > 0, self~available
        item = self~item
        index = self~index
        if returnIndex then newItem = .array~of(item, index)
                       else newItem = item
        collectedItems~append(newItem)
        count -= 1
        if count == 0 then leave -- stop now, to not consume datas if the count has been reached
        self~next
    end
    return collectedItems

::method takeLastImpl private unguarded
    use strict arg count, returnIndex
    buffer = .circularQueue~new(count)
    do while self~available
        item = self~item
        index = self~index
        if returnIndex then newItem = .array~of(item, index)
                       else newItem = item
        buffer~queue(newItem)
        self~next
    end
    return buffer~makeArray

::method takeUntilImpl private unguarded
    use strict arg predicate, returnIndex
    if predicate~hasMethod("functionDoer") then doer = predicate~functionDoer("use arg item, index")~arity(2)
                                           else doer = predicate~doer
    arity = doer~arity
    collectedItems = .Array~new
    do while self~available
        item = self~item
        index = self~index
        if returnIndex then newItem = .array~of(item, index)
                       else newItem = item
        collectedItems~append(newItem)
        if arity >=2 then logicalValue = doer~do(item, index)
                     else logicalValue = doer~do(item)
        if logicalValue then leave
        self~next
    end
    return collectedItems

::method takeWhileImpl private unguarded
    use strict arg predicate, returnIndex
    if predicate~hasMethod("functionDoer") then doer = predicate~functionDoer("use arg item, index")~arity(2)
                                           else doer = predicate~doer
    arity = doer~arity
    collectedItems = .Array~new
    do while self~available
        item = self~item
        index = self~index
        if arity >= 2 then logicalValue = doer~do(item, index)
                      else logicalValue = doer~do(item)
        if \ logicalValue then leave
        if returnIndex then newItem = .array~of(item, index)
                       else newItem = item
        collectedItems~append(newItem)
        self~next
    end
    return collectedItems


-----------------------------------------------------------------------------
-- Mixins
-- Repeater

-------------------------------------------------
::class "RepeaterCollector" mixinclass Object public
-------------------------------------------------

-- Repeat self times the given action (self is a number).
-- An array of results is returned (can be empty).
-- 3~times{say arg(1)} -- returns an empty array because no result returned during the iteration
-- 3~times{1} -- returns .array~of(1,1,1)
-- 3~times{arg(1)} -- returns .array~of(1,2,3)
::method times unguarded
    use strict arg action={arg(1)}
    if self~dataType("W"), self >= 0 then return 1~upto(self, 1,  .nil, action)
    raise syntax 93.900 array ("self must be zero or a positive whole number; found" self)

-- Repeat the given action from self up to upper limit (self and upper limit are numbers).
-- An array of results is returned (can be empty).
-- 11~upto(13){say arg(1)} -- returns an empty array because no result returned during the iteration
-- 11~upto(13){2*arg(1)} -- returns .array~of(22,24,26)
-- 11~upto(13) -- returns .array~of(11,12,13)
-- (-1)~upto(3) -- returns .array~of(-1,0,1,2,3) -- Note that -1 MUST be surrounded by paren or quotes
::method upto unguarded
    step = 1
    count = .nil -- no count by default
    action = {arg(1)}
    if arg() <= 1 then use strict arg limit
    else if arg() == 2 then do
        if arg(2)~isA(.String), arg(2)~dataType("N") then use arg limit, step=(step)
        else use arg limit, action=(action)
    end
    else if arg() == 3 then do
        if arg(3)~isA(.String), arg(3)~dataType("N") then use arg limit, step=(step), count=(count)
        else use arg limit, step=(step), action=(action)
    end
    else use strict arg limit, step=(step), count=(count), action=(action)
    return controlledLoop(self, limit, step, count, action)

-- Repeat the given action from self down to lower limit (self and lower limit are numbers).
-- An array of results is returned (can be empty).
-- 13~downto(11){say arg(1)} -- returns an empty array because no result returned during the iteration
-- 13~downto(11){2*arg(1)} -- returns .array~of(26,24,22)
-- 13~downto(11) -- returns .array~of(13,12,11)
-- 3~upto(-1) -- returns .array~of(3,2,1,0,-1)
::method downto unguarded
    step = -1
    count = .nil -- no count by default
    action = {arg(1)}
    if arg() <= 1 then use strict arg limit
    else if arg() == 2 then do
        if arg(2)~isA(.String), arg(2)~dataType("N") then use arg limit, step=(step)
        else use arg limit, action=(action)
    end
    else if arg() == 3 then do
        if arg(3)~isA(.String), arg(3)~dataType("N") then use arg limit, step=(step), count=(count)
        else use arg limit, step=(step), action=(action)
    end
    else use strict arg limit, step=(step), count=(count), action=(action)
    return controlledLoop(self, limit, step, count, action)

-- Shorter notation for upto (1~10) & downto (10~1)
-- when both self and the message are a number.
::method unknown unguarded
    use arg msg, args
    if self~dataType("N"), msg~dataType("N") then do
        if msg >= self then return self~sendWith("upto", args~~insert(msg, .nil))
        else return self~sendWith("downto", args~~insert(msg, .nil))
    end
    --forward class (super)
    raise syntax 97.1 array(self, msg)

::routine controlledLoop
    use strict arg from, limit, step, count, action
    -- parse only once, before iteration
    loop
        if from + step - from = step & limit + step - limit = step then leave
        numeric digits digits() + digits() % 2
    end
    if action~hasMethod("functionDoer") then doer = action~functionDoer("use arg item, digits")~arity(2)
                                        else doer = action~doer
    arity = doer~arity
    collectedItems = .array~new
    if count == .nil then do
        -- no FOR
        do i = from TO limit BY step
            if arity >= 2 then doer~do(i, digits())
                          else doer~do(i)
            if var("result") then collectedItems~append(result)
        end
    end
    else do
        if count < 0 then do
            N = (limit - from + step) % step
            N = abs(N)
            L = from + (N-1)*step
            count = abs(count)
            if count > N then count = N
            from = L - (count-1)*step
        end
        do i = from TO limit BY step FOR count
            if arity >= 2 then doer~do(i, digits())
                          else doer~do(i)
            if var("result") then collectedItems~append(result)
        end
    end
    return collectedItems
