/*
NOT USED.

This is an archive of the changes I made to support reshape with Zilde.
Not kept because that makes the code more complex for just getting the
first item of an array as scalar...

Use myArray~take[1]
That work for an array of any shape...

*/

::method reshape
    -- R←X⍴Y (Rho)
    -- args : new dimension(s)
    if arg() == 1, arg(1)~isa(.array) then do
        -- to support an array as argument
        use arg arg1
        if arg1~dimension == 1, arg1~dimension(1) == 0 then do
            -- special case APL Zilde (empty numeric vector)
            -- Remember: .array~new(v) returns an array with dimension=0, hence this special case which will be tested in ~of.
            return arg1~of(self)
        end
        return .array~new(arg1)~of(self)
    end
    return .array~new(arg(1, "a"))~of(self)


::method of
    /*
    Initializer (instance method) which takes into account the dimensions of the array.

    If there is only one argument, and this argument has the method ~supplier then each item returned by the argument's supplier is an item.
        .array~new(2,3)~of(1~upto(6))
        1 2 3
        4 5 6

    If there is only one argument, and this argument is a doer, then the doer is called for each cell to initialize.
    Implicit arguments :
        arg(1) : item : position of the current cell, from 1 to size.
        arg(2) : index : position of the current cell, in each dimension.
            When the rank is 1, the index is an integer.
            Invariant: index == item.
            When the rank is > 1, the index is an array [i1,i2,...,iRank].
            Invariant:  1 + rank**(rank-1)*(i1-1) + rank**(rank-2)*(i2-1) + ... + rank**(0)*(iRank-1) == item
        arg(3) : array : the array under construction.
    The value returned by the doer is the item for the current cell.
    If no value returned then the cell remains unassigned.
        .array~new(2,3)~of{if item//4 <> 0 then 10*item}
        10 20 30
        .. 50 60
        70 .. 90

    Otherwise each argument is an item as-is.
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
    JLF 19/09/2017 : fixed.

    The items are a list of values that must be assigned to the cells of the array.
    Rules inspired by APL :
    If there are too many items, the extra items are ignored.
    If there are fewer items than implied by the dimensions, the list of items is reused as
    many times as necessary to fill the array.
        .array~new(2,3)~of(1,2)
        1 2 1
        2 1 2
    */
    use arg ... -- optional 0..n arguments

    if self~dimension == 0 then raise syntax 93.900 array("Array with no dimension")

    scalar = .false
    if self~dimension == 1, self~dimension(1) == 0 then do
        -- APL:
        --     The expression ⍬⍴Array is widely used to return the first item of an array as a scalar,
        --     and in particular to convert a 1-item vector into a scalar.
        --     Remember: An array having an empty shape is a scalar.
        --     ⍬ is the empty numeric vector Zilde: ⍴⍬ is 0.
        --     ⍬ ⍴ 1 2 3 is 1.
        --     ⍬ ⍴ ⍬ is 0. [JLF] not clear, why 0 ? ok, ⍬ is a numeric vector, but it's empty...
        -- ooRexx :
        --    v(1,2,3)~reshape(v())= -- 1
        --    v()~reshape(v())= -- .nil
        scalar = .true
    end

    -- Only one of the following variables will be used
    oneValue = .false
    arrayIn = .nil
    doer = .nil
    supplier = .nil

    if arg() == 1 then do
        use arg arg1
        if arg1~isA(.String) then do
            -- Do this test to not convert the strings to doers
            oneValue = .true
            value = arg1
        end
        else if arg1~hasMethod("functionDoer") then doer = arg1~functionDoer("use arg item, index")~arity(2)
        else if arg1~hasMethod("doer") then doer = arg1~doer
        else if arg1~isA(.array), arg1~dimension == 1 then arrayIn = arg1 -- omitted item in the array passed as argument ==> no item in the array under initialization
        else if arg1~hasMethod("supplier") then supplier = arg1~supplier -- omitted items are ignored, because not available from the supplier
        else do
            oneValue = .true
            value = arg1
        end
    end
    else arrayIn = arg(1, "a")

    -- Optimization
    if oneValue == .true then do
        if scalar then return value -- APL-like
        self~fill(value)
        return self
    end

    selfIntegerIndex = 1
    if self~dimension == 1 then selfArrayIndex = 1
                           else selfArrayIndex = .array~new(self~dimension)~~fill(1) -- Initializes all indexes to 1

    if .nil <> arrayIn then do
        arrayInIndex = 1
        arrayInSize = arrayIn~size
    end

    sourceEnd = 0
    selfReuseIntegerIndex = 1
    if self~dimension == 1 then selfReuseArrayIndex = 1
                           else selfReuseArrayIndex = .array~new(self~dimension)~~fill(1) -- Initializes all indexes to 1

    if .nil <> doer then arity = doer~arity

    do while selfIntegerIndex <= self~size | scalar
        if sourceEnd == 0 then do
            -- if initialization with an array (covers the case of several arguments passed to the method)
            if .nil <> arrayIn then do
                if arrayInIndex > arrayInSize then sourceEnd = selfIntegerIndex
                else do
                    if scalar then return arrayIn[arrayInIndex]
                    if arrayIn~hasIndex(arrayInIndex) then self~put(arrayIn[arrayInIndex], selfArrayIndex)
                    arrayInIndex += 1
                end
            end

            -- if initialization with a doer
            else if .nil <> doer then do
                if self~dimension == 1 then index = selfArrayIndex
                                       else index = selfArrayIndex~copy
                if arity >= 2 then doer~do(selfIntegerIndex, index)
                else if arity == 1 then doer~do(selfIntegerIndex)
                else doer~do
                if var("result") then do
                    if scalar then return result
                    self~put(result, selfArrayIndex)
                end
                else do
                    -- Needed to offer the same behaviour for
                    --     .array~new(2,3)~of(1~upto(5))
                    --     .array~new(2,3)~of(1~generate.upto(5))
                    if doer~hasMethod("isEnded"), doer~isEnded then sourceEnd = selfIntegerIndex -- detection of end of coactivity
                end
            end

            -- if initialization with a supplier
            else if .nil <> supplier then do
                if \supplier~available then sourceEnd = selfIntegerIndex
                else do
                    if scalar then return supplier~item
                    self~put(supplier~item, selfArrayIndex)
                    supplier~next
                end
            end
        end
        if sourceEnd <> 0 then do -- APL-like : If there are fewer items than implied by the dimensions, the list of items is reused as  many times as necessary to fill the array.
            if sourceEnd == 1 then leave -- can stop now because nothing to reuse (happens when you pass an empty provider)
            if selfReuseIntegerIndex == sourceEnd then do
                selfReuseIntegerIndex = 1 -- rewind
                if self~dimension == 1 then selfReuseArrayIndex = 1 -- rewind
                                       else selfReuseArrayIndex~fill(1) -- rewind all indexes to 1
            end
            -- no need to test scalar here, because we are in the case 'reuse items'
            if self~hasIndex(selfReuseArrayIndex) then self~put(self[selfReuseArrayIndex], selfArrayIndex)
            selfReuseIntegerIndex += 1
            if self~dimension == 1 then selfReuseArrayIndex += 1
                                   else self~incrementIndex(selfReuseArrayIndex)
        end
        selfIntegerIndex += 1
        if self~dimension == 1 then selfArrayIndex += 1
                               else self~incrementIndex(selfArrayIndex)
    end
    if scalar then return .nil -- I think APL would return 0 (⍬ ⍴ ⍬ is 0), but .nil seems less surprising.
    return self
