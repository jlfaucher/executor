-- Filter
::extension Coactivity                      inherit CoactivityFilter
::extension CoactivitySupplierForGeneration inherit CoactivitySupplierForGenerationFilter

-- Iterator
::extension Coactivity                      inherit CoactivityIterator
::extension CoactivitySupplierForGeneration inherit CoactivitySupplierForGenerationIterator

-- Reducer
::extension Coactivity                      inherit CoactivityReducer

-- Generator
::extension Collection                      inherit CollectionGenerator
::extension Coactivity                      inherit CoactivityGenerator
::extension Supplier                        inherit SupplierGenerator
::extension String                          inherit TextOrBufferOrStringGenerator
::extension RexxText                        inherit TextOrBufferOrStringGenerator
::extension MutableBuffer                   inherit TextOrBufferOrStringGenerator

-- Repeater
::extension String                          inherit RepeaterGenerator

--::options trace i
::options NOMACROSPACE
::requires "concurrency/coactivity.cls"
::requires "extension/functionals.cls"


-------------------------------------------------------------------------------
-- Object can't inherit from a mixinclass (would raise "cannot inherit from itself")
::extension Object

::method generate class
    use strict arg action={item}
    return .Generator~new(self)~action(action)


::method generateI class
    use strict arg action={item}
    return .Generator~new(self)~action(action)~returnIndex


::method generate
    use strict arg action={item}
    return .Generator~new(self)~action(action)


::method generateI
    use strict arg action={item}
    return .Generator~new(self)~action(action)~returnIndex


-----------------------------------------------------------------------------
-- Mixins
-- Iterator, collector, filter.

-----------------------------------------------------
::class "CoactivityIterator" mixinclass Object public
-----------------------------------------------------

-- Iterate over the values yielded by the coactivity and apply the given action to (current_yielded_value).
-- Each result is yielded one by one.
::method each unguarded
    forward to (self~supplier)


-- Iterate over the values yielded by the coactivity and apply the given action to (current_yielded_value, current_yielded_index).
-- Each pair (result, index) is yielded one by one.
::method eachI unguarded
    forward to (self~supplier)


-----------------------------------------------------------------------
::class "CoactivitySupplierForGenerationIterator" mixinclass SupplierIterator public
-----------------------------------------------------------------------

-- Iterate over the items of the supplier and apply the given action to (current_item).
-- Each result is yielded one by one.
::method each unguarded
    use strict arg action={arg(1)}
    return self~eachImpl(action, .false)


-- Iterate over the items of the supplier and apply the given action to (current_item, current_index).
-- Each pair (result, index) is yielded one by one.
::method eachI unguarded
    use strict arg action={arg(1)}
    return self~eachImpl(action, .true)


::method eachImpl private unguarded
    use strict arg action, returnIndex=.false
    return {::coactivity
            expose action returnIndex self
            use strict arg -- none
            doer = action~doer
            arity = doer~arity
            self~firstOrNext
            do while self~available
                item = self~item
                index = self~index
                if arity == 9999   then doer~do( item,  index,-
                                                :item, :index) -- Most of the time, we need only the item, that's why it's the first arg.
                else if arity >= 2 then doer~do( item,  index)
                                   else doer~do( item)
                if var("result") then do
                    doResult = result
                    if returnIndex then newItem = .array~of(doResult, index)
                                   else newItem = doResult
                    .yield[newItem]
                end
                else .yield[]
                use strict arg -- none
                self~next
            end
           }~doer


-----------------------------------------------------------------------------
-- Mixins
-- Filter.

---------------------------------------------------
::class "CoactivityFilter" mixinclass Object public
---------------------------------------------------

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


-- Iterate over the values yielded by the coactivity and reject the values for which the given filter applied to (current_yielded_value) returns true.
-- Each not rejected item is yielded one by one.
::method reject unguarded
    forward to (self~supplier)


-- Iterate over the values yielded by the coactivity and reject the values for which the given filter applied to (current_yielded_value, current_yielded_index) returns true.
-- Each pair (not rejected item, index) is yielded one by one.
::method rejectI unguarded
    forward to (self~supplier)


-- Iterate over the values yielded by the coactivity and select the values for which the given filter applied to (current_yielded_value) returns true.
-- Each selected item is yielded one by one.
::method select unguarded
    forward to (self~supplier)


-- Iterate over the values yielded by the coactivity and select the values for which the given filter applied to (current_yielded_value, current_yielded_index) returns true.
-- Each pair (selected item, index) is yielded one by one.
::method selectI unguarded
    forward to (self~supplier)


::method takeFirst unguarded
    forward to (self~supplier)


::method take unguarded
    forward to (self~supplier)


::method takeFirstI unguarded
    forward to (self~supplier)


::method takeI unguarded
    forward to (self~supplier)


::method takeLast unguarded
    forward to (self~supplier)


::method takeLastI unguarded
    forward to (self~supplier)


::method takeUntil unguarded
    forward to (self~supplier)


::method until unguarded
    forward to (self~supplier)


::method takeUntilI unguarded
    forward to (self~supplier)


::method untilI unguarded
    forward to (self~supplier)


::method takeWhile unguarded
    forward to (self~supplier)


::method while unguarded
    forward to (self~supplier)


::method takeWhileI unguarded
    forward to (self~supplier)


::method whileI unguarded
    forward to (self~supplier)


-------------------------------------------------------------------
::class "CoactivitySupplierForGenerationFilter" mixinclass SupplierFilter public
-------------------------------------------------------------------

::method dropFirst unguarded
    use strict arg count=1
    return self~dropFirstImpl(count, .false)


::method drop unguarded
    use strict arg count=1
    return self~dropFirstImpl(count, .false)


::method dropFirstI unguarded
    use strict arg count=1
    return self~dropFirstImpl(count, .true)


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
-- Each not rejected item is yielded one by one.
::method reject unguarded
    use strict arg predicate
    return self~rejectImpl(predicate, .false)


-- Iterate over the items of the supplier and reject the items for which the given filter applied to (current_item, current_index) returns true.
-- Each pair (not rejected item, index) is yielded one by one.
::method rejectI unguarded
    use strict arg predicate
    return self~rejectImpl(predicate, .true)


-- Iterate over the items of the supplier and select the items for which the given filter applied to (current_item) returns true.
-- Each selected item is yielded one by one.
::method select unguarded
    use strict arg predicate
    return self~selectImpl(predicate, .false)


-- Iterate over the items of the supplier and select the items for which the given filter applied to (current_item, current_index) returns true.
-- Each pair (selected item, index) is yielded one by one.
::method selectI unguarded
    use strict arg predicate
    return self~selectImpl(predicate, .true)


::method takeFirst unguarded
    use strict arg count=1
    return self~takeFirstImpl(count, .false)


::method take unguarded
    use strict arg count=1
    return self~takeFirstImpl(count, .false)


::method takeFirstI unguarded
    use strict arg count=1
    return self~takeFirstImpl(count, .true)


::method takeI unguarded
    use strict arg count=1
    return self~takeFirstImpl(count, .true)


::method takeLast unguarded
    use strict arg count=1
    return self~takeLastImpl(count, .false)


::method takeLastI unguarded
    use strict arg count=1
    return self~takeLastImpl(count, .true)


::method takeUntil unguarded
    use strict arg predicate
    return self~takeUntilImpl(predicate, .false)


::method until unguarded
    use strict arg predicate
    return self~takeUntilImpl(predicate, .false)


::method takeUntilI unguarded
    use strict arg predicate
    return self~takeUntilImpl(predicate, .true)


::method untilI unguarded
    use strict arg predicate
    return self~takeUntilImpl(predicate, .true)


::method takeWhile unguarded
    use strict arg predicate
    return self~takeWhileImpl(predicate, .false)


::method while unguarded
    use strict arg predicate
    return self~takeWhileImpl(predicate, .false)


::method takeWhileI unguarded
    use strict arg predicate
    return self~takeWhileImpl(predicate, .true)


::method whileI unguarded
    use strict arg predicate
    return self~takeWhileImpl(predicate, .true)


::method dropFirstImpl private unguarded
    use strict arg count, returnIndex
    return {::coactivity
            expose count returnIndex self
            use strict arg -- none
            self~firstOrNext
            do while count > 0, self~available
                count -= 1
                self~next
            end
            do while self~available
                item = self~item
                index = self~index
                if returnIndex then newItem = .array~of(item, index)
                               else newItem = item
                .yield[newItem]
                use strict arg -- none
                self~next
            end
           }~doer


::method dropLastImpl private unguarded
    use strict arg count, returnIndex
    return {::coactivity
            expose count returnIndex self
            use strict arg -- none
            buffer = .circularQueue~new(count)
            self~firstOrNext
            do while self~available
                item = self~item
                index = self~index
                if returnIndex then newItem = .array~of(item, index)
                               else newItem = item
                if buffer~items == count then do
                    .yield[buffer~queue(newItem)]
                    use strict arg -- none
                end
                else buffer~queue(newItem)
                self~next
            end
           }~doer


::method dropUntilImpl private unguarded
    use strict arg predicate, returnIndex
    doer = predicate~doer
    return {::coactivity
            expose doer returnIndex self
            use strict arg -- none
            arity = doer~arity
            self~firstOrNext
            do while self~available
                item = self~item
                index = self~index
                self~next -- do it before testing the predicate
                if arity == 9999   then logicalValue = doer~do( item,  index,-
                                                               :item, :index)
                else if arity >= 2 then logicalValue = doer~do( item,  index)
                                   else logicalValue = doer~do( item)
                if logicalValue then leave
            end
            do while self~available
                item = self~item
                index = self~index
                if returnIndex then newItem = .array~of(item, index)
                               else newItem = item
                .yield[newItem]
                use strict arg -- none
                self~next
            end
           }~doer


::method dropWhileImpl private unguarded
    use strict arg predicate, returnIndex
    doer = predicate~doer
    return {::coactivity
            expose doer returnIndex self
            use strict arg -- none
            arity = doer~arity
            self~firstOrNext
            do while self~available
                item = self~item
                index = self~index
                if arity == 9999   then logicalValue = doer~do( item,  index,-
                                                               :item, :index)
                else if arity >= 2 then logicalValue = doer~do( item,  index)
                                   else logicalValue = doer~do( item)
                if \ logicalValue then leave
                self~next
            end
            do while self~available
                item = self~item
                index = self~index
                if returnIndex then newItem = .array~of(item, index)
                               else newItem = item
                .yield[newItem]
                use strict arg -- none
                self~next
            end
           }~doer


::method rejectImpl private unguarded
    use strict arg predicate, returnIndex=.false
    return {::coactivity
            expose predicate returnIndex self
            use strict arg -- none
            doer = predicate~doer
            arity = doer~arity
            self~firstOrNext
            do while self~available
                item = self~item
                index = self~index
                if arity == 9999   then doer~do( item,  index,-
                                                :item, :index) -- Most of the time, we need only the item, that's why it's the first arg.
                else if arity >= 2 then doer~do( item,  index)
                                   else doer~do( item)
                if var("result") then do
                    doResult = result
                    if \doResult then do
                        if returnIndex then newItem = .array~of(item, index)
                                       else newItem = item
                        .yield[newItem]
                        use strict arg -- none
                    end
                end
                self~next
            end
           }~doer


::method selectImpl private unguarded
    use strict arg predicate, returnIndex=.false
    return {::coactivity
            expose predicate returnIndex self
            use strict arg -- none
            doer = predicate~doer
            arity = doer~arity
            self~firstOrNext
            do while self~available
                item = self~item
                index = self~index
                if arity == 9999   then doer~do( item,  index,-
                                                :item, :index) -- Most of the time, we need only the item, that's why it's the first arg.
                else if arity >= 2 then doer~do( item,  index)
                                   else doer~do( item)
                if var("result") then do
                    doResult = result
                    if doResult then do
                        if returnIndex then newItem = .array~of(item, index)
                                       else newItem = item
                        .yield[newItem]
                        use strict arg -- none
                    end
                end
                self~next
            end
           }~doer


::method takeFirstImpl private unguarded
    use strict arg count, returnIndex
    return {::coactivity
            expose count returnIndex self
            use strict arg -- none
            self~firstOrNext
            do while count > 0, self~available
                item = self~item
                index = self~index
                if returnIndex then newItem = .array~of(item, index)
                               else newItem = item
                .yield[newItem]
                use strict arg -- none
                count -= 1
                if count > 0 then self~next
            end
           }~doer


::method takeLastImpl private unguarded
    use strict arg count, returnIndex
    return {::coactivity
            expose count returnIndex self
            use strict arg -- none
            buffer = .circularQueue~new(count)
            self~firstOrNext
            do while self~available
                item = self~item
                index = self~index
                if returnIndex then newItem = .array~of(item, index)
                               else newItem = item
                buffer~queue(newItem)
                self~next
            end
            s = buffer~supplier
            do while s~available
                .yield[s~item]
                use strict arg -- none
                s~next
            end
           }~doer


::method takeUntilImpl private unguarded
    use strict arg predicate, returnIndex
    doer = predicate~doer
    return {::coactivity
            expose doer returnIndex self
            use strict arg -- none
            arity = doer~arity
            self~firstOrNext
            do while self~available
                item = self~item
                index = self~index
                if returnIndex then newItem = .array~of(item, index)
                               else newItem = item
                .yield[newItem]
                use strict arg -- none
                if arity == 9999   then logicalValue = doer~do( item,  index,-
                                                               :item, :index)
                else if arity >= 2 then logicalValue = doer~do( item,  index)
                                   else logicalValue = doer~do( item)
                if logicalValue then leave
                self~next
            end
           }~doer


::method takeWhileImpl private unguarded
    use strict arg predicate, returnIndex
    doer = predicate~doer
    return {::coactivity
            expose doer returnIndex self
            use strict arg -- none
            arity = doer~arity
            self~firstOrNext
            do while self~available
                item = self~item
                index = self~index
                if arity == 9999  then logicalValue = doer~do( item,  index,-
                                                              :item, :index)
                else if arity >=2 then logicalValue = doer~do( item,  index)
                                  else logicalValue = doer~do( item)
                if \ logicalValue then leave
                if returnIndex then newItem = .array~of(item, index)
                               else newItem = item
                .yield[newItem]
                use strict arg -- none
                self~next
            end
           }~doer


-----------------------------------------------------------------------------
-- Mixins
-- Repeater

-------------------------------------------------
::class "RepeaterGenerator" mixinclass Object public
-------------------------------------------------

-- Lazy repeater : returns a coactivity.
-- Repeat self times the given action (self is a number).
-- When the action returns a result during the loop, this result is yielded.
-- The next result will be calculated only when requested.
-- c = 1000000~times.generate
-- say c~resume -- 1
-- say c~resume -- 2
-- ...
::method times.generate unguarded
    use strict arg action={arg(1)}
    if \ self~dataType("W") then raise syntax 93.900 array ("self must be zero or a positive whole number; found" self)
    if \ (self >= 0) then raise syntax 93.900 array ("self must be zero or a positive whole number; found" self)
    forward to 1 message "generate.upto" array(self, action)


-- Lazy repeater : returns a coactivity.
-- Repeat the given action from self up to upper limit (self and upper limit are numbers).
-- When the action returns a result during the loop, this result is yielded.
-- The next result will be calculated only when requested.
-- c = 11~generate.upto(1000000)
-- say c~resume -- 11
-- say c~resume -- 12
-- ...
::method generate.upto unguarded
    use strict arg upperLimit, action={arg(1)}
    if \ self~dataType("N") then raise syntax 93.900 array ("self must be a number; found" self)
    if \ upperLimit~dataType("N") then raise syntax 93.900 array ("upperLimit must be a number; found" upperLimit)
    doer = action~doer
    return {::coactivity
            expose doer upperLimit self
            use strict arg -- none
            do i = self to upperLimit
                doer~do(      i,-
                        item: i)
                if var("result") then .yield[result]; else .yield[]
                use strict arg -- none
            end
           }~doer


-- Lazy repeater : returns a coactivity.
-- Repeat the given action from self down to lower limit (self and lower limit are numbers).
-- When the action returns a result during the loop, this result is yielded.
-- The next result will be calculated only when requested.
-- c = 1000000~generate.downto(11)
-- say c~resume -- 1000000
-- say c~resume -- 999999
-- ...
::method generate.downto unguarded
    use strict arg lowerLimit, action={arg(1)}
    if \ self~dataType("N") then raise syntax 93.900 array ("self must be a number; found" self)
    if \ lowerLimit~dataType("N") then raise syntax 93.900 array ("lowerLimit must be a number; found" lowerLimit)
    doer = action~doer
    return {::coactivity
            expose doer lowerLimit self
            use strict arg -- none
            do i = self to lowerLimit by -1
                doer~do(      i,-
                        item: i)
                if var("result") then .yield[result]; else .yield[]
                use strict arg -- none
            end
           }~doer


-----------------------------------------------------------------------------
-- Mixins
-- Generator

--------------------------------------------------
::class "TextOrBufferOrStringGenerator" mixinclass object public
--------------------------------------------------

-- Yield each character one by one
::method generateC unguarded
    use strict arg action={arg(1)}
    return .Generator~new(self~characters)~iterateBefore~action(action)


-- Yield each character one by one, as a pair (char, char_pos)
::method generateCI unguarded
    use strict arg action={arg(1)}
    return .Generator~new(self~characters)~iterateBefore~action(action)~returnIndex


-- Yield each word one by one
::method generateW unguarded
    use strict arg action={arg(1)}
    return .Generator~new(self~subwords)~iterateBefore~action(action)


-- Yield each word one by one, as a pair (word, word_index)
::method generateWI unguarded
    use strict arg action={arg(1)}
    return .Generator~new(self~subwords)~iterateBefore~action(action)~returnIndex


------------------------------------------------------
::class "CollectionGenerator" mixinclass object public
------------------------------------------------------

-- Yield each item one by one
::method generate unguarded
    forward to (self~supplier)


-- Yield each item one by one, as a pair (item, index)
::method generateI unguarded
    forward to (self~supplier)


----------------------------------------------------
::class "SupplierGenerator" mixinclass Object public
----------------------------------------------------

-- Yield each item one by one
::method generate unguarded
    use strict arg action={arg(1)}
    return .Generator~new(self)~iterateBefore~action(action)


-- Yield each item one by one, as a pair (item, index)
::method generateI unguarded
    use strict arg action={arg(1)}
    return .Generator~new(self)~iterateBefore~action(action)~returnIndex


------------------------------------------------------
::class "CoactivityGenerator" mixinclass Object public
------------------------------------------------------

::method generate unguarded
    forward to (self~supplier)


::method generateI unguarded
    forward to (self~supplier)


---------------------------------------------
::class "Generator" public inherit Coactivity
---------------------------------------------

::method init
    expose action depthFirst detectCycles doer iterateBefore iterateAfter limit once pendingYieldNoResult recursive returnIndex source stackSize trace
    --say "Generator~init : self=" self self~identityHash
    self~init:super
    use strict arg source=.nil -- the seed of the generation, called "source" by analogy with pipes
    action = .nil
    depthFirst = .true
    detectCycles = .false
    doer = .nil
    iterateBefore = .false
    iterateAfter = .false
    limit = -1
    once = .false
    pendingYieldNoResult  = .false
    recursive = .false
    returnIndex = .false
    stackSize = 0
    trace = .false


::method uninit
    --say "Generator~uninit" -- Temporary, for trying to understand why the GC is not working
    self~uninit:super


::method action unguarded
    expose action trace
    if trace then .traceOutput~say("       >I> Method .Generator~action")
    if trace then trace i
    if self~isStarted then raise syntax 93.900 array(self~class~id ": has been started, too late to change the options! ")
    guard on
    use strict arg action
    return self


::method iterateBefore unguarded
    expose iterateBefore
    if self~isStarted then raise syntax 93.900 array(self~class~id ": has been started, too late to change the options! ")
    guard on
    use strict arg -- none
    iterateBefore = .true
    return self


::method iterateAfter unguarded
    expose iterateAfter
    if self~isStarted then raise syntax 93.900 array(self~class~id ": has been started, too late to change the options! ")
    guard on
    use strict arg -- none
    iterateAfter = .true
    return self


::method recursive unguarded
    expose depthFirst detectCycles limit recursive trace
    if trace then .traceOutput~say("       >I> Method .Generator~recursive")
    if trace then trace i
    if self~isStarted then raise syntax 93.900 array(self~class~id ": has been started, too late to change the options! ")
    use strict arg options=""
    guard on
    -- ([limit|depthFirst|breadthFirst|cycles][.])*
    recursive = .true
    do while options <> ""
        parse var options first "." options
        if first~dataType("W") then limit = first
        else if "breadthFirst"~caselessAbbrev(first, 1) then depthFirst = .false
        else if "cycles"~caselessAbbrev(first, 1) then detectCycles = .true
        else if "depthFirst"~caselessAbbrev(first, 1) then depthFirst = .true
        else raise syntax 93.900 array(self~class~id ": Expected a limit or 'breadthFirst' or 'cycles' or 'depthFirst. Got '"first"'")
    end
    return self


::method returnIndex unguarded
    expose returnIndex
    if self~isStarted then raise syntax 93.900 array(self~class~id ": has been started, too late to change the options! ")
    guard on
    use strict arg -- none
    returnIndex = .true
    return self


::method stack unguarded
    expose stackSize
    if self~isStarted then raise syntax 93.900 array(self~class~id ": has been started, too late to change the options! ")
    guard on
    use strict arg stackSize
    if datatype(stackSize, "W"), stackSize >= 0 then return self
    raise syntax 93.900 array("stack: argument must be an integer >= 0, got" stackSize~string)


::method trace unguarded
    expose trace
    if self~isStarted then raise syntax 93.900 array(self~class~id ": has been started, too late to change the options! ")
    guard on
    use strict arg -- none
    trace = .true
    return self


::method once unguarded
    expose once
    if self~isStarted then raise syntax 93.900 array(self~class~id ": has been started, too late to change the options! ")
    guard on
    use strict arg -- none
    once = .true
    return self


::method yieldResult private
    expose recursive returnIndex
    use strict arg item, index, depth, stack
    if returnIndex & recursive then self~yield(.array~of(item, index, depth, stack))
    else if returnIndex then self~yield(.array~of(item, index))
    else self~yield(item)
    use strict arg -- none


::method processDepthFirst.3 private
    expose detectCycles limit once recursive trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .Generator~processDepthFirst.3")
    if trace then trace i
    use strict arg item, index, previousItems, stack, depth
    if once, previousItems~hasItem(item) then return
    if recursive & depth <> limit then do
        if detectCycles, stack~hasItem(item) then return -- Recurse only if not already processed
        self~yieldResult(item, index, depth, stack)
        if once then previousItems~append(item)
        if .nil <> stack then stack~push(item)
        self~processDepthFirst.1(item, index, previousItems, stack, depth+1)
        if .nil <> stack then stack~pull
    end
    else do
        self~yieldResult(item, index, depth, stack)
        if once then previousItems~append(item)
    end


::method processDepthFirst.2 private
    expose doer iterateAfter pendingYieldNoResult trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .Generator~processDepthFirst.2")
    if trace then trace i
    use strict arg item, index, previousItems, stack, depth
    if doer~isA(.String), \item~hasMethod(doer) then return -- for convenience, a message is sent only if supported
    if pendingYieldNoResult then do
        pendingYieldNoResult = .false
        self~yield
        use strict arg -- none
    end
    arity = doer~arity
    if arity == 9999   then doer~do( item,  index,  depth,  stack,-
                                    :item, :index, :depth, :stack)
    else if arity >= 4 then doer~do( item,  index,  depth,  stack)
    else if arity == 3 then doer~do( item,  index,  depth)
    else if arity == 2 then doer~do( item,  index)
                       else doer~do( item)
    if \ var("result") then do
        -- No result returned, nothing to yield, but the yield must be done, synchronisation is important !
        -- The next calculation will be done only on resume.
        -- [JLF 8/10/2016]
        -- Today, I'm suprised to get [.nil] when running ""~generate{}~iterator~each
        -- Solution : don't yield if this is the last one (coactivity has the same behavior, see yieldLast).
        pendingYieldNoResult = .true
        return
    end
    doResult = result
    if iterateAfter, doResult~hasMethod("supplier") then do
        supplier = doResult~supplier
        do while supplier~available
            self~processDepthFirst.3(supplier~item, supplier~index, previousItems, stack, depth)
            supplier~next
        end
        -- We have iterated over a supplier. To be consistent, any "no result" must be yielded, including the last pending if any.
        if pendingYieldNoResult then do
            pendingYieldNoResult = .false
            self~yield
            use strict arg -- none
        end
    end
    else self~processDepthFirst.3(doResult, index, previousItems, stack, depth)


::method processDepthFirst.1 private
    expose iterateBefore pendingYieldNoResult trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .Generator~processDepthFirst.1")
    if trace then trace i
    use strict arg item, index, previousItems, stack, depth=0
    if iterateBefore, item~hasMethod("supplier") then do
        supplier = item~supplier
        do while supplier~available
            self~processDepthFirst.2(supplier~item, supplier~index, previousItems, stack, depth)
            supplier~next
        end
        -- We have iterated over a supplier. To be consistent, any "no result" must be yielded, including the last pending if any.
        if pendingYieldNoResult then do
            pendingYieldNoResult = .false
            self~yield
            use strict arg -- none
        end
    end
    else self~processDepthFirst.2(item, index, previousItems, stack, depth)


::method processBreadthFirst.3 private
    expose detectCycles limit once recursive trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .Generator~processBreadthFirst.3")
    if trace then trace i
    use strict arg item, index, toprocess, previousItems, stack, depth
    if once, previousItems~hasItem(item) then return
    if recursive & depth <> limit then do
        if detectCycles, stack~hasItem(item) then return -- Recurse only if not already processed
        self~yieldResult(item, index, depth, stack)
        if once then previousItems~append(item)
        toprocess~queue(item)
        toprocess~queue(index)
        if .nil <> stack then do
            stack~push(item)
            toprocess~queue(stack~copy)
            stack~pull
        end
        toprocess~queue(depth+1)
    end
    else do
        self~yieldResult(item, index, depth, stack)
        if once then previousItems~append(item)
    end


::method processBreadthFirst.2 private
    expose doer iterateAfter pendingYieldNoResult trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .Generator~processBreadthFirst.2")
    if trace then trace i
    use strict arg item, index, toprocess, previousItems, stack, depth
    if doer~isA(.String), \item~hasMethod(doer) then return -- for convenience, a message is sent only if supported
    if pendingYieldNoResult then do
        pendingYieldNoResult = .false
        self~yield
        use strict arg -- none
    end
    arity = doer~arity
    if arity == 9999   then doer~do( item,  index,  depth,  stack,-
                                    :item, :index, :depth, :stack)
    else if arity >= 4 then doer~do( item,  index,  depth,  stack)
    else if arity == 3 then doer~do( item,  index,  depth)
    else if arity == 2 then doer~do( item,  index)
                       else doer~do( item)
    if \ var("result") then do
        -- No result returned, nothing to yield, but the yield must be done, synchronisation is important !
        -- The next calculation will be done only on resume.
        -- [JLF 8/10/2016]
        -- Today, I'm suprised to get [.nil] when running ""~generate{}~recursive("b")~iterator~each
        -- Solution : don't yield if this is the last one (coactivity has the same behavior, see yieldLast).
        pendingYieldNoResult = .true
        return
    end
    doResult = result
    if iterateAfter, doResult~hasMethod("supplier") then do
        supplier = doResult~supplier
        do while supplier~available
            self~processBreadthFirst.3(supplier~item, supplier~index, toprocess, previousItems, stack, depth)
            supplier~next
        end
        -- We have iterated over a supplier. To be consistent, any "no result" must be yielded, including the last pending if any.
        if pendingYieldNoResult then do
            pendingYieldNoResult = .false
            self~yield
            use strict arg -- none
        end
    end
    else self~processBreadthFirst.3(doResult, index, toprocess, previousItems, stack, depth)


::method processBreadthFirst.1 private
    expose iterateBefore pendingYieldNoResult trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .Generator~processBreadthFirst.1")
    if trace then trace i
    use strict arg item, index, previousItems, stack
    toprocess = .queue~new
    depth = 0
    do forever
        if iterateBefore, item~hasMethod("supplier") then do
            supplier = item~supplier
            do while supplier~available
                self~processBreadthFirst.2(supplier~item, supplier~index, toprocess, previousItems, stack, depth)
                supplier~next
            end
            -- We have iterated over a supplier. To be consistent, any "no result" must be yielded, including the last pending if any.
            if pendingYieldNoResult then do
                pendingYieldNoResult = .false
                self~yield
                use strict arg -- none
            end
        end
        else self~processBreadthFirst.2(item, index, toprocess, previousItems, stack, depth)
        if toprocess~isEmpty then leave
        item = toprocess~pull
        index = toprocess~pull
        if .nil <> stack then stack = toprocess~pull
        depth = toprocess~pull
    end


::method action2doer private
    expose trace
    if trace then .traceOutput~say("       >I> Method .Generator~action2doer")
    if trace then trace i
    use strict arg action
    if .nil == action then action = {arg(1)}
    return action~doer


::method main
    expose action depthFirst detectCycles doer once recursive source stackSize trace
    use strict arg -- none
    doer = self~action2doer(action)
    action = .nil -- to let GC
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .Generator~main")
    if trace then do -- additional info
        doerSource = doer~source
        .traceOutput~say("-"~copies(20))
        if doerSource~isa(.array) then .traceOutput~say(doerSource~tostring)
                            else .traceOutput~say(doerSource)
        .traceOutput~say("-"~copies(20))
    end
    if trace then trace i
    previousItems = .nil
    if once then previousItems = .array~new
    stack = .nil
    if detectCycles then stack = .queue~new -- no limit, remember all the calculated items whatever the value of stackSize
    else if stackSize > 0 then stack = .circularQueue~new(stackSize) -- remember the <stackSize> last calculated items.
    if depthFirst then self~processDepthFirst.1(source, 1, previousItems, stack)
                  else self~processBreadthFirst.1(source, 1, previousItems, stack)


::class jlf public inherit Coactivity
/*
Temporary, for trying to understand why the GC is not working
*/

::method init
    expose action doer trace source
    say "jlf~init : self=" self self~identityHash
    self~init:super
    --forward class (super) continue
    use strict arg source=.nil -- the seed of the generation, called "source" by analogy with pipes
    action = .nil
    doer = .nil
    trace = .false


::method uninit
    say "jlf~uninit"
    self~uninit:super


::method action unguarded
    expose action trace
    if trace then .traceOutput~say("       >I> Method .jlf~action")
    if trace then trace i
    if self~isStarted then raise syntax 93.900 array(self~class~id ": has been started, too late to change the options! ")
    guard on
    use strict arg action
    return self


::method trace unguarded
    expose trace
    if self~isStarted then raise syntax 93.900 array(self~class~id ": has been started, too late to change the options! ")
    guard on
    use strict arg -- none
    trace = .true
    return self


::method action2doer private
    expose trace
    if trace then .traceOutput~say("       >I> Method .jlf~action2doer")
    if trace then trace i
    use strict arg action
    if .nil == action then action = {arg(1)}
    return action~doer


::method main
    expose action doer source trace
    use strict arg -- none
    doer = self~action2doer(action)
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .jlf~main")
    if trace then do -- additional info
        doerSource = doer~source
        .traceOutput~say("-"~copies(20))
        if doerSource~isa(.array) then .traceOutput~say(doerSource~tostring)
                            else .traceOutput~say(doerSource)
        .traceOutput~say("-"~copies(20))
    end
    if trace then trace i
    doer~do(source)
    action = .nil
    doer = .nil
    if \ var("result") then do
        -- No result returned, nothing to yield, but the yield must be done, synchronisation is important !
        -- The next calculation will be done only on resume.
        self~yield
        use strict arg -- none
        return
    end
    else do
        self~yield(result)
        use strict arg -- none
    end
    say "jlf~main is ended"

