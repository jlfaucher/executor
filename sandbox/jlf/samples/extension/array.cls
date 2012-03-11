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
The index of the current cell is passed as argument to the doer.
The value returned by the doer is the item for the current cell.
    .array~new(2,3)~of{10*arg(1)}
    10 20 30
    40 50 60

Otherwise each argument is an item as-is.
    .array~new(2,3)~of(1,2,3,4,5,6)
    1 2 3
    4 5 6

The items are a list of values that must be assigned to the cells of the array.
Rules inspired by APL :
If there are too many items, the extra items are ignored.
If there are fewer items than implied by the dimensions, the list of items is reused as 
many times as necessary to fill the array.
    .array~new(2,3)~of(1)
    1 1 1
    1 1 1
*/

::method of
    if arg() == 0 then args = .array~of(.nil)
    else if arg() == 1, arg(1)~isA(.String) then args = arg(1)~subwords
    else args = arg(1, "a")
    argsCount = args~items
    
    dim = self~dimension
    if dim == 0 then dim = 1 -- assumes it's a vector
    index = dim~times{1} -- Initializes all indexes at 1

    -- to continue...


-- The shape of an array is an array which gives the size of each dimension.
::method shape
    shape = .array~new(self~dimension)
    do i=1 to self~dimension
        shape[i] = self~dimension(i)
    end
    return shape


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
    use strict arg separator=",", val=(self), stack=(.queue~new) 
    if val~isA(.array) then do
        level = stack~index(val)
        if level <> .nil then return "*"level-1
        stack~push(val)
        -- each item of the array is inserted.
        valstr = "["
        sep = ""
        do v over val
            valstr ||= sep || self~ppRepresentation(separator, v, stack)
            sep = separator
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

