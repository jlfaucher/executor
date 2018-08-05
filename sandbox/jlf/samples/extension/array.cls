/*
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
::requires "extension/infinity.cls"

::routine a public
    -- Empty array of specified shape.
    -- Remember :
    -- When called with no argument, this function returns an array
    -- which is definitively an array with no dimension : an Array (shape [] , 0 items)
    -- Any attempt to assign a value to this array raises the error
    -- "Too many subscripts for array; 0 expected"

    -- if arg() == 0 then return .array~new -- no dimension (yet), can be set later.
    -- Bug ? .array~new~dimensions returns [0], should return an array with no dimension (not [] which is an empty vector returned for arrays definitively with 0 dimension).

    -- To support that : a(myMatrix~shape)
    if arg() == 1, arg(1)~isa(.array) then return .array~new(arg(1))

    return .array~new(arg(1, "a")) -- dimension assigned, no longer possible to change it


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


::routine shape public
    -- Remember: same procedure is defined in rgf_util2
    -- I don't want a dependency on rgf_util2 in this package,
    -- must find a way to eliminate this double definition.
    use arg coll, separator=""
    if coll~hasMethod("shapeToString"), coll~isA(.array) then do
        shape = coll~shapeToString
        if shape <> "no shape" then shape = "shape" shape
        return shape || separator
    end
    return ""


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


::method each
    -- R←,Y (Ravel)
    -- Y may be any array. R is a vector of the elements of Y taken in row-major order.
    -- Seen in http://www.dyalog.com/mastering-dyalog-apl-errata.htm
    -- B 51 debate: "A single number has no dimensions" .. what about ⍴,1 ?
    -- ⍴,1 is 1, that's why I add this method
    return v(self)


/******************************************************************************/
::class "APLArray" mixinclass Object public

/*
                  | value                         | dimension | dimensions                    | size | shape
------------------+-------------------------------+-----------+-------------------------------+------+-----------------------------
.array~new        | an Array (no shape, 0 items)  | 0         | [0]                           | 0    | an Array (shape [], 0 items)
.array~new(a())   | an Array (shape [], 0 items)  | 0         | an Array (no shape, 0 items)  | 1    | []
.array~new(v())   | an Array (shape [], 0 items)  | 0         | an Array (no shape, 0 items)  | 1    | []
a()               | an Array (shape [], 0 items)  | 0         | an Array (no shape, 0 items)  | 1    | []
v()               | []                            | 1         | [0]                           | 0    | [0]
*/
::method shape
    -- The shape of an array is an array which gives the size of each dimension (APL).
    dimensions = self~dimensions
    if self~dimension == 0 then do
        -- Two cases:

        -- array definitively with no dimension : .array~new(.array~new), also returned by a()
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
    if .nil <> level then return .infinity~positive
    stack~push(self)
    depth = 1 + self~reduce(0){expose stack; depth = item~depth(stack); if depth > accu then depth}
    stack~pull
    return depth


::method enclose
    -- R←⊂Y (Left Shoe)
    -- Here, Y is an array.  R is a scalar array whose item is the array Y.
    -- R has a depth whose magnitude is one greater than the magnitude of the depth of Y.
    return .EnclosedArray~new(self)


::method isSparse
    /*
    The sparse arrays in ooRexx are not so sparse... at least in term of storage optimization.
    All the cells are allocated. A matrix 1000x1000 with no value inside will use 1 000 000 cells.
    Not so bad for small arrays, that simplifies the implementation.
        .array~new(2,2)~~put(12,1,2)
            1,1     OREF_NULL   offset=0
            1,2     12          offset=1
            2,1     OREF_NULL   offset=2
            2,2     OREF_NULL   offset=3
    ALL the cells are allocated, the sparse cells have the value OREF_NULL.
    In the C++ implementation, the only way to know if an array is sparse is to iterate over
    all the cells (items) and test if there is at least one non-assigned cell.
    For the ooRexx user, a possible way is to compare the number of items with the size.
    Internally, the method ~items count the cells <> OREF_NULL (at each call, not stored).
    The bigger the array, the longer it takes :
        smallArray = .array~new(10,10); do 10000; n = smallArray~items; end -- near 0 sec
        bigArray = .array~new(1000,1000); do 10000; n = bigArray~items; end -- around 8 sec
    */
    return self~items <> self~size


::method atIndex
    -- An index is an indice (whole number), or a vector of [vector of] indices.
    -- An index can be sparse: an omitted indice lets select all the items in the corresponding dimension.
    -- For convenience, the items of the vector can be passed as arguments :
    --     atIndex(1,,1) is the same as atIndex(v(1,,1)).
    -- The result can be a scalar or an array.
    if arg() == 1 then do
        use arg index
        if index~isa(.string), index~datatype("W") then do
            if self~dimension <= 1 then return self[index] -- one item, indexed by a wholenumber.
            -- here more complex... must return a subarray.
            if index > self~dimension(1) then return .nil
            subshape = self~shape~section(2) -- Ex : for a matrix whose shape is [6,3], the result is a vector of shape [3]
            myIndex = index
            -- REMEMBER ! If index is exposed in the closure, then it's overwritten by the implicit argument index.
            subindexes = self~allindexes~select{expose myIndex; item[1] == myIndex}
            subindexes = subindexes~reshape(subshape)
            return subindexes~leftElementWise({itemRight[itemLeft]}, self~enclose, 1)
        end
        if index~isa(.array) then do
            -- Select the values situated at the intersections of the specified rows and columns : rows 1 5 6, columns 1 3
            --     matrix[1 5 6;1 3] or (1 5 6) (1 3) ⌷ matrix
            --         41 38
            --         19 64
            --         45 74
            if sameShapes(index, self~shape), index~depth == 1 then do
                -- TODO:
                return self[index] -- Case one item, indexed by an array
            end
        end
        if index~isa(.array) then indexString = index~ppRepresentation
        else indexString = index~string
        raise syntax 93.900 array("Unsupported index:" indexString)
    end
    return self~atIndex(arg(1, "a"))


::method indexer
    /*
    This method takes an array of indexes as parameter.
    The array of indexes can have any shape, the result will have the same shape.
    For convenience, when the array of indexes is a vector, the items of the vector can be passed as arguments :
        indexer(1,1,1) is the same as indexer(v(1,1,1)).
    An index is an indice (whole number), or a vector of [vector of] indices.
    An index can be sparse: an omitted item lets select all the items in the corresponding dimension.
    The result is ALWAYS an array.

    Indexing a vector
    -----------------
    It is possible to extract several items in a single operation, and in any order.
    An item can be selected more than once.
    APL
        vector ← 41 26 38 14 87 52 30 28 19 65 40 55 19 31 64 45 82 74
            41 26 38 14 87 52 30 28 19 65 40 55 19 31 64 45 82 74
        vector[3] or 3 ⌷ vector
            38
        vector[3 7 1 3 3 12]
            38 30 41 38 38 55
    ooRexx
        vector = v(41,26,38,14,87,52,30,28,19,65,40,55,19,31,64,45,82,74)
        vector~indexer(3) or vector~indexer(v3))
        vector~indexer(3,7,1,3,3,12) =

    The index may be an array of any shape: scalar, vector, matrix, or an array of higher rank.
    When a vector is indexed by an array, the result has exactly the same shape as the index
    array, as if each item of the index had been replaced by the item it designates:
    APL
        index ← 3 5 ⍴ 5 5 4 4 8 6 12 6 11 12 10 6 1 4 9
             5  5 4  4  8
             6 12 6 11 12
            10  6 1  4  9
        vector[index]
            87 87 14 14 28
            52 55 52 40 55
            65 52 41 14 19
    ooRexx
        index = a(3,5)~of(5,5,4,4,8,6,12,6,11,12,10,6,1,4,9)
        vector~indexer(index) =

    Indexing an array
    -----------------
    Similar to vector indexing, but with one index for the row and one for the column:
    APL
        matrix ← 6 3 ⍴ 41 26 38 14 87 52 30 28 19 65 40 55 19 31 64 45 82 74
            41 26 38
            14 87 52
            30 28 19
            65 40 55
            19 31 64
            45 82 74
        matrix[2;3] or 2 3 ⌷ matrix
            52
        index ← (1 1) (2 2) (3 3)
             1 1  2 2  3 3
        matrix[index]
            41 87 19
        matrix[2 3 ⍴ index]
            41 87 19
            41 87 19
    ooRexx
        matrix = a(6,3)~of(41,26,38,14,87,52,30,28,19,65,40,55,19,31,64,45,82,74)
        matrix[2,3] or matrix~indexer(2,3) or matrix~indexer(v(2,3))
        index = v(  v(1,1), v(2,2), v(3,3)  )
        matrix~indexer(index) =
        matrix~indexer(a(2,3)~of(index)) =

    Remaining to implement
    ----------------------
    Vector[]                select the whole vector
    Matrix[;]               select the whole matrix
    Cube[;;]                select the whole cube
    etc...

    Select the values situated at the intersections of the specified rows and columns : rows 1 5 6, columns 1 3
        matrix[1 5 6;1 3] or (1 5 6) (1 3) ⌷ matrix
            41 38
            19 64
            45 74

    To specify all the items of a dimension, you just omit the index for that dimension, but you must not omit the semi-colon attached to it.
        cube ← 2 3 4 ⍴ 41 26 38 14 87 52 30 28 19 65 40 55 19 31 64 45 82 74
            41 26 38 14
            87 52 30 28
            19 65 40 55

            19 31 64 45
            82 74 41 26
            38 14 87 52
        cube[1;;]
            41 26 38 14
            87 52 30 28
            19 65 40 55
        cube[;1;]
            41 26 38 14
            19 31 64 45
        cube[;;1]
            41 87 19
            19 82 38
        cube[1;1;]
            41 26 38 14
        cube[1;;1]
            41 87 19
        cube[;1;1]
            41 19

    To review
    ---------
    matrix~indexer(1,1,1)= -- Not enough subscripts for array; 2 expected
    The error message is surprising : 3 indices and complains "not enough"
    This is because the list of arguments is interpreted as a list of 3 indexes made of 1 indice each.
    */
    if arg() <> 1 then return self~indexer(arg(1, "a"))
    use arg index
    if \index~isa(.array) then index=v(index)

    -- The shape of the result is the same as the shape of the index.
    -- The depth of the result is always 1, would be too complicated to manage at the same time nested indexes and indexes as array.
    -- Ex :
    --     v( v(1), v(2) ) can be used with a vector : shape [2], depth 2. The indexes have 1 indice, the result is shape [2], depth 1.
    --     v( v(1,2), v(3,4) ) can be used with a matrix : shape [2], depth 2. The indexes have 2 indices, the result is shape [2], depth 1.
    return index~leftElementWise({itemRight~atIndex(itemLeft)}, self~enclose, 1)

/*
    args = arg(1, "a")
    if args~depth == 1 then return self~indexer(v(args)) -- one index, maybe with omitted indices
    return self~indexer(arg(1, "a")) -- for convenience, indexer(i1,i2,...iN) equivalent to indexer(v(i1,i2,...iN))

vector~indexer()=           Not enough arguments for method; 1 expected     ok
vector~indexer(1)=          41                                              ok
vector~indexer(1,1)=        Too many subscripts for array; 1 expected       ok
vector~indexer(1,)=         [41]                                            should raise error too many subscripts
vector~indexer(v())=        []                                              ok
vector~indexer(v(1))=       41                                              expected [41]
vector~indexer(v(1,1))=     [41,41]                                         ok
vector~indexer(v(1,))=      [41,...]                                        should raise error too many subscripts


matrix~indexer()=           Not enough arguments for method; 1 expected     ok
matrix~indexer(1)=          Not enough arguments for method; 1 expected     ok
matrix~indexer(1,1)=        [41]                                            expected 41
matrix~indexer(1,1,1)=      Too many subscripts for array; 2 expected       ok
matrix~indexer(v())=        []                                              ok
matrix~indexer(v(1))=       Not enough subscripts for array; 2 expected     ok
matrix~indexer(v(1,1))=     41                                              expected [41]. [later] no ! should return a vector of 2 values but the indexes don't have enough subscripts
matrix~indexer(v(1,))=      Not enough subscripts for array; 2 expected     ok, to extend. [later] no ! attempts to return a vector of 1 value and 1 omitted
matrix~indexer(v(1,1,1))=   Not enough subscripts for array; 2 expected     surprising ? no ! attempts to return a vector of 3 values
matrix~indexer(v(1,1,))=    Not enough subscripts for array; 2 expected     surprising ? no ! attempts to return a vector of 2 values and 1 omitted


    args = arg(1, "a")
    --if args~depth == 1 then return self~indexer(v(args)) -- one index, maybe with omitted indices
    return self~indexer(arg(1, "a")) -- for convenience, indexer(i1,i2,...iN) equivalent to indexer(v(i1,i2,...iN))

vector~indexer()=           []
vector~indexer(1)=          41
vector~indexer(1,1)=        [41,41]
vector~indexer(1,)=         [41,...]
vector~indexer()=           []
*/

/*
    An index is an indice (whole number), or a vector of indices.
    An index can be sparse: an omitted indice lets select all the items in the corresponding dimension.
    Zero parameter:
        all indices are omitted, returns a copy of the whole array (copy because in all other cases, the result is new array).
    One parameter:
        if type whole number: indice
            if array rank <=1 (vector) then return the corresponding item (can be .nil if no item).
                vector~indexer(1)
                vector[1] or 1 ⌷ vector
                    41 (scalar: rank = 0)
            otherwise return the corresponding sub-array (indice in 1st dimension is provided, indices in next dimensions are omitted).
                matrix~indexer(1)
                1 ⌷ matrix
                    41 26 38
        if type array: array of indexes, can have any shape, the result will have the same shape.
            vector~indexer(v(1))
            vector[1 ⍴ 1]
                41 (vector: rank = 1)
            vector~indexer(v(1,2,3))
            vector[1 2 3]
                41 26 38
            matrix~indexer(v(index(1,1)))
            APL ? matrix[(1 1)] rank error, why ?
                41
            matrix~indexer(v(index(1,1), index(1,2)))
            matrix[(1 1)(1 2)]
                41 26
            matrix~indexer(v(1)) or matrix~indexer(v(1,))
            matrix[1;])
                41 26 38
            matrix~indexer(v(1,2,3))
            APL ? (matrix[1;]) (matrix[2;]) (matrix[3;])
                41 26 38  14 87 52  30 28 19 (shape [1,3])

        otherwise: unsupported index
    More than one parameter: each parameter is an indice or a vector of indices (not an index). An indice can be omitted.
        matrix~indexer(1,1)
        matrix[1;1]
            41      rank 0
        matrix~indexer(1,)
        matrix[1;]
            41 26 38
        matrix~indexer(v(1,1),1)
        matrix[1 1;1] or (1 1) 1 ⌷ matrix
            41 41   rank 1
        matrix~indexer(v(1,1),v(1,1)]
        matrix[1 1;1 1] or (1 1) (1 1) ⌷ matrix
            41 41   rank 2
            41 41

*/


/******************************************************************************/
::class "EnclosedArray" public inherit ArrayOperators ArrayPrettyPrinter -- remember : don't declare it subclass of Array !

/*
How to create a self-referencing enclosed array:
a=(1,2)                         -- [1,2]
b=a                             -- [1,2]
a~append(b)                     -- [1,2,*0]                         -- self reference to array
b=a~enclose                     -- <[1,2,*0]>
a~append(b)                     -- [1,2,*0,<*1>]                    -- enclosed self reference to array
c = .EnclosedArray~new(.nil)    -- <(The NIL object)>
d = c~enclose~enclose           -- <<<(The NIL object)>>>
c~setEnclosed(d)                -- <<<*2>>>                         -- enclosed self reference to enclosed array
a~append(c)                     -- [1,2,*0,<*1>,<<<*2>>>]
b=a~enclose~enclose             -- <<[1,2,*0,<*1>,<<<*2>>>]>>
a~append(b)                     -- [1,2,*0,<*1>,<<<*2>>>,<<*2>>]
b=                              -- <<[1,2,*0,<*1>,<<<*2>>>,*2]>>
*/

::method init
    expose object
    use strict arg object


::method setEnclosed
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

        .array~new(2,3)~of(1,,3,,5,)
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
    use arg ... -- optional 0..n arguments

    if self~dimension == 0 then raise syntax 93.900 array("Array with no dimension")

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
                                       else index = selfArrayIndex~copy -- to avoid any side effect from the doer
                if arity >= 2 then doer~do(selfIntegerIndex, index)
                else if arity == 1 then doer~do(selfIntegerIndex)
                else doer~do
                if var("result") then self~put(result, selfArrayIndex)
                -- Needed to offer the same behaviour for
                --     .array~new(2,3)~of(1~upto(5))
                --     .array~new(2,3)~of(1~generate.upto(5))
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


::method deltaIndexes
    use strict arg index1, index2
    dimension = self~dimension
    dimensions = self~dimensions
    delta = 0
    p = 1 -- Ex: for shape [2,3,4] the successive values of p are 1, 1*4, 1*4*3. It's the equivalent of 1, 1*10, 1*10*10 when you write a number in base 10.
    do i = dimension to 1 by -1
        delta += (index2[i] - index1[i]) * p
        p *= dimensions[i]
    end
    return delta


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
        --if .nil <> level then return "*"level-1
        if .nil <> level then return "*a"level -- pointer to the array already displayed
        stack~append(val)
        level = stack~index(val)
        valstr = "a" || level || "=" || "<"val~ppRepresentation(maxItems, sparse, ellipsis, separator, val~disclose, stack)">"
        --stack~pull
        return valstr
    end
    else if val~isA(.array), val~dimension == 1 then do
        level = stack~index(val)
        --if .nil <> level then return "*"level-1
        if .nil <> level then return "*a"level -- pointer to the array already displayed
        stack~append(val)
        level = stack~index(val)
        -- each item of the array is inserted.
        items = 0 -- Not global. Each item being an array will have maxItems items inserted.
                  -- Maybe a global count could be useful... Will see on usage.
        valstr = "a" || level || "=" || "["
        sep = ""
        if maxItems >= 0 then s = val~supplier(maxItems+1) -- +1 to let display the ellipsis
        else s = val~supplier
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
        if maxItems >= 0, items >= maxItems then nop -- truncated, ellipsis already added, don't add sparse
        else do -- if not truncated
            if i <= val~size then do
                valstr ||= sep || sparse
            end
        end
        valstr ||= "]"
        --stack~pull
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
            if val~isA(.array) then valstr = "("valstr shape(val, ", ") || val~items "items)"
            else valstr = "("valstr")"
        end
        return valstr
    end


/******************************************************************************/
::class "ArrayOperators" mixinclass Object public

::attribute defaultSparseValue

::method leftElementWise
    /*
    A copy of all nested arrays is done. The self-references are adjusted.
    The argument 'depth' lets control how many levels are impacted by the calculation.
    level1 = (11,12)
    level2 = (21,22)
    level3 = (31,32)
    level5 = (51,52)
    level5e = level5~enclose
    level1~append(level2)
    level2~append(level3)
    level2~append(level5e)
    level2~append(level1)               -- self reference
    level3~append(level5e)              -- indirect self reference part1
    level5~append(level3)               -- indirect self reference part2.
    a = level1                          -- [11,12,[21,22,[31,32,<[51,52,*2]>],<[51,52,[31,32,*2]]>,*1]]
    -a=                                 -- [-11,-12,[-21,-22,[-31,-32,<[-51,-52,*2]>],<[-51,-52,[-31,-32,*2]]>,*1]]
    a~leftElementWise("-",,0)=          -- [11,12,[21,22,[31,32,<[51,52,*2]>],<[51,52,[31,32,*2]]>,*1]]
    a~leftElementWise("-",,1)=          -- [-11,-12,[21,22,[31,32,<[51,52,*2]>],<[51,52,[31,32,*2]]>,*1]]
    a~leftElementWise("-",,2)=          -- [-11,-12,[-21,-22,[31,32,<[51,52,*2]>],<[51,52,[31,32,*2]]>,*1]]
    a~leftElementWise("-",,3)=          -- [-11,-12,[-21,-22,[-31,-32,<[51,52,*2]>],<[51,52,[-31,-32,*2]]>,*1]
    a~leftElementWise("-",,4)=          -- [-11,-12,[-21,-22,[-31,-32,<[51,52,*2]>],<[51,52,[-31,-32,*2]]>,*1]]
    a~leftElementWise("-",,5)=          -- [-11,-12,[-21,-22,[-31,-32,<[-51,-52,*2]>],<[-51,-52,[-31,-32,*2]]>,*1]]

    Remember:
    The stack is used to manage the mapping between the nested arrays and their copy.
    It's possible to have self references that are not only vertical (between an item and a nested item inside this item),
    but also horizontal (between 2 items that have no common root)
    This is the case for the self reference created by level4~append(level3).
    To adjust correctly this self reference, must not remove the mappings from the stack when returning from a recursive call.
    */
    use strict arg action, rightArg=.nil, depth=(.infinity~positive), stack=(.identityTable~new)
    counterpart = stack[self]
    if counterpart <> .nil then return counterpart -- stop infinite recursion
    if \ arg(2, "e") then do
        -- unary operator (op self):
        --   op Array
        --   op EnclosedArray

        if action~hasMethod("functionDoer") then doer = action~functionDoer("use arg item, index, depth")~arity(3)
                                            else doer = action~doer
        arity = doer~arity

        if self~isA(.EnclosedArray) then do
            er = .EnclosedArray~new(.nil)
            stack[self] = er -- in case of self reference, will be used to build the new self reference
            arg = self~disclose
            r = arg~leftElementWise(doer, , depth-1, stack)
            stack~remove(self)
            er~setEnclosed(r)
            return er
        end
        -- Here, self is an array
        r = .array~new(self~dimensions)
        stack[self] = r -- in case of self reference, will be used to build the new self reference
        supplier = self~supplier
        do while supplier~available
            index = supplier~index
            item = supplier~item
            if item~isA(.array) | item~isA(.EnclosedArray) then do
                r[index] = item~leftElementWise(doer, , depth-1, stack)
            end
            else if depth <= 0 then do
                r[index] = item
            end
            else do
                if arity >= 3 then doer~do(item, index, depth)
                              else doer~do(item)
                if var("result") then r[index] = result
            end
            supplier~next
        end
        stack~remove(self)
        return r
    end

    -- binary operator (self op rightArg):
    --   Array op Array : element wise
    --   Array op EnclosedArray : manage enclosedArray as a whole
    --   Array op Other
    --   EnclosedArray op Array : return rightArg~rightElementWise(doer, self)
    --   EnclosedArray op EnclosedArray : error
    --   EnclosedArray op Other : manage enclosedArray as a non enclosed array

    if action~hasMethod("functionDoer") then doer = action~functionDoer("use arg itemLeft, itemRight, indexLeft, indexRight, depth")~arity(5)
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
            return rightArg~rightElementWise(doer, self, depth, stack)
        end
    end

    -- not enclosed array on left
    -- or enclosed array on left and not array on right: in this case, the enclosed array is handled as a not enclosed array

    if rightArg~isA(.array) then do
        -- binary operator with not enclosed array on left & right : Array op Array
        if \sameShapes(self, rightArg) then raise syntax 93.900 array("Shapes are not equal")
        r = .array~new(self~dimensions)
        stack[self] = r -- in case of self reference, will be used to build the new self reference
        supplier = self~supplier
        -- TODO : sparse array not supported. Must use TWO suppliers.
        do while supplier~available
            index = supplier~index
            item = supplier~item
            if item~isA(.array) | item~isA(.EnclosedArray) then do
                r[index] = item~leftElementWise(doer, rightArg[index], depth-1, stack)
            end
            else if depth <= 0 then do
                r[index] = item
            end
            else do
                if arity >= 5 then doer~do(item, rightArg[index], index, index, depth)
                              else doer~do(item, rightArg[index])
                if var("result") then r[index] = result
            end
            supplier~next
        end
        stack~remove(self)
        return r
    end
    else do
        -- Remaining cases:
        -- Array op EnclosedArray
        -- Array op Other
        -- EnclosedArray op Other
        if self~isA(.EnclosedArray) then do
            er = .EnclosedArray~new(.nil)
            stack[self] = er -- in case of self reference, will be used to build the new self reference
            leftArg = self~disclose
            r = leftArg~leftElementWise(doer, rightArg, depth-1, stack)
            stack~remove(self)
            er~setEnclosed(r)
            return er
        end
        -- Here, self is an array
        r = .array~new(self~dimensions)
        stack[self] = r -- in case of self reference, will be used to build the new self reference
        supplier = self~supplier
        do while supplier~available
            index = supplier~index
            item = supplier~item
            if item~isA(.array) | item~isA(.EnclosedArray) then do
                r[index] = item~leftElementWise(doer, rightArg, depth-1, stack)
            end
            else if depth <= 0 then do
                r[index] = item
            end
            else do
                if arity >= 5 then doer~do(item, rightArg, index, index, depth)
                              else doer~do(item, rightArg)
                if var("result") then r[index] = result
            end
            supplier~next
        end
        stack~remove(self)
        return r
    end

::method "rightElementWise"
    -- no unary operator here.
    -- Array op Array :                 delegate to leftElementWise
    -- Array op EnclosedArray :         delegate to leftElementWise
    -- Array op Other :                 can't happen (right is either Array or EnclosedArray)
    -- EnclosedArray op Array :         specific implementation
    -- EnclosedArray op EnclosedArray : error
    -- EnclosedArray op Other :         can't happen (right is either Array or EnclosedArray)
    -- Other op Array :                 specific implementation
    -- Other op EnclosedArray :         specific implementation
    -- Other op Other :                 can't happen (right is either Array or EnclosedArray)

    use strict arg action, leftArg, depth=(.infinity~positive), stack=(.identityTable~new)
    counterpart = stack[self]
    if counterpart <> .nil then return counterpart -- stop infinite recursion

    if action~hasMethod("functionDoer") then doer = action~functionDoer("use arg itemLeft, itemRight, indexLeft, indexRight, depth")~arity(5)
                                        else doer = action~doer
    arity = doer~arity

    if leftArg~isA(.array) then return leftArg~leftElementWise(doer, self, depth, stack)

    if leftArg~isA(.EnclosedArray), self~isA(.EnclosedArray) then do
        -- binary operator with enclosed array on left & right : EnclosedArray op EnclosedArray
        raise syntax 93.900 array("Element-wise operation does not support two enclosed arrays")
    end

    -- Remaining cases:
    -- EnclosedArray op Array : enclosedArray managed as a whole
    -- Other op Array :         specific implementation
    -- Other op EnclosedArray : disclose the enclosed array

    if self~isA(.EnclosedArray) then do
        er = .EnclosedArray~new(.nil)
        stack[self] = er -- in case of self reference, will be used to build the new self reference
        rightArg = self~disclose
        r = rightArg~rightElementWise(doer, leftArg, depth-1, stack)
        stack~remove(self)
        er~setEnclosed(r)
        return er
    end
    -- Here, self is an array
    rightArg = self
    r = .array~new(rightArg~dimensions)
    stack[rightArg] = r -- will be used to build the resulting infinite array
    supplier = rightArg~supplier
    do while supplier~available
        index = supplier~index
        item = supplier~item
        if item~isA(.array) | item~isA(.EnclosedArray) then do
            r[index] = item~rightElementWise(doer, leftArg, depth-1, stack)
        end
        else if depth <= 0 then do
            r[index] = item
        end
        else do
            if arity >= 5 then doer~do(leftArg, item, index, index, depth)
                          else doer~do(leftArg, item)
            if var("result") then r[index] = result
        end
        supplier~next
    end
    stack~remove(rightArg)
    return r

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
