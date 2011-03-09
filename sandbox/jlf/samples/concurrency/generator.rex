-- This file is now deprecated.
-- See coactivity.cls

-- Generators in ooRexx

g1 = .RangeGenerator~new(10, 1, -2)
g1~generate
say g1~next
say g1~next
say g1~next
say g1~next
g1~stop

say
g2 = .RangeGenerator~new(1, 10)
g2~generate
do while g2~hasNext
    say g2~next
end
say g2~next

--::options trace i

--------------------------------------------------------------------------------
-- Helper class to implement user-defined generators
-- Could be a predefined ooRexx class, since no need to modify it for user-defined needs.
::class Generator
::constant valueIsRequested 1
::constant valueIsAvailable 2
::attribute valueStatus private
::attribute value private
::attribute isStopped private

::method init
    self~isStopped = .false
    self~value = .nil
    self~valueStatus = .generator~valueIsRequested

::method stop
    self~isStopped = .true
    
::method guardGenerate
    expose valueStatus isStopped
    guard on when valueStatus == .generator~valueIsRequested | isStopped

::method yield unguarded
    use strict arg value
    self~guardGenerate
    if self~isStopped then return
    self~value = value
    self~valueStatus = .generator~valueIsAvailable

::method generate
    self~stop -- default implementation : nothing generated

::method guardNext
    expose valueStatus isStopped
    guard on when valueStatus == .generator~valueIsAvailable | isStopped
    
::method next unguarded
    self~guardNext
    res = self~value
    self~value = .nil
    self~valueStatus = .generator~valueIsRequested
    return res
  
::method hasNext
    return \self~isStopped, -- while the generator is alive, new values can be (potentially) generated
           | self~valueStatus == .generator~valueIsAvailable -- the generator may be stopped, but the last generated value not yet consumed
    
    
--------------------------------------------------------------------------------
/*
An example of user-defined generator

::generator RangeGenerator
    use strict arg start, end, step=1
    do i = start to end by step
        yield i
    end
*/

::class RangeGenerator subclass Generator

::method init
    expose start end step
    use strict arg start, end, step=1
    self~init:super
    
::method generate
    expose start end step
    reply
    do i = start to end by step
        self~yield(i)
        if self~isStopped then return
    end
    self~stop -- no more values to generate

    
--------------------------------------------------------------------------------
/*
An example of user-defined generator.
In this example, FileIterator (which is the ooRexx equivalent of the C++ SysFileIterator) does not yet exists.
See :
interpreter\platform\windows\SysFileSystem.hpp
interpreter\platform\unix\SysFileSystem.hpp

::generator FileGenerator
    use strict arg pattern
    iterator = .FileIterator~new(pattern)
    do while iterator~hasNext
        yield iterator~next
    end
*/
::class FileGenerator subclass Generator

::method init
    expose pattern
    use strict arg pattern
    
::method generate
    expose pattern
    iterator = .FileIterator~new(pattern)
    do while iterator~hasNext
        self~yield(iterator~next)
        if self~isStopped then return
    end
    self~stop -- no more values to generate


