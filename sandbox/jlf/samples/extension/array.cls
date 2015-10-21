/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

--::options trace i

/******************************************************************************/
::class "ArrayInitializer" mixinclass Object public
/*
Initializer (instance method) which takes into account the dimensions of the array.

If there is only one argument, and this argument is a string, then each word of the string is an item (APL-like).
    .array~new(2,3)~of(1 2 3 4 5 6)
    1 2 3
    4 5 6

If there is only one argument, and this argument has the method ~supplier then each item returned by the argument's supplier is an item.
    .array~new(2,3)~of(1~upto(6))
    1 2 3
    4 5 6

If there is only one argument, and this argument is a doer, then the doer is called for each cell to initialize.
Implicit arguments :
    arg(1) : integerIndex : position of the current cell, from 1 to size.
    arg(2) : arrayIndex : position of the current cell, in each dimension. Always an array, even if the number of dimensions = 1
The value returned by the doer is the item for the current cell.
If no value returned then the cell remains unassigned.
    .array~new(2,3)~of{10*integerIndex}
    10 20 30
    40 50 60

Otherwise, when more than one argument, each argument is an item as-is.
    .array~new(2,3)~of(1,2,3,4,5,6)
    1 2 3
    4 5 6

If some arguments are omitted, then the corresponding item in the initialized array remains non-assigned.
    .array~new(2,3)~of(1,,3,,5,6)
    1 . 3
    . 5 6

For me, there is a problem (bug ?) when the last arguments are explicitely omitted : they are not counted by the interpreter !
    .array~new(2,3)~of(1,,3,,5,)
    1 . 3
    . 5 1
I was expecting this result, because I passed explicitely 6 arguments, 3 of them being omitted :
    1 . 3
    . 5 .

The items are a list of values that must be assigned to the cells of the array.
Rules inspired by APL :
If there are too many items, the extra items are ignored.
If there are fewer items than implied by the dimensions, the list of items is reused as
many times as necessary to fill the array.
    .array~new(2,3)~of(1,2)
    1 2 1
    2 1 2
*/

::method of
    use strict arg arg1, ... -- at least one argument

    if self~dimension == 0 then raise syntax 93.900 array("Unknown number of dimensions")

    -- Only one of the following variable will be used
    oneValue = .false
    arrayIn = .nil
    doer = .nil
    supplier = .nil

    if arg() == 1 then do
        if arg(1)~isA(.String) then do
            arrayIn = arg(1)~subwords -- APL-like
            if arrayIn~items == 1 then do
                -- Optimization : use the value as-is instead of iterating over an array of 1 item
                arrayIn = .nil
                oneValue = .true
                value = arg(1)
            end
        end
        else if arg(1)~hasMethod("functionDoer") then doer = arg(1)~functionDoer("use arg integerIndex, arrayIndex, array")~arity(3)
        else if arg(1)~hasMethod("doer") then doer = arg(1)~doer
        else if arg(1)~isA(.array), arg(1)~dimension == 1 then arrayIn = arg(1) -- omitted item in the array passed as argument ==> no item in the array under initialization
        else if arg(1)~hasMethod("supplier") then supplier = arg(1)~supplier -- omitted items are ignored, because not available from the supplier
        else arrayIn = arg(1, "a")
    end
    else arrayIn = arg(1, "a")

    selfIntegerIndex = 1
    selfArrayIndex = self~dimension~times{1} -- Initializes all indexes to 1

    -- Optimization
    if oneValue == .true then do
        do while selfIntegerIndex <= self~size
            self~put(value, selfArrayIndex)
            selfIntegerIndex += 1
            self~incrementIndex(selfArrayIndex)
        end
        return self
    end

    if .nil <> arrayIn then do
        arrayInIndex = 1
        arrayInSize = arrayIn~size
    end

    sourceEnd = 0
    selfReuseIntegerIndex = 1
    selfReuseArrayIndex = self~dimension~times{1} -- Initializes all indexes to 1

    do while selfIntegerIndex <= self~size
        if sourceEnd == 0 then do
            -- if initialization with an array (covers the case of several arguments passed to the method)
            if .nil <> arrayIn then do
                if arrayInIndex > arrayInSize then sourceEnd = selfIntegerIndex
                else do
                    if arrayIn~hasIndex(arrayInIndex) then self~put(arrayIn[arrayInIndex], selfArrayIndex)
                    arrayInIndex += 1
                end
            end

            -- if initialization with a doer
            else if .nil <> doer then do
                if doer~arity == 3 then doer~do(selfIntegerIndex, selfArrayIndex~copy, self)
                else if doer~arity == 2 then doer~do(selfIntegerIndex, selfArrayIndex~copy)
                else if doer~arity == 1 then doer~do(selfIntegerIndex)
                else doer~do
                if var("result") then self~put(result, selfArrayIndex)
                -- next line is needed to offer the same behaviour for
                -- .array~new(2,3)~of(1~upto(5))
                -- .array~new(2,3)~of(1~generate.upto(5))
                else if doer~hasMethod("isEnded"), doer~isEnded then sourceEnd = selfIntegerIndex -- detection of end of coactivity
            end

            -- if initialization with a supplier
            else if .nil <> supplier then do
                if \supplier~available then sourceEnd = selfIntegerIndex
                else do
                    self~put(supplier~item, selfArrayIndex)
                    supplier~next
                end
            end
        end
        if sourceEnd <> 0 then do -- APL-like : If there are fewer items than implied by the dimensions, the list of items is reused as  many times as necessary to fill the array.
            if sourceEnd == 1 then leave -- can stop now because nothing to reuse (happens when you pass an empty provider)
            if selfReuseIntegerIndex == sourceEnd then do
                selfReuseIntegerIndex = 1 -- rewind
                selfReuseArrayIndex~mapR{1} -- rewind all indexes to 1
            end
            if self~hasIndex(selfReuseArrayIndex) then self~put(self[selfReuseArrayIndex], selfArrayIndex)
            selfReuseIntegerIndex += 1
            self~incrementIndex(selfReuseArrayIndex)
        end
        selfIntegerIndex += 1
        self~incrementIndex(selfArrayIndex)
    end
    return self


-- The shape of an array is an array which gives the size of each dimension (APL).
::method shape
    -- return self~dimension~times{::closure expose self;self~dimension(item)}
    shape = .array~new(self~dimension)
    do i=1 to self~dimension
        shape[i] = self~dimension(i)
    end
    return shape


::method incrementIndex
    use strict arg arrayIndex -- updated in place
    do i=self~dimension to 1 by -1
        arrayIndex[i] += 1
        if arrayIndex[i] <= self~dimension(i) then leave
        arrayIndex[i] = 1
    end
    return arrayIndex -- for convenience


/******************************************************************************/
::class "ArrayPrettyPrinter" mixinclass Object public
-- Ex :
-- .array~of(1,"two", .array~of(1, "two", 3), .array~of(1, "two"))~ppRepresentation -- [[1,'two',[1,'two',3],[1,'two']]]

::method ppRepresentation
    /*
    Return a condensed string representation of the array.
    Recursive arrays are supported. A reference *N is inserted in the representation,
    where N is the number of levels to follow from the current position.
    Ex :
    a = .array~of("string1", "string2")
    b = .array~of("string2")
    b~append(a)
    a~append(b)
    a~append(a)

           +<------------------------------------+<--------+
           |                                     ^         ^
           V                                     |         |
        +---------+---------+-----+--+--+        |         |
        | string1 | string2 |  .  |  .  |        |         |
        +---------+---------+--|--+--|--+        |         |
                               |     |           |         |
                               |     +---------->+         |    Reference current level : *0
                               V                           |
                           +---------+-----+               |
                           | string2 |  .  |               |
                           +---------+--|--+               |
                                        |                  |
                                        +----------------->+    Reference one level above : *1

    say a~ppRepresentation
        ['string1','string2',['string2',*1],*0]

    a~pipe(.console dataflow)
        source:1,'string1'
        source:2,'string2'
        source:3,[v1='string2',['string1',v1,*1,*0]]
        source:4,['string1',v1='string2',[v1,*1],*0]

    a~pipe(.inject iterateBefore {item} recursive.0.memorize | .console dataflow)
        source:1,v1='string1' | inject:1,v1
        source:2,v1='string2' | inject:1,v1
        source:3,[v1='string2',['string1',v1,*1,*0]] | inject:1,v1
        source:3,[v1='string2',[v2='string1',v1,*1,*0]] | inject:1,[v2,v1,[v1,*1],*0]
        source:4,[v1='string1',v2='string2',[v2,*1],*0] | inject:1,v1
        source:4,['string1',v1='string2',[v1,*1],*0] | inject:1,v1
        source:4,[v1='string1',v2='string2',[v2,*1],*0] | inject:1,[v2,[v1,v2,*1,*0]]
        source:4,[v1='string1',v2='string2',[v2,*1],*0] | inject:1,[v1,v2,[v2,*1],*0]
*/
    use strict arg maxItems=(-1), sparse="..", ellipsis="...", separator=",", val=(self), stack=(.queue~new)
    if val~isA(.array), val~dimension == 1 then do
        -- Remember : this code has been duplicated in pipe.rex, routine dataflow_representation.
        level = stack~index(val)
        if .nil <> level then return "*"level-1
        stack~push(val)
        -- each item of the array is inserted.
        items = 0 -- Not global. Each item being an array will have maxItems items inserted.
                  -- Maybe a global count could be useful... Will see on usage.
        valstr = "["
        sep = ""
        s = val~supplier
        i = 1 -- current index, will let detect sparse sections
        do while s~available
            item = s~item
            index = s~index
            if maxItems >= 0, items >= maxItems then do
                valstr ||= sep || ellipsis
                leave
            end
            if i <> index then do
                valstr ||= sep || sparse
                sep = separator
            end
            valstr ||= sep || self~ppRepresentation(maxItems, sparse, ellipsis, separator, item, stack)
            sep = separator
            items += 1
            i = index + 1 -- next index
            s~next -- skip sparse section, if any
        end
        if maxItems >= 0, items < maxItems then do -- if not truncated
            if i <= self~size then valstr ||= sep || sparse
        end
        valstr ||= "]"
        stack~pull
        return valstr
    end
    else do
        valstr = val~string
        if val~isA(.String) then do
            isnum = valstr~dataType("N")
            if \isnum then valstr = "'"valstr"'" -- strings are surrounded by quotes, except string numbers
        end
        else do
            isnum = .false
            -- To make a distinction between a real string and other objects, surround by (...)
            -- For the arrays, indicate their shape : (an Array 2x3)
            if val~isA(.array) then valstr = "("valstr val~shape~reduce{accu"x"item}")"
            else valstr = "("valstr")"
        end
        return valstr
    end


/******************************************************************************/
::class "ArrayOperators" mixinclass Object public

::method leftElementWise
    use strict arg message, rightArgIsProvided, rightArg, recursion=(.identityTable~new)
    counterpart = recursion[self]
    if counterpart <> .nil then return counterpart -- stop infinite recursion
    r = .array~new
    recursion[self] = r -- will be used to build the resulting infinite array
    if \ rightArgIsProvided then do -- unary operator
        supplier = self~supplier
        do while supplier~available
            index = supplier~index
            item = supplier~item
            if item~isA(.array) then
                r[index] = item~leftElementWise(message, .false, .nil, recursion)
            else
                r[index] = item~send(message)
            supplier~next
        end
    end
    else if rightArg~isA(.array) then do -- binary operator with array on left & right
        if \SameDimensions(self, rightArg) then raise syntax 93.900 array("Dimensions are not equal")
        supplier = self~supplier
        do while supplier~available
            index = supplier~index
            item = supplier~item
            if item~isA(.array) then
                r[index] = item~leftElementWise(message, .true, rightArg[index], recursion)
            else
                r[index] = item~send(message, rightArg[index])
            supplier~next
        end
    end
    else do -- binary operator with array on left only
        supplier = self~supplier
        do while supplier~available
            index = supplier~index
            item = supplier~item
            if item~isA(.array) then
                r[index] = item~leftElementWise(message, .true, rightArg, recursion)
            else
                r[index] = item~send(message, rightArg)
            supplier~next
        end
    end
    recursion~remove(self)
    return r

::method "rightElementWise"
    use strict arg message, leftArg, recursion=(.identityTable~new)
    counterpart = recursion[self]
    if counterpart <> .nil then return counterpart -- stop infinite recursion
    r = .array~new
    recursion[self] = r -- will be used to build the resulting infinite array
    if leftArg~isA(.array) then do -- binary operator with array on left & right
        if \SameDimensions(self, leftArg) then raise syntax 93.900 array("Dimensions are not equal")
        supplier = self~supplier
        do while supplier~available
            index = supplier~index
            item = supplier~item
            if item~isA(.array) then
                r[index] = item~rightElementWise(message, leftArg[index], recursion)
            else
                r[index] = leftArg[index]~send(message, item)
            supplier~next
        end
    end
    else do -- binary operator with array on right only
        supplier = self~supplier
        do while supplier~available
            index = supplier~index
            item = supplier~item
            if item~isA(.array) then
                r[index] = item~rightElementWise(message, leftArg, recursion)
            else
                r[index] = leftArg~send(message, item)
            supplier~next
        end
    end
    recursion~remove(self)
    return r

::method "+"
    return self~leftElementWise("+", arg(1, "e"), arg(1))

::method "+op:right"
    return self~rightElementWise("+", arg(1))

::method "-"
    return self~leftElementWise("-", arg(1, "e"), arg(1))

::method "-op:right"
    return self~rightElementWise("-", arg(1))

::method "*"
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item * right[index]}
    end
    return self~map{::closure expose right ; item * right}

::method "*op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] * item}
    end
    return self~map{::closure expose left ; left * item}

::method "/"
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item / right[index]}
    end
    return self~map{::closure expose right ; item / right}

::method "/op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] / item}
    end
    return self~map{::closure expose left ; left / item}

::method "%"
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item % right[index]}
    end
    return self~map{::closure expose right ; item % right}

::method "%op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] % item}
    end
    return self~map{::closure expose left ; left % item}

::method "//"
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item // right[index]}
    end
    return self~map{::closure expose right ; item // right}

::method "//op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] // item}
    end
    return self~map{::closure expose left ; left // item}

::method "**"
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item ** right[index]}
    end
    return self~map{::closure expose right ; item ** right}

::method "**op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] ** item}
    end
    return self~map{::closure expose left ; left ** item}

::method " "
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item right[index]}
    end
    return self~map{::closure expose right ; item right}

::method " op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose self ; self[index] item}
    end
    return self~map{::closure expose left ; left item}

::method "||"
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item || right[index]}
    end
    return self~map{::closure expose right ; item || right}

::method "||op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] || item}
    end
    return self~map{::closure expose left ; left || item}

::method "" -- abuttal
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item || right[index]}
    end
    return self~map{::closure expose right ; item || right}

::method "op:right" -- abuttal
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] || item}
    end
    return self~map{::closure expose left ; left || item}

::method mapEqual
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; (item) = right[index]}
    end
    return self~map{::closure expose right ; (item) = right}

/* Not activated
::method "="
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; (item) = right[index]}
    end
    return self~map{::closure expose right ; (item) = right}
*/

/* Not activated
::method "=op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; (left[index]) = item}
    end
    return self~map{::closure expose left ; (left) = item}
*/

::method mapNotEqual
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item \= right[index]}
    end
    return self~map{::closure expose right ; item \= right}

/* Not activated
::method "\="
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item \= right[index]}
    end
    return self~map{::closure expose right ; item \= right}
*/

/* Not activated
::method "\=op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] \= item}
    end
    return self~map{::closure expose left ; left \= item}
*/

::method mapNotEqualTo
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item <> right[index]}
    end
    return self~map{::closure expose right ; item <> right}

/* Not activated
::method "<>"
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item <> right[index]}
    end
    return self~map{::closure expose right ; item <> right}
*/

/* Not activated
::method "<>op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] <> item}
    end
    return self~map{::closure expose left ; left <> item}
*/

::method mapStrictEqual
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item == right[index]}
    end
    return self~map{::closure expose right ; item == right}

/* Not activated
::method "=="
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item == right[index]}
    end
    return self~map{::closure expose right ; item == right}
*/

/* Not activated
::method "==op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] == item}
    end
    return self~map{::closure expose left ; left == item}
*/

::method mapStrictNotEqual
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item \== right[index]}
    end
    return self~map{::closure expose right ; item \== right}

/* Not activated
::method "\=="
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item \== right[index]}
    end
    return self~map{::closure expose right ; item \== right}
*/

/* Not activated
::method "\==op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] \== item}
    end
    return self~map{::closure expose left ; left \== item}
*/

/* Not activated
::method "><"
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item >< right[index]}
    end
    return self~map{::closure expose right ; item >< right}
*/

/* Not activated
::method "><op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] >< item}
    end
    return self~map{::closure expose left ; left >< item}
*/

::method "\"
    use strict arg -- none
    return self~map("\")

::method ">"
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item > right[index]}
    end
    return self~map{::closure expose right ; item > right}

::method ">op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] > item}
    end
    return self~map{::closure expose left ; left > item}

::method "<"
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item < right[index]}
    end
    return self~map{::closure expose right ; item < right}

::method "<op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] < item}
    end
    return self~map{::closure expose left ; left < item}

::method ">="
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item >= right[index]}
    end
    return self~map{::closure expose right ; item >= right}

::method ">=op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] >= item}
    end
    return self~map{::closure expose left ; left >= item}

::method "\<"
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item \< right[index]}
    end
    return self~map{::closure expose right ; item \< right}

::method "\<op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] \< item}
    end
    return self~map{::closure expose left ; left \< item}

::method "<="
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item <= right[index]}
    end
    return self~map{::closure expose right ; item <= right}

::method "<=op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] <= item}
    end
    return self~map{::closure expose left ; left <= item}

::method "\>"
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item \> right[index]}
    end
    return self~map{::closure expose right ; item \> right}

::method "\>op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] \> item}
    end
    return self~map{::closure expose left ; left \> item}

::method ">>"
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item >> right[index]}
    end
    return self~map{::closure expose right ; item >> right}

::method ">>op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] >> item}
    end
    return self~map{::closure expose left ; left >> item}

::method "<<"
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item << right[index]}
    end
    return self~map{::closure expose right ; item << right}

::method "<<op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] << item}
    end
    return self~map{::closure expose left ; left << item}

::method ">>="
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item >>= right[index]}
    end
    return self~map{::closure expose right ; item >>= right}

::method ">>=op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] >>= item}
    end
    return self~map{::closure expose left ; left >>= item}

::method "\<<"
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item \<< right[index]}
    end
    return self~map{::closure expose right ; item \<< right}

::method "\<<op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] \<< item}
    end
    return self~map{::closure expose left ; left \<< item}

::method "<<="
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item <<= right[index]}
    end
    return self~map{::closure expose right ; item <<= right}

::method "<<=op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] <<= item}
    end
    return self~map{::closure expose left ; left <<= item}

::method "\>>"
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item \>> right[index]}
    end
    return self~map{::closure expose right ; item \>> right}

::method "\>>op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] \>> item}
    end
    return self~map{::closure expose left ; left \>> item}

::method "&"
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item & right[index]}
    end
    return self~map{::closure expose right ; item & right}

::method "&op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] & item}
    end
    return self~map{::closure expose left ; left & item}

::method "|"
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item | right[index]}
    end
    return self~map{::closure expose right ; item | right}

::method "|op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] | item}
    end
    return self~map{::closure expose left ; left | item}

::method "&&"
    use strict arg right
    if right~isA(.array) then do
        if \SameDimensions(self, right) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose right ; item && right[index]}
    end
    return self~map{::closure expose right ; item && right}

::method "&&op:right"
    use strict arg left
    if left~isA(.array) then do
        if \SameDimensions(self, left) then raise syntax 93.900 array("Dimensions are not equal")
        return self~map{::closure expose left ; left[index] && item}
    end
    return self~map{::closure expose left ; left && item}

::routine SameDimensions
    use strict arg a1, a2
    if a1~dimension <> a2~dimension then return .false
    do i=1 to a1~dimension
        if a1~dimension(i) <> a2~dimension(i) then return .false
    end
    return .true
