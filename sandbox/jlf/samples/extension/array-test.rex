/********************************************************************
Array initializers
********************************************************************/

-- If there is only one argument, and this argument is a string, then each word of the string is an item (APL-like).
call dump2      .array~new(2,3)~of(1 2 3 4 5 6)
-- 1 2 3
-- 4 5 6

-- If there is only one argument, and this argument has the method ~supplier then each item returned by the argument's supplier is an item.
call dump2      .array~new(2,3)~of(1~upto(6))
-- 1 2 3
-- 4 5 6

-- If there is only one argument, and this argument is a doer, then the doer is called for each cell to initialize.
call dump2      .array~new(2,3)~of{10*integerIndex}
-- 10 20 30
-- 40 50 60

-- Otherwise, when more than one argument, each argument is an item as-is.
call dump2      .array~new(2,3)~of(1,2,3,4,5,6)
-- 1 2 3
-- 4 5 6

-- If some arguments are omitted, then the corresponding item in the initialized arrat remains non-assigned.
call dump2      .array~new(2,3)~of(1,,3,,5,6)
-- 1 . 3
-- . 5 6

-- For me, there is a problem (bug ?) when the last arguments are explicitely omitted : they are not counted by the interpreter !
call dump2      .array~new(2,3)~of(1,,3,,5,)
-- 1 . 3
-- . 5 1
-- I was expecting this result, because I passed explicitely 6 arguments, 3 of them being omitted :
-- 1 . 3
-- . 5 .

-- Rules inspired by APL :
-- If there are too many items, the extra items are ignored.
-- If there are fewer items than implied by the dimensions, the list of items is reused as many times as necessary to fill the array.
call dump2      .array~new(2,3)~of(1,2)
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

/********************************************************************
Array operators
********************************************************************/

-- By default, the operator overriding is not activated, because it has a cost.
-- The goal is to keep the optimization for the predefined class String.
-- You decide where you want to activate the operator overriding.
-- We need it here.
options "OPERATOR_OVERRIDING_BY_ROUTINE"

call dump2      1 + .array~of(10,20,30) + .complex[5,6]
call dump2      1 - .array~of(10,20,30)

call dump2      1 + .array~new(2,3)~of(10,11,12)
call dump2      1 - .array~new(2,3)~of(10,11,12)

ts1day = .TimeSpan~fromDays(1)
ts1hour = .TimeSpan~fromHours(1)
ts1minute = .TimeSpan~fromMinutes(1)
ts1second = .TimeSpan~fromSeconds(1)
ts1microsecond = .TimeSpan~fromMicroseconds(1)
today = .DateTime~today

call dump2      .array~of(ts1microsecond, ts1second, ts1minute, ts1hour, ts1day) + today
call dump2      today + .array~of(ts1microsecond, ts1second, ts1minute, ts1hour, ts1day)

-- Operator overriding has a cost on performances...
-- When activated, each usage of operator will trigger the multi-implementation behavior :
-- Search strategy :
-- Search in the call stack the older frame whose package requires some other packages.
-- This is the root package for the search. Follow the order of requires from this root
-- package, and collect all the implementations of the operator.
-- Execution strategy :
-- Iteration over the collected implementations and call them one by one, until one of them
-- returns a result. This result is the result of the evaluation of the operator.
-- If no result at all, then fallback to the normal evaluation of the operator.

call time('r')
do 10000
    var = 1+2
end
say "duration1="time('e')~format(2,4)

options "NOOPERATOR_OVERRIDING_BY_ROUTINE"

call time('r')
do 10000
    var = 1+2
end
say "duration2="time('e')~format(2,4)

::requires "extension/extensions.cls"
::requires "pipeline/pipe_extension.cls"
::requires "rgf_util2/rgf_util2_wrappers.rex"

