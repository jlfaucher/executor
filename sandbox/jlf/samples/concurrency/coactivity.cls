/*
Coactivity is an emulation of coroutines in ooRexx.
This script needs a modified ooRexx interpreter, because depends on :
.context~args = <array>
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
    coactivityObj = .CoactivityObj~new(action, start, object, proxy) -- pass itself as proxy, to be stored on the wrapped coactivityObj (needed for supplier)


::method uninit
    expose coactivityObj
    coactivityObj~end


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
    The arguments passed to the first 'resume' will be made available to the coactivity through the traditional 'use arg'.
    The arguments passed to the next 'resume's will be made available as an array returned by 'yield'.
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
    if coactivityObj == .nil then raise syntax 93.900 array ("yield can be used only from a coactivity")
    forward to (coactivityObj)


::method yield private unguarded -- unguarded because of deadlock4
    -- Can be called only from a coactivity.
    -- Returns an array which contains the arguments passed to 'resume' by the client of the coactivity.
    expose coactivityObj
    forward to (coactivityObj)


::method resume -- MUST be guarded ! If unguarded then the same value could be returned to different concurrent clients
                -- Remember : Was declared unguarded to fix deadlock4 but that was a bad decision. Now, yield is unguarded.
    -- You can pass arguments to this method.
    -- They will be passed to the coactivity, either as traditional 'use arg' if first call, or as an array returned by 'yield'.
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
    expose arguments doer object status
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
        -- arguments are coming from 'resume' (the first resume activates the coactivity)
        if doer~needsObject then doer~doWith(object, arguments) -- object needed (message, method)
        else doer~doWith(arguments) -- no object needed (routine)
        guard on
        if var("result") then self~yieldLast(result)
        else self~yieldLast
        status = .CoactivityObj~ended
    end
    trapCondition:
    self~kill -- maybe already killed or ended
    if self~hasMethod("onTerminate") then self~onTerminate
    .Coactivity~unregister(self)
    if self~isKilled & condition("o") <> .nil then raise propagate


::method yield --private
    expose arguments status yieldIndex yieldItem
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
    do while context <> .nil, context~package == currentPackage -- search for the first context outside this package
        context = context~parentContext -- .nil if native or top-level activation.
    end
    if context == .nil then raise syntax 93.900 array ("Can't update the arguments, yield's context not found")
    context~args = arguments -- assigns the arguments that the coactivity's client passed to 'resume'


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


::method resume
    expose arguments status yieldItem
    if status == .CoactivityObj~notStarted then self~start
    if status == .CoactivityObj~killed then raise syntax 93.900 array ("Coactivity is killed")
    if status == .CoactivityObj~ended then return -- raise syntax 93.900 array ("Coactivity is ended")
    arguments = arg(1, "a")
    status = .CoactivityObj~running
    guard off
    guard on when status <> .CoactivityObj~running
    if status == .CoactivityObj~killed then raise syntax 93.900 array ("Coactivity is killed")
    if var("yieldItem") then return yieldItem


::method resumeWithIndex
    expose arguments status yieldIndex yieldItem
    if status == .CoactivityObj~notStarted then self~start
    if status == .CoactivityObj~killed then raise syntax 93.900 array ("Coactivity is killed")
    if status == .CoactivityObj~ended then return -- raise syntax 93.900 array ("Coactivity is ended")
    arguments = arg(1, "a")
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
    return status == .CoactivityObj~ended


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
    --self~next -- Too early ! The first call to ~next must be done from ~available
    isAvailable = -1 -- special value to indicate that ~next must be executed


::method available
    expose isAvailable
    if isAvailable == -1 then self~next
    return isAvailable


::method index
    expose currentIndex isAvailable
    if isAvailable == -1 then self~next
    if isAvailable then return currentIndex


::method item
    expose currentItem isAvailable
    if isAvailable == -1 then self~next
    if isAvailable then return currentItem


-- If no result returned by the coactivity, then item=.nil and index=.nil
-- This is conform to the description of .Supplier~new : 
-- The supplier iterates for the number of items contained in the values array,
-- returning the Nil object for any nonexistent items in either array.
::method next
    expose coactivity currentIndex currentItem isAvailable
    isAvailable = .false
    coactivity~resumeWithIndex
    if var("result") then do
        currentItem = result[1]
        currentIndex = result[2]
        isAvailable = .true
    end
    else if coactivity~isAlive then do
        currentItem = .nil
        currentIndex = .nil -- By testing index==.nil, you know that the coactivity yielded no item
        isAvailable = .true
    end


-- Two public subclasses : one for generation, one for iteration
::class "CoactivitySupplierForGeneration" public subclass CoactivitySupplier
::class "CoactivitySupplierForIteration" public subclass CoactivitySupplier

