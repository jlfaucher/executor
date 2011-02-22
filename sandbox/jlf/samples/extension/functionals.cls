/*
This script works with a standard ooRexx, no need of ::extension here.
BUT
only the version with ::extension will let you hook those mixins on the predefined classes.
*/

::requires "doers.cls"
::requires "factory.cls"

-----------------------------------------------------------------------------
-- Mixins
-- Reduce

::class StringReduce mixinclass Object public

::method reduce
    use strict arg action, context=.nil
    return self~makearray("")~reduce(action, context)


::class CollectionReduce mixinclass Object public

::method reduce
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
-- Mixins
-- Map

::class StringMap mixinclass Object public

::method map
    forward message "mapChar"

::method mapchar
    use strict arg action, inplace=.false, context=.nil
    if inplace == .true then raise syntax 93.900 array ("in place not applicable to string")
    -- For better support of extended classes, must take care of special factories (not needed with ::extension)
    return Object.factory(self, .MutableBuffer)~new(self)~mapchar(action, .true, context)~string

::method mapword
    use strict arg action, inplace=.false, context=.nil
    if inplace == .true then raise syntax 93.900 array ("in place not applicable to string")
    -- For better support of extended classes, must take care of special factories (not needed with ::extension)
    return Object.factory(self, .MutableBuffer)~new(self)~mapword(action, .true, context)~string


::class MutableBufferMap mixinclass Object public

::method map
    forward message "mapChar"

::method mapchar
    use strict arg action, inplace=.true, context=.nil
    doer = action~doer(context) -- parse only once, before iteration
    r = self
    if \inplace then r = self~copy
    string = r~string
    r~delete(1)
    do char over string~makearray("")
        r~append(doer~do(char))
    end
    return r

::method mapword
    use strict arg action, inplace=.true, context=.nil
    doer = action~doer(context) -- parse only once, before iteration
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

::method map
    use strict arg action, inplace=.false, context=.nil
    doer = action~doer(context) -- parse only once, before iteration
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

::method times
    use strict arg action, context=.nil
    doer = action~doer(context) -- parse only once, before iteration
    do i = 1 to self
        doer~do(i)
    end
    return self

::method upto
    use strict arg upperLimit, action, context=.nil
    doer = action~doer(context) -- parse only once, before iteration
    do i = self to upperLimit
        doer~do(i)
    end
    return self

