/********************************************************************
Array initializers
********************************************************************/

-- If there is only one argument, and this argument is a string, then each word of the string is an item (APL-like).
.array~new(2,3)~of(1 2 3 4 5 6)~dump2
-- 1 2 3
-- 4 5 6

-- If there is only one argument, and this argument has the method ~supplier then each item returned by the argument's supplier is an item.
.array~new(2,3)~of(1~upto(6))~dump2
-- 1 2 3
-- 4 5 6

-- If there is only one argument, and this argument is a doer, then the doer is called for each cell to initialize.
.array~new(2,3)~of{10*integerIndex}~dump2
-- 10 20 30
-- 40 50 60

-- Otherwise, when more than one argument, each argument is an item as-is.
.array~new(2,3)~of(1,2,3,4,5,6)~dump2
-- 1 2 3
-- 4 5 6

-- If some arguments are omitted, then the corresponding item in the initialized arrat remains non-assigned.
.array~new(2,3)~of(1,,3,,5,6)~dump2
-- 1 . 3
-- . 5 6

-- For me, there is a problem (bug ?) when the last arguments are explicitely omitted : they are not counted by the interpreter !
.array~new(2,3)~of(1,,3,,5,)~dump2
-- 1 . 3
-- . 5 1
-- I was expecting this result, because I passed explicitely 6 arguments, 3 of them being omitted :
-- 1 . 3
-- . 5 .

-- Rules inspired by APL :
-- If there are too many items, the extra items are ignored.
-- If there are fewer items than implied by the dimensions, the list of items is reused as many times as necessary to fill the array.
.array~new(2,3)~of(1,2)~dump2
-- 1 2 1
-- 2 1 2


/********************************************************************
Recursive arrays
********************************************************************/

separator = "-"~copies(50)

a = .array~of("string1","string2")
b = .array~of("string2")
b~append(a)
a~append(b)
a~append(a)

-- display the first two levels
s1 = a~supplier
do while s1~available
    call charout , s1~index ":" s1~item
    if s1~item~isA(.array) then call charout , " "s1~item~ppRepresentation
    say
    if s1~item~isA(.array) then do
        s2 = s1~item~supplier
        do while s2~available
            call charout , "    "s2~index ":" s2~item
            if s2~item~isA(.array) then call charout , " "s2~item~ppRepresentation
            say
            s2~next
        end
    end
    s1~next
end
say separator

say a~ppRepresentation
say separator

a~pipe(.console dataflow)
say separator

a~pipe(.inject iterateBefore {item} recursive.0.memorize | .console dataflow)
say separator


d = .array~of("d")
c = .array~of("c", d)
b = .array~of("b", c)
a = .array~of("a", b)
d~append(a)
say a~ppRepresentation
say separator

::requires "extension/extensions.cls"
::requires "pipeline/pipe_extension.cls"
::requires "rgf_util2/rgf_util2_wrappers.rex"

