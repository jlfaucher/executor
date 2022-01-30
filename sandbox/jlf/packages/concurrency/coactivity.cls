/*
Coactivity is an emulation of coroutines in ooRexx.
This script needs a modified ooRexx interpreter, because depends on :
.context~parentContext
.context~setargs(<array>, <directory>)
.threadLocal

This is not a "real" coroutine implementation, because it's based on ooRexx activities
and synchronization. But at least you have all the functionalities of stackful
asymmetric coroutines (resume + yield). All is in place to support symmetric coroutines
(yield only), but the scheduler remains to implement.

Coroutines are a programming language concept that allows for explicit, cooperative
and stateful switching between subroutines. The advantage of real coroutine over
threads is that they do not have to be synchronized because they pass control to
each other explicitly and deterministically.
*/


--::options trace i
--::options NOMACROSPACE


--------------------------------------------------------------------------------
-- .yield[value] is more compact than .Coactivity~yield(value)
::class "yield" public
::method "[]" class unguarded
    forward message ("yield") to (.Coactivity)


-- Another way to yield : call yield [value]
::routine yield public
    .Coactivity~sendWith("yield", arg(1, "a"))


--------------------------------------------------------------------------------
-- This is a WeakReference which forwards the messages to its value.
-- To move elsewhere, probably (not restricted to coactivies).
::class "WeakProxy" public subclass WeakReference
::method unknown
    use arg msg, args
    forward to (self~value) message (msg) arguments (args)


--------------------------------------------------------------------------------
/*
To let a coactivity's thread be stopped when the coactivity is GC'ed, must use two separated objects :
- An instance of Coactivity, visible by the end-user.
  Wrapper of a CoactivityObj instance.
  Runs in the thread of the end-user.
  Forwards almost all its messages to the wrapped CoactivityObj instance.
- An instance of CoactivityObj, hidden from the end-user.
  The methods of this instance run on a separate thread.
  This thread is automatically stopped when the wrapping Coactivity is GC'ed.
*/
::class "Coactivity" mixinclass Object public

-- Class attributes
--::attribute globalCache class private -- contains all the active coactivities


::method init class
    expose globalCache
    -- Using a Directory instead of an IdentityTable because of the experimentation with WeakReferences.
    globalCache = .Directory~new


::method register class
    expose globalCache
    use strict arg coactivityObj -- Remember : don't register the proxy ! that would forbid GC
    -- Remember : A weak reference is useless here because only started-not-(ended-killed) coactivities
    -- are referenced by this cache, and a started-not-(ended-killed) coactivity can't be GC'ed because
    -- (by definition) its start method is running and the self variable references the coactivity.
    globalCache[coactivityObj~identityHash] = coactivityObj


::method unregister class
    expose globalCache
    use strict arg coactivityObj
    globalCache~remove(coactivityObj~identityHash)


::method count class
    expose globalCache
    return globalCache~items


::method all class
    expose globalCache
    return globalCache~allItems


::method endAll class
    expose globalCache
    count = 0
    do coactivityObj over globalCache~allItems
        if coactivityObj~end then count += 1
    end
    return count


::method killAll class
    expose globalCache
    count = 0
    do coactivityObj over globalCache~allItems
        if coactivityObj~kill then count += 1
    end
    return count


::method init
    /*
    The coactivity entry can be a routine, a couple (message, object) or a couple (method, object).
    The default entry is the couple ("main", self).
    By default, the coactivity is not started (the 'start' method is not called)
    */
    expose coactivityObj
    proxy = .WeakProxy~new(self)
    use strict arg action="main", start=.false, object=(proxy) -- object must reference the proxy, not directly the coactivity, otherwise the coactivity will never be GC'ed

    -- pass itself as proxy, to be stored on the wrapped coactivityObj (needed for supplier)
    coactivityObj = .CoactivityObj~new(action, start, object, proxy)


::method uninit
    expose coactivityObj
    coactivityObj~end
    coactivityObj = .nil -- strange !!!! Without this assignment, I *NEVER* see a call to CoactivityObj~uninit


--::method unknown
    -- I don't define the unknown method because (for the moment) .Coactivity is a mixin class.
    -- I don't think it's a good idea to inherit an unknown method from a mixin class, knowing
    -- that it's not unusual to inherit from several mixin classes.


::method executable unguarded
    expose coactivityObj
    forward to (coactivityObj)


::method start -- was declared unguarded because of deadlock4, but finally better to keep it guarded and declare ~yield unguarded
    /*
    Create the activity that will control the coactivity and make it suspended.
    Use 'resume' to start the coactivity effectively.
    The arguments passed to 'resume' will be made available to the coactivity through 'use arg'.
    */
    expose coactivityObj
    forward to (coactivityObj)


::method main abstract
    -- Default entry point of the coactivity, to be implemented in a subclass
    -- (The subclassing is optional. You can use any doer as entry point).


::method yield class unguarded -- unguarded because of deadlock4
    /*
    Helper method to let yield from any nested invocation
    (i.e. directly or indirectly called by the coactivity 'start' method).
    The goal is to retrieve the coactivity instance and send it the message yield.
    myCoactivity~start  <--------------+
        invocation                     |
            invocation                 |
                ...                    |
                    invocation : .Coactivity~yield()
    */
    coactivityObj = .threadLocal["coactivity"]
    if .nil == coactivityObj then raise syntax 93.900 array ("yield can be used only from a coactivity")
    forward to (coactivityObj)


::method yield private unguarded -- unguarded because of deadlock4
    -- Can be called only from a coactivity.
    -- Update the arguments of the caller's context with the arguments passed to 'resume' by the client of the coactivity.
    expose coactivityObj
    forward to (coactivityObj)


::method currentIndexItem
    expose coactivityObj
    forward to (coactivityObj)


::method resume -- MUST be guarded ! If unguarded then the same value could be returned to different concurrent clients
                -- Remember : Was declared unguarded to fix deadlock4 but that was a bad decision. Now, yield is unguarded.
    -- You can pass arguments to this method.
    -- They will be passed to the coactivity, which can retrieve them with 'use arg'.
    -- Returns the value yielded by the coactivity.
    expose coactivityObj
    forward to (coactivityObj)


::method resumeWithIndex -- MUST be guarded !
    -- Like ~resume, but the result is an array of (item, index)
    expose coactivityObj
    forward to (coactivityObj)


::method end
    expose coactivityObj
    forward to (coactivityObj)


::method kill
    expose coactivityObj
    forward to (coactivityObj)


::method isStarted unguarded
    expose coactivityObj
    forward to (coactivityObj)


::method isAlive unguarded
    expose coactivityObj
    forward to (coactivityObj)


::method isEnded unguarded
    expose coactivityObj
    forward to (coactivityObj)


::method isKilled unguarded
    expose coactivityObj
    forward to (coactivityObj)


::method statusText unguarded
    expose coactivityObj
    forward to (coactivityObj)


::method supplier unguarded
    expose coactivityObj
    forward to (coactivityObj)


::method iterator unguarded
    expose coactivityObj
    forward to (coactivityObj)


::method makeArray unguarded
    -- This is the only way to write : do item over myCoactivity ...
    -- A better approach would be to modify the interpreter to support : do item over anySupplier ...
    expose coactivityObj
    forward to (coactivityObj)


--------------------------------------------------------------------------------
::class "CoactivityObj"

/*
Status transitions :
    notStarted --> running | ended | killed
    running --> suspended | ended | killed
    suspended --> running | ended | killed
*/
::constant notStarted 0
::constant suspended 1
::constant running 2
::constant ended 3
::constant killed 4

-- Instance attributes for entry point
-- ::attribute doer private
-- ::attribute object private

-- Instance attributes for execution
-- ::attribute proxy private
-- ::attribute status private
-- ::attribute arguments private
-- ::attribute namedArguments private
-- ::attribute yieldItem private
-- ::attribute yieldIndex private


::method init unguarded
    expose doer object proxy status yieldIndex
    use strict arg action, start, object, proxy
    doer = action~doer
    status = .CoactivityObj~notStarted
    yieldIndex = 0
    if start then self~start


::method uninit
    -- If no longer referenced, then can stop the coactivity
    -- (but will never happen, see the comment in ~register)
    self~end


::method executable unguarded
    expose doer
    return doer


::method start
    expose arguments namedArguments doer object status
    use strict arg -- no arg
    if status <> .CoactivityObj~notStarted then return
    status = .CoactivityObj~suspended
    reply self
    .threadLocal["coactivity"] = self
    .Coactivity~register(self)
    signal on any name trapCondition -- catch all
    signal on syntax name trapCondition -- gives better messages
    guard off
    guard on when status <> .CoactivityObj~suspended
    if status == .CoactivityObj~running then do
        guard off
        -- arguments and namedArguments are coming from 'resume' (the first resume activates the coactivity)
        if doer~needsObject then doer~doWith(object, arguments, namedArguments: namedArguments) -- object needed (message, method)
        else doer~doWith(arguments, namedArguments: namedArguments) -- no object needed (routine)
        guard on
        if var("result") then self~yieldLast(result)
        else self~yieldLast
        status = .CoactivityObj~ended
    end
    trapCondition:
    self~kill -- maybe already killed or ended
    .Coactivity~unregister(self)
    -- Fighting against objects which are not GC'ed...
    -- Should be done in uninit, but uninit rarely called by the interpreter...
    arguments = .nil
    namedArguments = .nil
    doer = .nil -- I was surprised to get .nil when doing myBlock~executable~executable after the end of {::cl.co}
                -- but no choice... If I don't do this assignment, some coactivities are never GC'ed.
    object = .nil
    if self~isKilled & .nil <> condition("o") then raise propagate


::method yield --private
    expose arguments namedArguments status yieldIndex yieldItem
    drop yieldItem
    if status == .CoactivityObj~killed then raise syntax 93.900 array ("Can't yield, the coactivity is killed") -- this is to unwind any nested invocation and return to 'start'
    if status == .CoactivityObj~ended then raise syntax 93.900 array ("Can't yield, the coactivity is ended") -- this is to unwind any nested invocation and return to 'start'
    if arg() <> 0 then do
        use strict arg yieldItem -- yieldItem will be returned to the Coactivity's client by 'resume'
        yieldIndex += 1
    end
    status = .CoactivityObj~suspended
    guard off
    guard on when status <> .CoactivityObj~suspended
    if status == .CoactivityObj~killed then raise syntax 93.900 array ("The coactivity has been killed") -- this is to unwind any nested invocation and return to 'start'
    if status == .CoactivityObj~ended then raise syntax 93.900 array ("The coactivity has been ended") -- this is to unwind any nested invocation and return to 'start'
    -- Update the arguments of the caller's context
    -- Must unwind until we reach a context whose package is not the current package.
    context = .context
    currentPackage = context~package
    do while .nil <> context, context~package == currentPackage -- search for the first context outside this package
        context = context~parentContext -- .nil if native or top-level activation.
    end
    if .nil == context then raise syntax 93.900 array ("Can't update the arguments, yield's context not found")
    context~setargs(arguments, n:namedArguments) -- assigns the positional and named arguments that the coactivity's client passed to 'resume'


::method yieldLast private
    /*
    Internal method called when the coactivity action has returned.
    */
    expose yieldIndex yieldItem
    drop yieldItem
    if arg() <> 0 then do
        use strict arg yieldItem -- yieldItem will be returned to the coactivity's client by 'resume'
        yieldIndex += 1
    end


::method currentIndexItem
    expose yieldIndex yieldItem
    if self~isAlive then do
        if var("yieldItem") then return .array~of(yieldIndex, yieldItem)
    end


::method resume
    expose arguments namedArguments status yieldItem
    if status == .CoactivityObj~notStarted then self~start
    if status == .CoactivityObj~killed then raise syntax 93.900 array ("Coactivity is killed")
    if status == .CoactivityObj~ended then return -- raise syntax 93.900 array ("Coactivity is ended")
    arguments = .context~args
    namedArguments = .context~namedArgs
    status = .CoactivityObj~running
    guard off
    guard on when status <> .CoactivityObj~running
    if status == .CoactivityObj~killed then raise syntax 93.900 array ("Coactivity is killed")
    if var("yieldItem") then return yieldItem


::method resumeWithIndex
    expose arguments namedArguments status yieldIndex yieldItem
    if status == .CoactivityObj~notStarted then self~start
    if status == .CoactivityObj~killed then raise syntax 93.900 array ("Coactivity is killed")
    if status == .CoactivityObj~ended then return -- raise syntax 93.900 array ("Coactivity is ended")
    arguments = .context~args
    namedArguments = .context~namedArgs
    status = .CoactivityObj~running
    guard off
    guard on when status <> .CoactivityObj~running
    if status == .CoactivityObj~killed then raise syntax 93.900 array ("Coactivity is killed")
    if var("yieldItem") then return .array~of(yieldItem, yieldIndex)


::method end
    expose status
    if status == .CoactivityObj~ended then return .false
    if status == .CoactivityObj~killed then return .false
    -- A not started coactivity can be ended, to forbid its starting.
    status = .CoactivityObj~ended
    return .true


::method kill
    expose status
    if status == .CoactivityObj~ended then return .false
    if status == .CoactivityObj~killed then return .false
    -- A not started coactivity can be killed, to forbid its starting.
    status = .CoactivityObj~killed
    return .true


::method isStarted unguarded
    expose status
    return status <> .CoactivityObj~notStarted


::method isAlive unguarded
    expose status
    return status == .CoactivityObj~suspended | status == .CoactivityObj~running


::method isEnded unguarded
    expose status
    -- For convenience, test also killed. After all, a killed coactivity is ended...
    return status == .CoactivityObj~ended | status == .CoactivityObj~killed


::method isKilled unguarded
    expose status
    return status == .CoactivityObj~killed


::method statusText unguarded
    expose status
    select
        when status == .CoactivityObj~notStarted then return "not started"
        when status == .CoactivityObj~suspended then return "suspended"
        when status == .CoactivityObj~running then return "running"
        when status == .CoactivityObj~ended then return "ended"
        when status == .CoactivityObj~killed then return "killed"
        otherwise return "unknown"
    end


::method supplier unguarded
    expose proxy
    return .CoactivitySupplierForGeneration~new(proxy~value) -- must pass the wrapping coactivity, not self, otherwise the coactivity may be GC'ed even if the supplier is running and not GC'ed


::method iterator unguarded
    expose proxy
    return .CoactivitySupplierForIteration~new(proxy~value) -- must pass the wrapping coactivity, not self, otherwise the coactivity may be GC'ed even if the supplier is running and not GC'ed


::method makeArray unguarded
    -- The count parameter gives the maximal number of items in the array.
    -- This is not the number of resumes, which can be greater if no result returned sometimes.
    use strict arg count=(-1)
    array = .Array~new
    do forever
        if count >=0, array~dimension(1) >= count then do
            -- Better to not end the coactivity : makeArray is like clojure's take or like the pipestage .take
            -- self~end
            leave
        end
        self~resume
        if var("result") then array~append(result)
        -- Remember : don't append .nil when no result.
        -- I don't want to get an array of thousands .nil when no result returned by a coactivity which is resumed thousands times.
        if \ self~isAlive then leave
    end
    return array


--------------------------------------------------------------------------------
/*
Coactivity supplier :
This supplier does not take a snapshot of the items remaining to generate by the coactivity.
Instead, it calculates the next item only when the 'next' method is called.

No longer needs an uninit method to support properly this use case (the coactivity itself knows when to end automatically) :
.coactivity~new{i=0; do forever; i+=1; .yield[i]; end}~pipe(.take 5 | .console)
While the pipeline is running, the coactivity supplier is referenced by the 'source' property of the first pipe stage, and can't be GC'ed.
The pipeline itself can't be GC'ed because the first pipe stage is referenced from the call stack, as an argument of 'pipe'.
When 5 values have been taken (.take 5), the pipeline is stopped and the method 'pipe' returns.
From now, the pipeline can be GC'ed, because it's no longer referenced from the call stack.
And once the pipeline is GC'ed, there is no more reference to the coactivity supplier, which can be GC'ed.

Special note about ~refresh.
This method aligns the cached index/item with the current index/item of the coactivity.
The method ~available is doing a refresh.
And that's enough to have the most recent index/item when your code is like that:
    do while supplier~available
        item = supplier~item
        index = supplier~index
        ...
        supplier~next
    end

*/
::class "CoactivitySupplier" public subclass Supplier

--::attribute coactivity private
--::attribute currentIndex private
--::attribute currentItem private
--::attribute isAvailable private


::method init
    expose coactivity isAvailable
    use strict arg coactivity
    empty = .array~new(0) -- Lazy supplier
    self~init:super(empty, empty)
    --self~first -- Too early ! The first call to ~first must be done from ~available
    isAvailable = -1 -- special value to indicate that ~next must be executed


::method available
    expose isAvailable
    if isAvailable == -1 then self~first
    else self~refresh
    return isAvailable


::method index
    expose currentIndex isAvailable
    if isAvailable == -1 then self~first
    -- else self~refresh    -- DON'T REFRESH! ~index and ~item must be ALWAYS consistent together, and consistent with ~available
    if isAvailable then return currentIndex


::method item
    expose currentItem isAvailable
    if isAvailable == -1 then self~first
    -- else self~refresh    -- DON'T REFRESH! ~index and ~item must be ALWAYS consistent together, and consistent with ~available
    if isAvailable then return currentItem


::method first private
    expose coactivity currentIndex currentItem isAvailable

    isAvailable = .false
    if coactivity~isStarted then do
        -- A new supplier can be created from a coactivity already started.
        -- In this case, don't use resume otherwise the current item would be skipped.
        coactivity~currentIndexItem
        if var("result") then do
            currentIndex = result[1]
            currentItem = result[2]
            isAvailable = .true
            return
        end
    end
    else do
        coactivity~resumeWithIndex
        if var("result") then do
            currentItem = result[1]
            currentIndex = result[2]
            isAvailable = .true
            return
        end
    end
    if coactivity~isAlive then do
        -- If no result returned by the coactivity, then item=.nil and index=.nil
        -- This is conform to the description of .Supplier~new :
        -- The supplier iterates for the number of items contained in the values array,
        -- returning the Nil object for any nonexistent items in either array.
        currentItem = .nil
        currentIndex = .nil -- By testing index==.nil, you know that the coactivity yielded no item
        isAvailable = .true
    end


::method refresh private
    expose coactivity currentIndex currentItem isAvailable

    isAvailable = .false
    coactivity~currentIndexItem
    if var("result") then do
        currentIndex = result[1]
        currentItem = result[2]
        isAvailable = .true
        return
    end
    if coactivity~isAlive then do
        -- If no result returned by the coactivity, then item=.nil and index=.nil
        -- This is conform to the description of .Supplier~new :
        -- The supplier iterates for the number of items contained in the values array,
        -- returning the Nil object for any nonexistent items in either array.
        currentItem = .nil
        currentIndex = .nil -- By testing index==.nil, you know that the coactivity yielded no item
        isAvailable = .true
    end


::method next
    expose coactivity currentIndex currentItem isAvailable

    -- to be consistent with a supplier of collection : s=collection~supplier; s~next; s~item returns the SECOND item
    -- without this line, we would have the FIRST item
    if \ coactivity~isStarted then coactivity~resume

    isAvailable = .false
    coactivity~resumeWithIndex
    if var("result") then do
        currentItem = result[1]
        currentIndex = result[2]
        isAvailable = .true
    end
    else if coactivity~isAlive then do
        -- If no result returned by the coactivity, then item=.nil and index=.nil
        -- This is conform to the description of .Supplier~new :
        -- The supplier iterates for the number of items contained in the values array,
        -- returning the Nil object for any nonexistent items in either array.
        currentItem = .nil
        currentIndex = .nil -- By testing index==.nil, you know that the coactivity yielded no item
        isAvailable = .true
    end


-- Helper for generators: called before entering the generation loop
-- Manages the case when the coactivity is still at first step: don't consume, to return the first item.
/*
g1 = {::coactivity loop i=0; call yield i; end}; g2 = g1~each:.CoactivityIterator -- bypass .object~each which returns an array
g2~()   -- 0    -- don't consume
g1~()   -- 1
g1 = {::coactivity loop i=0; call yield i; end}; g2 = g1~each:.CoactivityIterator -- bypass .object~each which returns an array
g1~()   -- 0
g2~()   -- 1    -- consume (without firstOrNext, would return 0)
*/
::method firstOrNext
    expose coactivity
    if coactivity~isStarted then self~next


-- Two public subclasses : one for generation, one for iteration
::class "CoactivitySupplierForGeneration" public subclass CoactivitySupplier
::class "CoactivitySupplierForIteration" public subclass CoactivitySupplier


/*
Problem with iterator of coactivity ? no...
After adding the method refresh, I get results that are correctly aligned with
the coactivity: the index/item cached on the iterator is refreshed to get the
current index/item of the coactivity.

g={::co loop i=1; .yield[i]; end}
i=g~iterator
i~take(10)=     -- [1,2,3,4,5,6,7,8,9,10]
g~currentIndexItem= -- [11,11]
g~()=           -- 12
i~take(10)=     -- [12,13,14,15,16,17,18,19,20,21]
g~currentIndexItem= -- [22,22]
g~()=           -- 23
g~()=           -- 24
i~take(10)=     -- [24,25,26,27,28,29,30,31,32,33]

After code review, no problem...
See takeFirstImpl in functional.cls

g={::co loop i=1; .yield[i]; end}
i=g~iterator
i~take(10)=     -- [1,2,3,4,5,6,7,8,9,10]
i~take(10)=     -- [11,12,13,14,15,16,17,18,19,20]
i~take(10)=     -- [21,22,23,24,25,26,27,28,29,30]


Same behaviour with supplier...
g={::co loop i=1; .yield[i]; end}
s=g~supplier
s~take(10)~iterator~each=       -- [1,2,3,4,5,6,7,8,9,10]
s~take(10)~iterator~each=       -- [11,12,13,14,15,16,17,18,19,20]
s~take(10)~iterator~each=       -- [21,22,23,24,25,26,27,28,29,30]

Same behaviour when working directly with the coactivity...
Behind the scene, a supplier is used...
A new supplier is created at each invocation of ~take.
g={::co loop i=1; .yield[i]; end}
g~take(10)~iterator~each=       -- [1,2,3,4,5,6,7,8,9,10]
g~currentIndexItem=             -- [10,10]
g~take(10)~iterator~each=       -- [11,12,13,14,15,16,17,18,19,20]
g~take(10)~iterator~each=       -- [21,22,23,24,25,26,27,28,29,30]

*/
