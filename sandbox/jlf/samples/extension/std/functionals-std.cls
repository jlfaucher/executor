/*
This script works with a standard ooRexx, but has drawbacks compared to functionals.cls.
*/

--::options trace i
::requires "extension/std/doers-std.cls"

-----------------------------------------------------------------------------
-- Mixins/Wrappers
-- Reduce

::class StringReduce mixinclass Object public

::method init
    -- Enhancement by delegation (wrapper) when ~enhanced can't be used
    expose string
    use arg string=.nil

::method reduce
    expose string
    use strict arg action, context=.nil
    if var("string"), string <> .nil then self = string 
    return .CollectionReduce~new(self~makearray(""))~reduce(action, context)


::class CollectionReduce mixinclass Object public

::method init
    -- Enhancement by delegation (wrapper) when ~enhanced can't be used
    expose collection
    use arg collection=.nil

::method reduce
    expose collection
    if var("collection"), collection <> .nil then self = collection 
    use strict arg action, context=.nil
    doer = action~doer(context) -- parse only once, before iteration
    supplier = self~supplier
    if \ supplier~available then return .nil
    r = supplier~item
    supplier~next
    do while supplier~available
        r = doer~do(r, supplier~item)
        supplier~next
    end
    return r


-----------------------------------------------------------------------------
-- Mixins/Wrappers
-- Map

::class StringMap mixinclass Object public

::method init
    -- Enhancement by delegation (wrapper) when ~enhanced can't be used
    expose string
    use arg string=.nil

::method map
    forward message "mapChar"

::method mapchar
    expose string
    use strict arg action, inplace=.false, context=.nil
    if inplace == .true then raise syntax 93.900 array ("in place not applicable to string")
    if var("string"), string <> .nil then self = string 
    return .MutableBuffer~enhanced(.MutableBufferMap~methods(.nil), self)~mapchar(action, .true, context)~string

::method mapword
    expose string
    use strict arg action, inplace=.false, context=.nil
    if inplace == .true then raise syntax 93.900 array ("in place not applicable to string")
    if var("string"), string <> .nil then self = string 
    return .MutableBuffer~enhanced(.MutableBufferMap~methods(.nil), self)~mapword(action, .true, context)~string


::class MutableBufferMap mixinclass Object public

::method init
    -- Enhancement by delegation (wrapper) when ~enhanced can't be used
    expose mutableBuffer
    use arg mutableBuffer=.nil

::method map
    forward message "mapChar"

::method mapchar
    expose mutableBuffer 
    use strict arg action, inplace=.true, context=.nil
    doer = action~doer(context) -- parse only once, before iteration
    if var("mutableBuffer"), mutableBuffer <> .nil then self = mutableBuffer 
    r = self
    if \inplace then r = self~copy
    string = r~string
    r~delete(1)
    do char over string~makearray("")
        r~append(doer~do(char))
    end
    return r

::method mapword
    expose mutableBuffer 
    use strict arg action, inplace=.true, context=.nil
    doer = action~doer(context) -- parse only once, before iteration
    if var("mutableBuffer"), mutableBuffer <> .nil then self = mutableBuffer 
    r = self
    if \inplace then r = self~copy
    string = r~string
    r~delete(1)
    first = .true
    do word over string~space~makearray(" ")
        if \first then self~append(" ")
        r~append(doer~do(word))
        first = .false
    end
    return r


-- Will work with Array, List, Queue, CircularQueue (any collection which supports "first" and "next")
-- These 4 classes are subclasses of  OrderedCollection.
-- I don't use a supplier because it works on a snapshot of the collection and is not done for updating the collection
-- (when inplace == .true the collection is updated in place)
::class OrderedCollectionMap mixinclass Object public

::method init
    -- Enhancement by delegation (wrapper) when ~enhanced can't be used
    expose orderedCollection
    use arg orderedCollection=.nil

::method map
    expose orderedCollection
    use strict arg action, inplace=.false, context=.nil
    doer = action~doer(context) -- parse only once, before iteration
    if var("orderedCollection"), orderedCollection <> .nil then self = orderedCollection 
    r = self
    if \inplace then r = self~copy
    current = self~first
    do while current <> .nil
        r[current] = doer~do(self[current])
        current = self~next(current)
    end
    return r


-----------------------------------------------------------------------------
-- Mixins
-- Repeater

::class StringRepeater mixinclass Object public

::method init
    -- Enhancement by delegation (wrapper) when ~enhanced can't be used
    expose string
    use arg string=.nil

::method times
    expose string
    use strict arg action, context=.nil
    doer = action~doer(context) -- parse only once, before iteration
    if var("string"), string <> .nil then self = string 
    do i = 1 to self
        doer~do(i)
    end
    return self

::method upto
    expose string
    use strict arg upperLimit, action, context=.nil
    doer = action~doer(context) -- parse only once, before iteration
    if var("string"), string <> .nil then self = string 
    do i = self to upperLimit
        doer~do(i)
    end
    return self

