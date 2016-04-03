/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.


v0 = a(0)~of{index} -- equivalent to v()
v0=
    []
    an Array (shape [0], 0 items)

v1 = a(1)~of{index} -- equivalent to v(1)
v1=
    [1]
    an Array (shape [1], 1 items)
    1 : 1

v2 = a(2)~of{index} -- equivalent to v(1,2)
v2=
    [1,2]
    an Array (shape [2], 2 items)
    1 : 1
    2 : 2

v3 = a(3)~of{index} -- equivalent to v(1,2,3)
v3=
    [1,2,3]
    an Array (shape [3], 3 items)
    1 : 1
    2 : 2
    3 : 3

a33 = a(3,3)~of{index}
a33=
    an Array (shape [3,3], 9 items)
    [1,1] : [1,1]
    [1,2] : [1,2]
    [1,3] : [1,3]
    [2,1] : [2,1]
    [2,2] : [2,2]
    [2,3] : [2,3]
    [3,1] : [3,1]
    [3,2] : [3,2]
    [3,3] : [3,3]

APL     ,           ravel       monadic function (Comma)
ooRexx  ~each
inverse of reshape, which turns any data into a vector whose length is the product
of the shape vector (the dimensions) of the operand array
a33~each=
[[1,1],[1,2],[1,3],[2,1],[2,2],[2,3],[3,1],[3,2],[3,3]]

*/

--::options trace i

::routine a public
    -- Empty array of specified shape

    -- if arg() == 0 then return .array~new -- no dimension (yet), can be set later.
    -- Bug ? .array~new~dimensions returns [0], should return an array with no dimension (not [] which is an empty vector returned for arrays definitively with 0 dimension).

    return .array~new(arg(1, "a")) -- dimension assigned, no longer possible to change it
    -- Remember :
    -- When called with no argument, this function returns an array
    -- which is definitively an array with no dimension : an Array (no shape , 0 items)
    -- Any attempt to assign a value to this array raises the error
    -- "Too many subscripts for array; 0 expected"

::routine v public
    -- Vector (rank = 1)
    -- When no argument, arg(1, "a") returns an array with NO dimension. This is not what we want here, we want 1 dimension.
    if arg() == 0 then return .array~new(0) -- empty vector
    return arg(1, "a")


::routine sameShapes public
    use strict arg a1, a2
    if a1~dimension <> a2~dimension then return .false
    do i=1 to a1~dimension
        if a1~dimension(i) <> a2~dimension(i) then return .false
    end
    return .true


/******************************************************************************/
-- Object can't inherit from a mixinclass (would raise "cannot inherit from itself")
::extension Object -- APLObject

::method rank
    /*
        R←⍴⍴Y
        An array may have 0 or more axes or dimensions.
        The number of axes of an array is known as its rank.
        An array with 0 axes (rank 0) is called a scalar
        An array with 1 axis (rank 1) is called a vector.
        An array with 2 axes (rank 2) is called a matrix or table.
        An array with 3 axes (rank 3) is called a cube.
        An array with more than 2 axes is called a multi-dimensional array
    */
    shape = self~shape
    if shape~dimension == 0 then return -1 -- special case which does not exist in APL : an array with no dimension yet assigned
    return shape~items


::method shape
    -- R←⍴Y (Rho)
    -- The shape of a scalar is an empty vector []
    return v()


::method shapeToString
   -- Helper to display the shape of any object
   shape = self~shape
   if shape~dimension == 0 then return "no shape"
   return "[" || shape~toString("L", ",") || "]"


::method depth
    -- R←≡Y (Equal Underbar)
    -- Depth (≡) indicates the degree of nesting within an array.
    -- It returns a non-negative integer which defines the maximum number of levels
    -- of structure to be penetrated in order to get to a simple scalar where simple means non-nested.
    return 0


::method reshape
    -- R←X⍴Y (Rho)
    -- args : new dimension(s)
    if arg() == 1 then return .array~new(arg(1))~of(self) -- to support an array as argument
    return .array~new(arg(1, "a"))~of(self)


::method enclose
    -- R←⊂Y (Left Shoe)
    -- If Y is a simple scalar, R is the simple scalar unchanged.
    -- Otherwise, R has a depth whose magnitude is one greater than the magnitude of the depth of Y.
    -- Here, Y is a simple scalar.
    return self


::method disclose
    -- R←⊃Y (Right Shoe)
    -- Disclose is the inverse of Enclose.  The identity R←→⊃⊂R holds for all R.
    return self


/******************************************************************************/
::class "APLArray" mixinclass Object public

::method shape
    -- The shape of an array is an array which gives the size of each dimension (APL).
    dimensions = self~dimensions
    if self~dimension == 0 then do
        -- Two cases:

        -- array definitively with no dimension : .array~new(.array~new)
        -- This case exist in APL : the scalars have no dimension, their shape is an empty vector
        if dimensions~items == 0 then return v() -- empty vector (1 dimension, 0 item)

        -- array with no dimension yet assigned (the first assignment will determine the dimension).
        -- This case does not exist in APL
        -- Bug ? self~dimensions returns [0]. It should return an array with no dimension.
        return a() -- really no shape yet, return an array with no dimension.
    end
    return dimensions


::method depth
    -- R←≡Y (Equal Underbar)
    -- Here, Y is an array. Y has depth 1 greater than that of its most deeply nested item.
    use arg stack=(.queue~new)
    level = stack~index(self)
    if .nil <> level then return infinity
    stack~push(self)
    depth = 1 + self~reduce(0){depth = item~depth; if depth > accu then depth}
    stack~pull
    return depth


::method enclose
    -- R←⊂Y (Left Shoe)
    -- Here, Y is an array.  R is a scalar array whose item is the array Y.
    -- R has a depth whose magnitude is one greater than the magnitude of the depth of Y.
    return .EnclosedArray~new(self)


/******************************************************************************/
::class "EnclosedArray" public inherit ArrayOperators ArrayPrettyPrinter

::method init
    expose object
    use strict arg object


::method enclose
    -- R←⊂Y (Left Shoe)
    -- Here, Y is a scalar array.  R is a scalar array whose item is the scalar array Y.
    -- R has a depth whose magnitude is one greater than the magnitude of the depth of Y.
    return .EnclosedArray~new(self)


::method disclose
    -- R←⊃Y (Right Shoe)
    -- Disclose is the inverse of Enclose.  The identity R←→⊃⊂R holds for all R.
    expose object
    return object


::method depth
    -- R←≡Y (Equal Underbar)
    -- Here, Y is a scalar array.  R is a scalar array whose item is the scalar array Y.
    -- R has a depth whose magnitude is one greater than the magnitude of the depth of Y.
    expose object
    return 1 + object~depth


::method leftElementWise
    -- Don't forward to the enclosed object, it's important to keep the class Enclosed
    forward class (super)


::method rightElementWise
    -- Don't forward to the enclosed object, it's important to keep the class Enclosed
    forward class (super)


::method ppRepresentation
    -- Don't forward to the enclosed object, the class ArrayPrettyPrinter takes care of the instances of EnclosedArray
    forward class (super)


::method unknown unguarded
    expose object
    use arg msg, args
    forward message (msg) arguments (args) to (object)


/******************************************************************************/
::class "ArrayInitializer" mixinclass Object public

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

    The items are a list of values that must be assigned to the cells of the array.
    Rules inspired by APL :
    If there are too many items, the extra items are ignored.
    If there are fewer items than implied by the dimensions, the list of items is reused as
    many times as necessary to fill the array.
        .array~new(2,3)~of(1,2)
        1 2 1
        2 1 2
    */
    use strict arg arg1, ... -- at least one argument

    if self~dimension == 0 then raise syntax 93.900 array("Array with no dimension")

    -- Only one of the following variables will be used
    oneValue = .false
    arrayIn = .nil
    doer = .nil
    supplier = .nil

    if arg() == 1 then do
        if arg(1)~isA(.String) then do
            -- Do this test to not convert the strings to doers
            oneValue = .true
            value = arg(1)
        end
        else if arg(1)~hasMethod("functionDoer") then doer = arg(1)~functionDoer("use arg item, index, array")~arity(3)
        else if arg(1)~hasMethod("doer") then doer = arg(1)~doer
        else if arg(1)~isA(.array), arg(1)~dimension == 1 then arrayIn = arg(1) -- omitted item in the array passed as argument ==> no item in the array under initialization
        else if arg(1)~hasMethod("supplier") then supplier = arg(1)~supplier -- omitted items are ignored, because not available from the supplier
        else do
            oneValue = .true
            value = arg(1)
        end
    end
    else arrayIn = arg(1, "a")

    -- Optimization
    if oneValue == .true then do
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
                if self~dimension == 1 then index = selfArrayIndex
                                       else index = selfArrayIndex~copy
                if arity >= 3 then doer~do(selfIntegerIndex, index, self)
                else if arity == 2 then doer~do(selfIntegerIndex, index)
                else if arity == 1 then doer~do(selfIntegerIndex)
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
                if self~dimension == 1 then selfReuseArrayIndex = 1 -- rewind
                                       else selfReuseArrayIndex~fill(1) -- rewind all indexes to 1
            end
            if self~hasIndex(selfReuseArrayIndex) then self~put(self[selfReuseArrayIndex], selfArrayIndex)
            selfReuseIntegerIndex += 1
            if self~dimension == 1 then selfReuseArrayIndex += 1
                                   else self~incrementIndex(selfReuseArrayIndex)
        end
        selfIntegerIndex += 1
        if self~dimension == 1 then selfArrayIndex += 1
                               else self~incrementIndex(selfArrayIndex)
    end
    return self


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

::method ppRepresentation
    /*
    Return a condensed string representation of the array.
    Ex :
    .array~of(1,"two", .array~of(1, "two", 3), .array~of(1, "two"))~ppRepresentation -- [[1,'two',[1,'two',3],[1,'two']]]
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
    -- Remember : this code has been duplicated in pipe.rex, routine dataflow_representation.
    if val~isA(.enclosedArray) then do
        -- Remember : would be better to have a method ppRepresentation on class EnclosedArray, but I prefer to remain close to dataflow_representation.
        level = stack~index(val)
        if .nil <> level then return "*"level-1
        stack~push(val)
        valstr = "<"val~ppRepresentation(maxItems, sparse, ellipsis, separator, val~disclose, stack)">"
        stack~pull
        return valstr
    end
    else if val~isA(.array), val~dimension == 1 then do
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
            valstr ||= sep || val~ppRepresentation(maxItems, sparse, ellipsis, separator, item, stack)
            sep = separator
            items += 1
            i = index + 1 -- next index
            s~next -- skip sparse section, if any
        end
        if maxItems >= 0, items < maxItems then do -- if not truncated
            if i <= val~size then do
                valstr ||= sep || sparse
            end
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
            -- For the arrays, indicate their shape
            if val~isA(.array) then valstr = "("valstr val~shapeToString")"
            else valstr = "("valstr")"
        end
        return valstr
    end


/******************************************************************************/
::class "ArrayOperators" mixinclass Object public

::attribute defaultSparseValue

::method leftElementWise
    use strict arg action, rightArg=.nil, recursion=(.identityTable~new)
    counterpart = recursion[self]
    if counterpart <> .nil then return counterpart -- stop infinite recursion
    if \ arg(2, "e") then do
        -- unary operator (op self):
        -- op Array
        -- op EnclosedArray

        if action~hasMethod("functionDoer") then doer = action~functionDoer("use arg item, index")~arity(2)
                                            else doer = action~doer
        arity = doer~arity

        if self~isA(.EnclosedArray) then do
            arg = self~disclose
            r = .array~new(arg~dimensions)
            recursion[arg] = r -- will be used to build the resulting infinite array
            er = r~enclose
            recursion[self] = er -- will be used to build the resulting enclosed infinite array
        end
        else do
            arg = self
            r = .array~new(arg~dimensions)
            recursion[arg] = r -- will be used to build the resulting infinite array
        end
        supplier = arg~supplier
        do while supplier~available
            index = supplier~index
            item = supplier~item
            if item~isA(.array) | item~isA(.EnclosedArray) then do
                r[index] = item~leftElementWise(doer, , recursion)
            end
            else do
                if arity >= 2 then doer~do(item, index)
                              else doer~do(item)
                if var("result") then r[index] = result
            end
            supplier~next
        end
        if self~isA(.EnclosedArray) then do
            recursion~remove(arg)
            recursion~remove(self)
            return er
        end
        else do
            recursion~remove(self)
            return r
        end
    end

    -- binary operator (self op rightArg):
    -- Array op Array : element wise
    -- Array op EnclosedArray : manage enclosedArray as a whole
    -- Array op Other
    -- EnclosedArray op Array : return rightArg~rightElementWise(doer, self)
    -- EnclosedArray op EnclosedArray : error
    -- EnclosedArray op Other : manage enclosedArray as a non enclosed array

    if action~hasMethod("functionDoer") then doer = action~functionDoer("use arg item1, item2, index1, index2")~arity(4)
                                        else doer = action~doer
    arity = doer~arity

    if self~isA(.EnclosedArray) then do
        -- enclosed array on left
        if rightArg~isA(.EnclosedArray) then do
            -- binary operator with enclosed array on left & right : EnclosedArray op EnclosedArray
            raise syntax 93.900 array("Element-wise operation does not support two enclosed arrays")
        end
        if rightArg~isA(.array) then do
            -- binary operator with enclosed array on left & not enclosed array on right : EnclosedArray op Array
            return rightArg~rightElementWise(doer, self)
        end
    end

    -- not enclosed array on left
    -- or enclosed array on left and not array on right: in this case, the enclosed array is handled as a not enclosed array

    if rightArg~isA(.array) then do
        -- binary operator with not enclosed array on left & right : Array op Array
        if \sameShapes(self, rightArg) then raise syntax 93.900 array("Shapes are not equal")
        r = .array~new(self~dimensions)
        recursion[self] = r -- will be used to build the resulting infinite array
        supplier = self~supplier
        -- TODO : sparse array not supported. Must use TWO suppliers.
        do while supplier~available
            index = supplier~index
            item = supplier~item
            if item~isA(.array) | item~isA(.EnclosedArray) then do
                r[index] = item~leftElementWise(doer, rightArg[index], recursion)
            end
            else do
                if arity >= 4 then doer~do(item, rightArg[index], index, index)
                              else doer~do(item, rightArg[index])
                if var("result") then r[index] = result
            end
            supplier~next
        end
        recursion~remove(self)
        return r
    end
    else do
        -- Remaining cases:
        -- Array op EnclosedArray
        -- Array op Other
        -- EnclosedArray op Other
        if self~isA(.EnclosedArray) then do
            leftArg = self~disclose
            r = .array~new(leftArg~dimensions)
            recursion[leftArg] = r -- will be used to build the resulting infinite array
            er = r~enclose
            recursion[self] = er -- will be used to build the resulting enclosed infinite array
        end
        else do
            leftArg = self
            r = .array~new(leftArg~dimensions)
            recursion[leftArg] = r -- will be used to build the resulting infinite array
        end
        supplier = leftArg~supplier
        do while supplier~available
            index = supplier~index
            item = supplier~item
            if item~isA(.array) | item~isA(.EnclosedArray) then do
                r[index] = item~leftElementWise(doer, rightArg, recursion)
            end
            else do
                if arity >= 4 then doer~do(item, rightArg, index, index)
                              else doer~do(item, rightArg)
                if var("result") then r[index] = result
            end
            supplier~next
        end
        if self~isA(.EnclosedArray) then do
            recursion~remove(leftArg)
            recursion~remove(self)
            return er
        end
        else do
            recursion~remove(self)
            return r
        end
    end

::method "rightElementWise"
    -- no unary operator here.
    -- Array op Array : delegate to leftElementWise
    -- Array op EnclosedArray : delegate to leftElementWise
    -- EnclosedArray op Array : specific implementation
    -- EnclosedArray op EnclosedArray : error
    -- Other op Array : specific implementation
    -- Other op EnclosedArray : specific implementation

    use strict arg action, leftArg, recursion=(.identityTable~new)
    counterpart = recursion[self]
    if counterpart <> .nil then return counterpart -- stop infinite recursion

    if action~hasMethod("functionDoer") then doer = action~functionDoer("use arg item1, item2, index1, index2")~arity(4)
                                        else doer = action~doer
    arity = doer~arity

    if leftArg~isA(.array) then return leftArg~leftElementWise(doer, self)

    if leftArg~isA(.EnclosedArray), self~isA(.EnclosedArray) then do
        -- binary operator with enclosed array on left & right : EnclosedArray op EnclosedArray
        raise syntax 93.900 array("Element-wise operation does not support two enclosed arrays")
    end

    -- Remaining cases:
    -- EnclosedArray op Array : enclosedArray managed as a whole
    -- Other op Array : specific implementation
    -- Other op EnclosedArray : disclose the enclosed array

    if self~isA(.EnclosedArray) then do
        rightArg = self~disclose
        r = .array~new(rightArg~dimensions)
        recursion[rightArg] = r -- will be used to build the resulting infinite array
        er = r~enclose
        recursion[self] = er -- will be used to build the resulting enclosed infinite array
    end
    else do
        rightArg = self
        r = .array~new(rightArg~dimensions)
        recursion[rightArg] = r -- will be used to build the resulting infinite array
    end
    supplier = rightArg~supplier
    do while supplier~available
        index = supplier~index
        item = supplier~item
        if item~isA(.array) | item~isA(.EnclosedArray) then do
            r[index] = item~rightElementWise(doer, leftArg, recursion)
        end
        else do
            if arity >= 4 then doer~do(leftArg, item, index, index)
                          else doer~do(leftArg, item)
            if var("result") then r[index] = result
        end
        supplier~next
    end
    if self~isA(.EnclosedArray) then do
        recursion~remove(rightArg)
        recursion~remove(self)
        return er
    end
    else do
        recursion~remove(self)
        return r
    end

::method "+"
    if arg() == 0 then return self~leftElementWise("+")
    if arg() == 1 then return self~leftElementWise("+", arg(1))

::method "+op:right"
    if arg() == 1 then return self~rightElementWise("+", arg(1))

::method "-"
    if arg() == 0 then return self~leftElementWise("-")
    if arg() == 1 then return self~leftElementWise("-", arg(1))

::method "-op:right"
    if arg() == 1 then return self~rightElementWise("-", arg(1))

::method "*"
    if arg() == 1 then return self~leftElementWise("*", arg(1))

::method "*op:right"
    if arg() == 1 then return self~rightElementWise("*", arg(1))

::method "/"
    if arg() == 1 then return self~leftElementWise("/", arg(1))

::method "/op:right"
    if arg() == 1 then return self~rightElementWise("/", arg(1))

::method "%"
    if arg() == 1 then return self~leftElementWise("%", arg(1))

::method "%op:right"
    if arg() == 1 then return self~rightElementWise("%", arg(1))

::method "//"
    if arg() == 1 then return self~leftElementWise("//", arg(1))

::method "//op:right"
    if arg() == 1 then return self~rightElementWise("//", arg(1))

::method "**"
    if arg() == 1 then return self~leftElementWise("**", arg(1))

::method "**op:right"
    if arg() == 1 then return self~rightElementWise("**", arg(1))

::method " "
    if arg() == 1 then return self~leftElementWise(" ", arg(1))

::method " op:right"
    if arg() == 1 then return self~rightElementWise(" ", arg(1))

::method "||"
    if arg() == 1 then return self~leftElementWise("||", arg(1))

::method "||op:right"
    if arg() == 1 then return self~rightElementWise("||", arg(1))

::method "" -- abuttal
    if arg() == 1 then return self~leftElementWise("", arg(1))

::method "op:right" -- abuttal
    if arg() == 1 then return self~rightElementWise("", arg(1))

::method elementEquals
    if arg() == 1 then return self~leftElementWise("=", arg(1))

/* Not activated
::method "="
    if arg() == 1 then return self~leftElementWise("=", arg(1))
*/

/* Not activated
::method "=op:right"
    if arg() == 1 then return self~rightElementWise("=", arg(1))
*/

::method elementNotEquals
    if arg() == 1 then return self~leftElementWise("\=", arg(1))

/* Not activated
::method "\="
    if arg() == 1 then return self~leftElementWise("\=", arg(1))
*/

/* Not activated
::method "\=op:right"
    if arg() == 1 then return self~rightElementWise("\=", arg(1))
*/

/* Not activated
::method "<>"
    if arg() == 1 then return self~leftElementWise("<>", arg(1))
*/

/* Not activated
::method "<>op:right"
    if arg() == 1 then return self~rightElementWise("<>", arg(1))
*/

::method elementStrictEquals
    if arg() == 1 then return self~leftElementWise("==", arg(1))

/* Not activated
::method "=="
    if arg() == 1 then return self~leftElementWise("==", arg(1))
*/

/* Not activated
::method "==op:right"
    if arg() == 1 then return self~rightElementWise("==", arg(1))
*/

::method elementStrictNotEquals
    if arg() == 1 then return self~leftElementWise("\==", arg(1))

/* Not activated
::method "\=="
    if arg() == 1 then return self~leftElementWise("\==", arg(1))
*/

/* Not activated
::method "\==op:right"
    if arg() == 1 then return self~rightElementWise("\==", arg(1))
*/

/* Not activated
::method "><"
    if arg() == 1 then return self~leftElementWise("><", arg(1))
*/

/* Not activated
::method "><op:right"
    if arg() == 1 then return self~rightElementWise("><", arg(1))
*/

::method "\"
    use strict arg -- none, no binary version
    return self~leftElementWise("\")

::method ">"
    if arg() == 1 then return self~leftElementWise(">", arg(1))

::method ">op:right"
    if arg() == 1 then return self~rightElementWise(">", arg(1))

::method "<"
    if arg() == 1 then return self~leftElementWise("<", arg(1))

::method "<op:right"
    if arg() == 1 then return self~rightElementWise("<", arg(1))

::method ">="
    if arg() == 1 then return self~leftElementWise(">=", arg(1))

::method ">=op:right"
    if arg() == 1 then return self~rightElementWise(">=", arg(1))

::method "\<"
    if arg() == 1 then return self~leftElementWise("\<", arg(1))

::method "\<op:right"
    if arg() == 1 then return self~rightElementWise("\<", arg(1))

::method "<="
    if arg() == 1 then return self~leftElementWise("<=", arg(1))

::method "<=op:right"
    if arg() == 1 then return self~rightElementWise("<=", arg(1))

::method "\>"
    if arg() == 1 then return self~leftElementWise("\>", arg(1))

::method "\>op:right"
    if arg() == 1 then return self~rightElementWise("\>", arg(1))

::method ">>"
    if arg() == 1 then return self~leftElementWise(">>", arg(1))

::method ">>op:right"
    if arg() == 1 then return self~rightElementWise(">>", arg(1))

::method "<<"
    if arg() == 1 then return self~leftElementWise("<<", arg(1))

::method "<<op:right"
    if arg() == 1 then return self~rightElementWise("<<", arg(1))

::method ">>="
    if arg() == 1 then return self~leftElementWise(">>=", arg(1))

::method ">>=op:right"
    if arg() == 1 then return self~rightElementWise(">>=", arg(1))

::method "\<<"
    if arg() == 1 then return self~leftElementWise("\<<", arg(1))

::method "\<<op:right"
    if arg() == 1 then return self~rightElementWise("\<<", arg(1))

::method "<<="
    if arg() == 1 then return self~leftElementWise("<<=", arg(1))

::method "<<=op:right"
    if arg() == 1 then return self~rightElementWise("<<=", arg(1))

::method "\>>"
    if arg() == 1 then return self~leftElementWise("\>>", arg(1))

::method "\>>op:right"
    if arg() == 1 then return self~rightElementWise("\>>", arg(1))

::method "&"
    if arg() == 1 then return self~leftElementWise("&", arg(1))

::method "&op:right"
    if arg() == 1 then return self~rightElementWise("&", arg(1))

::method "|"
    if arg() == 1 then return self~leftElementWise("|", arg(1))

::method "|op:right"
    if arg() == 1 then return self~rightElementWise("|", arg(1))

::method "&&"
    if arg() == 1 then return self~leftElementWise("&&", arg(1))

::method "&&op:right"
    if arg() == 1 then return self~rightElementWise("&&", arg(1))
