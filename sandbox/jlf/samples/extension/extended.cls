/*
This script works with a standard ooRexx, no need of ::extension here.
BUT
the extended classes defined here won't be accepted by the interpreter
when a predefined class is expected. Same remark for enhanced classes.
*/

::requires "doers.cls"
::requires "functionals.cls"


::class ExtendedString subclass String public inherit StringDoer StringReduce StringMap StringRepeater

::method methodFactory class
    -- When the ~doer method must create an instance of Method, use this extended class
    return .ExtendedMethod

::method routineFactory class
    -- When the ~doer method must create an instance of Routine, use this extended class
    return .ExtendedRoutine

::method mutableBufferFactory class
    -- When the ~mapchar or ~mapword method must create an instance of MutableBuffer, use this extended class
    return .ExtendedMutableBuffer

::method do
    -- ~sendWith doesn't accept a subclass of String : must convert my ExtendedString to a String
    use strict arg object, ...
    object~sendWith(self~string, arg(2,"a"))
    if var("result") then return result

::method doWith
    -- ~sendWith doesn't accept a subclass of String : must convert my ExtendedString to a String
    use strict arg object, array
    object~sendWith(self~string, array)
    if var("result") then return result

::method makeArray
    -- Must return an ExtendedArray. This is to let StringReduce~reduce work as expected
    array = .ExtendedArray~new(self~length)
    do i = 1 to self~length
        array~append(self~subchar(i))
    end
    return array
    
::class ExtendedMutableBuffer subclass MutableBuffer public inherit MutableBufferMap
::class ExtendedRoutine subclass Routine public inherit RoutineDoer
::class ExtendedMethod subclass Method public inherit MethodDoer

-- Here, you must extend each collection class that you wish to extend
::class ExtendedArray subclass Array public inherit CollectionReduce OrderedCollectionMap
::class ExtendedList subclass List public inherit CollectionReduce OrderedCollectionMap
::class ExtendedQueue subclass Queue public inherit CollectionReduce OrderedCollectionMap
::class ExtendedCircularQueue subclass CircularQueue public inherit CollectionReduce OrderedCollectionMap

