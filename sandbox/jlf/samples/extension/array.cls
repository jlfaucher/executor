/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

--::requires "extension/extensions.cls"
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
    arrayIn = .nil
    doer = .nil
    supplier = .nil
    
    if arg() == 1 then do
        if arg(1)~isA(.String) then arrayIn = arg(1)~subwords -- APL-like
        else if arg(1)~hasMethod("functionDoer") then doer = arg(1)~functionDoer("use arg integerIndex, arrayIndex")~arity(2)
        else if arg(1)~hasMethod("doer") then doer = arg(1)~doer
        else if arg(1)~isA(.array), arg(1)~dimension == 1 then arrayIn = arg(1) -- omitted item in the array passed as argument ==> no item in the array under initialization
        else if arg(1)~hasMethod("supplier") then supplier = arg(1)~supplier -- omitted items are ignored, because not available from the supplier
        else arrayIn = arg(1, "a")
    end
    else arrayIn = arg(1, "a")
    
    if arrayIn <> .nil then do
        arrayInIndex = 1
        arrayInSize = arrayIn~size
    end

    selfIntegerIndex = 1
    selfArrayIndex = self~dimension~times{1} -- Initializes all indexes to 1

    sourceEnd = 0
    selfReuseIntegerIndex = 1
    selfReuseArrayIndex = self~dimension~times{1} -- Initializes all indexes to 1

    do while selfIntegerIndex <= self~size
        if sourceEnd == 0 then do
            -- if initialization with an array (covers the case of several arguments passed to the method)
            if arrayIn <> .nil then do
                if arrayInIndex > arrayInSize then sourceEnd = selfIntegerIndex
                else do
                    if arrayIn~hasIndex(arrayInIndex) then self~put(arrayIn[arrayInIndex], selfArrayIndex)
                    arrayInIndex += 1
                end
            end
            
            -- if initialization with a doer
            else if doer <> .nil then do
                -- next line is not really needed because when a coactivity is ended, there is not returned result
                -- and this case is managed by the second test doer~isEnded below.
                if doer~hasMethod("isEnded"), doer~isEnded then sourceEnd = selfIntegerIndex -- detection of end of coactivity
                else do
                    if doer~arity >= 2 then doer~do(selfIntegerIndex, selfArrayIndex~copy)
                    else if doer~arity == 1 then doer~do(selfIntegerIndex)
                    else doer~do
                    if var("result") then self~put(result, selfArrayIndex)
                    -- next line is needed to offer the same behaviour for
                    -- .array~new(2,3)~of(1~upto(5))
                    -- .array~new(2,3)~of(1~generate.upto(5))
                    else if doer~hasMethod("isEnded"), doer~isEnded then sourceEnd = selfIntegerIndex -- detection of end of coactivity
                end
            end
            
            -- if initialization with a supplier
            else if supplier <> .nil then do
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
    use strict arg maxItems=(-1), ellipsis="...", separator=",", val=(self), stack=(.queue~new)
    if val~isA(.array) /*, val~dimension == 1*/ then do
        -- Remember : this code has been duplicated in pipe.rex, routine dataflow_representation.
        level = stack~index(val)
        if level <> .nil then return "*"level-1
        stack~push(val)
        -- each item of the array is inserted.
        items = 0 -- Not global. Each item being an array will have maxItems items inserted.
                  -- Maybe a global count could be useful... Will see on usage.
        valstr = "["
        sep = ""
        do v over val -- not well adapted to multi-dimension arrays : converted into a non-sparse single dimension array
            if maxItems >= 0, items >= maxItems then do
                valstr ||= sep || ellipsis
                leave
            end
            valstr ||= sep || self~ppRepresentation(maxItems, ellipsis, separator, v, stack)
            sep = separator
            items += 1
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
            valstr = "("valstr")" -- to make a distinction between a real string and other objects
        end
        return valstr
    end


/******************************************************************************/
-- ArrayOperators

::options OPERATOR_OVERRIDING_BY_ROUTINE

::routine "+" public
--say "array '+'" arg(1) arg(2)
if arg() == 1, arg(1)~isA(.array) then return arg(1)~map("+")
if arg() == 2 then do
    if arg(1)~isA(.array), arg(2)~isA(.array) then do
        use arg array1, array2
        return array1~map{::closure expose array2 ; options "OPERATOR_OVERRIDING_BY_ROUTINE" ; item + array2[index]}
    end
    if arg(1)~isA(.array) then do
        use arg array, scalar
        return array~map{::closure expose scalar ; options "OPERATOR_OVERRIDING_BY_ROUTINE" ; item + scalar}
    end
    if arg(2)~isA(.array) then do
        use arg scalar, array
        return array~map{::closure expose scalar ; options "OPERATOR_OVERRIDING_BY_ROUTINE" ; scalar + item}
    end
end

::routine "-" public
if arg() == 1, arg(1)~isA(.array) then return arg(1)~map("-")
if arg() == 2 then do
    if arg(1)~isA(.array), arg(2)~isA(.array) then do
        use arg array1, array2
        return array1~map{::closure expose array2 ; item - array2[index]}
    end
    if arg(1)~isA(.array) then do
        use arg array, scalar
        return array~map{::closure expose scalar ; item - scalar}
    end
    if arg(2)~isA(.array) then do
        use arg scalar, array
        return array~map{::closure expose scalar ; scalar - item}
    end
end

