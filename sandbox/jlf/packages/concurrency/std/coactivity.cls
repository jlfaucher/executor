/*
Coactivity is an emulation of coroutines in ooRexx.

This script works with a standard ooRexx, but there is a dependency on doers.
It's up to the package which requires the current script to requires also :
either extension.cls (if supporting ::extension)
or extension-std.cls (if standard ooRexx)

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
::requires "concurrency/activity.cls"


--------------------------------------------------------------------------------
-- .yield[value] is more compact than .Coactivity~yield(value)
::class "yield" public
::method "[]" class unguarded
    forward message ("yield") to (.Coactivity)


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
::attribute makeArrayLimit class -- Coactivities can generate an infinite number of values, so must put a limit...


::method init class
    expose globalCache
    -- Using a Directory instead of an IdentityTable because of the experimentation with WeakReferences.
    globalCache = .Directory~new
    self~makeArrayLimit = 10000 -- not a constant, not a private attribute, I think it's useful to let the end user change this value


::method register class
    expose globalCache
    use strict arg coactivityObj
    -- Remember : A weak reference is useless here because only started-not-ended-killed coactivities
    -- are referenced by this cache, and a started-not-ended-killed coactivity can't be GC'ed because
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


::method init unguarded
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
    -- I don't define the unknown method because (for the moment) .Coactivity is a
    -- mixin class. I don't think it's a good idea to inherit an unknown method from a
    -- mixin class, knowing that it's not unusual to inherit from several mixin classes.


::method executable
    expose coactivityObj
    forward to (coactivityObj)


::method start unguarded
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


::method yield class unguarded
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
    coactivityObj = .Activity~local~coactivityObj
    if coactivityObj == .nil then raise syntax 93.900 array ("yield can be used only from a coactivity")
    forward to (coactivityObj)


::method yield private
    -- Can be called only from a coactivity.
    -- Returns an array which contains the arguments passed to 'resume' by the client of the coactivity.
    expose coactivityObj
    forward to (coactivityObj)


::method resume unguarded -- must be unguarded because can start the coactivity (so must be lock free to let the coactivityObj re-enter when calling yield)
    -- You can pass arguments to this method.
    -- They will be passed to the coactivity, either as traditional 'use arg' if first call, or as an array returned by 'yield'.
    expose coactivityObj
    forward to (coactivityObj)


::method end
    expose coactivityObj
    forward to (coactivityObj)


::method kill
    expose coactivityObj
    forward to (coactivityObj)


::method isStarted
    expose coactivityObj
    forward to (coactivityObj)


::method isAlive
    expose coactivityObj
    forward to (coactivityObj)


::method isEnded
    expose coactivityObj
    forward to (coactivityObj)


::method isKilled
    expose coactivityObj
    forward to (coactivityObj)


::method statusText
    expose coactivityObj
    forward to (coactivityObj)


::method supplier unguarded
    expose coactivityObj
    forward to (coactivityObj)


::method makeArray unguarded
    -- This is really NOT adapted to coactivities which can generate an infinite set of values  !
    -- But this is the only way to write : do over myCoactivity ...
    -- A better approach would be to modify the interpreter to support : do over anySupplier ...
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
-- ::attribute yieldValue private


::method init unguarded
    expose proxy doer object status
    use strict arg action, start, object, proxy
    doer = action~doer
    status = .CoactivityObj~notStarted
    if start then self~start


::method uninit
    -- If no longer referenced, then can stop the coactivity
    -- (but will never happen, see the comment in ~register)
    self~end


::method executable
    expose doer
    return doer


::method start
    expose arguments doer object status
    use strict arg -- no arg
    if status <> .CoactivityObj~notStarted then return
    status = .CoactivityObj~suspended
    reply self
    .Activity~local~empty
    .Activity~local~coactivityObj = self
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
    .Activity~local~empty
    if self~isKilled & condition("o") <> .nil then raise propagate


::method yield --private
    expose arguments status yieldValue
    drop yieldValue
    if status == .CoactivityObj~killed then raise syntax 93.900 array ("Coactivity is killed") -- this is to unwind any nested invocation and return to 'start'
    if status == .CoactivityObj~ended then raise syntax 93.900 array ("Coactivity is ended") -- this is to unwind any nested invocation and return to 'start'
    if arg() <> 0 then use strict arg yieldValue -- yieldValue will be returned to the Coactivity's client by 'resume'
    status = .CoactivityObj~suspended
    guard off
    guard on when status <> .CoactivityObj~suspended
    if status == .CoactivityObj~killed then raise syntax 93.900 array ("Coactivity is killed") -- this is to unwind any nested invocation and return to 'start'
    if status == .CoactivityObj~ended then raise syntax 93.900 array ("Coactivity is ended") -- this is to unwind any nested invocation and return to 'start'
    if arguments~items <> 0 then return arguments -- returns the arguments that the coactivity's client passed to 'resume'


::method yieldLast private
    /*
    Internal method called when the coactivity action has returned.
    */
    expose yieldValue
    drop yieldValue
    if arg() <> 0 then use strict arg yieldValue -- yieldValue will be returned to the coactivity's client by 'resume'


::method resume
    expose arguments status yieldValue
    if status == .CoactivityObj~notStarted then self~start
    if status == .CoactivityObj~killed then raise syntax 93.900 array ("Coactivity is killed")
    if status == .CoactivityObj~ended then return -- raise syntax 93.900 array ("Coactivity is ended")
    arguments = arg(1, "a")
    status = .CoactivityObj~running
    guard off
    guard on when status <> .CoactivityObj~running
    if status == .CoactivityObj~killed then raise syntax 93.900 array ("Coactivity is killed")
    if var("yieldValue") then return yieldValue


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


::method isStarted
    expose status
    return status <> .CoactivityObj~notStarted


::method isAlive
    expose status
    return status == .CoactivityObj~suspended | status == .CoactivityObj~running


::method isEnded
    expose status
    return status == .CoactivityObj~ended


::method isKilled
    expose status
    return status == .CoactivityObj~killed


::method statusText
    expose status
    select
        when status == .CoactivityObj~notStarted then return "not started"
        when status == .CoactivityObj~suspended then return "suspended"
        when status == .CoactivityObj~running then return "running"
        when status == .CoactivityObj~ended then return "ended"
        when status == .CoactivityObj~killed then return "killed"
        otherwise return "unknown"
    end


/*
BAD IDEA ! The method defaultName is called by the interpreter when tracing and you enter in
a recursive loop because defaultName itself is traced. Should use "objectName=" instead, but
will have to call it each time the status is changed. Maybe later...

::method defaultName
    defaultName = self~statusText self~class~id
    if defaultName~caselessMatchChar(1, "aeiou") then article = "An" ; else article = "A"
    return article defaultName
*/


::method supplier unguarded
    expose proxy
    return .LazyCoactivitySupplier~new(proxy~value) -- must pass the wrapping coactivity, not self, otherwise the coactivity may be GC'ed even if the supplier is running and not GC'ed


::method makeArray unguarded
    use strict arg limit=(.Coactivity~makeArrayLimit)
    array = .Array~new
    do forever
        if array~dimension(1) >= limit then do
            -- Better to not end the coactivity : makeArray is like clojure's take or like the pipestage .take
            -- self~end
            leave
        end
        self~resume
        if \var("result") then leave
        array~append(result)
    end
    return array


--------------------------------------------------------------------------------
/*
Lazy Coactivity supplier :
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
::class "LazyCoactivitySupplier" subclass Supplier

--::attribute coactivity private
--::attribute currentIndex private
--::attribute currentItem private
--::attribute isAvailable private


::method init
    expose coactivity currentIndex
    use strict arg coactivity
    empty = .array~new(0) -- Lazy supplier
    self~init:super(empty, empty)
    currentIndex = 0
    self~next


::method available
    expose isAvailable
    return isAvailable


::method index
    expose currentIndex isAvailable
    if isAvailable then return currentIndex


::method item
    expose currentItem isAvailable
    if isAvailable then return currentItem


::method next
    expose coactivity currentItem currentIndex isAvailable
    coactivity~resume
    drop currentItem
    if var("result") then do
        currentItem = result
        currentIndex += 1
        isAvailable = .true
    end
    else isAvailable = .false

