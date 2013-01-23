/*
Rustic benchmark 

Initially, a RangeGenerator was about 2000 times slower than a RangeIterator
(tested with release version of ooRexx sandbox, and using .Coactivity~yield instead of self~yield). 

If I replace .Coactivity~yield by self~yield, then
RangeGenerator is about 400 times slower than a RangeIterator.
    
If I use ooRexx trunk release instead of ooRexx sandbox release, then
RangeGenerator is about 13 times slower than a RangeIterator
(so the trace for SysSemaphore is very costly)
See std/coactivity-benchmark-std.rex

Todo : when building release version of ooRexx sandbox, don't include trace for SysSemaphore.
--> done.

Todo : optimize the access to activity's local variables (currently implemented in .Activity
using a dictionary of dictionary) because .Coactivity~yield depends on that to retrieve the
coactivity in the call stack.
--> done.
*/

showDuration = .false
max = 1000
do while max <= 1000000
    say
    say "loop" max
    
    call time('r')
    range = .RangeIteratorUnguarded~new(1, max)
    do while range~hasNext
        v = range~next
    end
    e1 = time('e')
    if showDuration then say "RangeIteratorUnguarded :" e1
    
    call time('r')
    range = .RangeIterator~new(1, max)
    do while range~hasNext
        v = range~next
    end
    e2 = time('e')
    if showDuration then say "RangeIterator :" e2
    
    call time('r')
    range = .RangeGenerator~new(1, max)
    range~resume
    do while var("result")
        v = result;
        range~resume
    end
    e3 = time('e')
    if showDuration then say "RangeGenerator :" e3
    
    if e2 <> 0 then say e3 / e2 "(generator vs iterator)"
    if e1 <> 0 then say e3 / e1 "(generator vs iterator ungarded)"
    if e1 <> 0 then say e2 / e1 "(iterator vs iterator unguarded)"
    
    max *= 10
end


::requires "extension/extensions.cls"
::requires "concurrency/coactivity.cls"

--------------------------------------------------------------------------------
-- A classic RangeIterator, to compare the performances with RangeGenerator...

::class RangeIterator public

::method init
    expose start end step value
    use strict arg start, end, step=1
    value = start
    self~init:super

::method hasNext
    expose end value
    return value <= end

::method next
    expose step value
    res = value
    value += step
    return res

    
--------------------------------------------------------------------------------
-- An unguarded RangeIterator, to compare the performances with RangeGenerator...

::class RangeIteratorUnguarded public

::method init unguarded
    expose start end step value
    use strict arg start, end, step=1
    value = start
    self~init:super

::method hasNext unguarded
    expose end value
    return value <= end

::method next unguarded
    expose step value
    res = value
    value += step
    return res


--------------------------------------------------------------------------------
-- A RangeGenerator, to compare the performances with a RangeIterator...

::class RangeGenerator inherit CoActivity

::method init
    expose start end step
    use strict arg start, end, step=1
    self~init:super
    
::method main
    expose start end step
    do i = start to end by step
        self~yield(i) -- .Coactivity~yield(i)
    end

