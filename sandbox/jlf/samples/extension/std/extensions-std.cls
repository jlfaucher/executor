/*
This script works with a standard ooRexx,
BUT
the instances of the extended classes defined here won't be accepted by 
the interpreter when an instance of a predefined class is expected. 
Same remark for enhanced instances.
*/

::requires "extension/std/doers-std.cls"
::requires "extension/std/functionals-std.cls"


::class ExtendedString subclass String public inherit StringDoer StringReduce StringMap StringRepeater
::class ExtendedMutableBuffer subclass MutableBuffer public inherit MutableBufferMap
::class ExtendedRoutine subclass Routine public inherit RoutineDoer
::class ExtendedMethod subclass Method public inherit MethodDoer

-- Here, you must extend each collection class that you wish to extend
::class ExtendedArray subclass Array public inherit CollectionReduce OrderedCollectionMap
::class ExtendedList subclass List public inherit CollectionReduce OrderedCollectionMap
::class ExtendedQueue subclass Queue public inherit CollectionReduce OrderedCollectionMap
::class ExtendedCircularQueue subclass CircularQueue public inherit CollectionReduce OrderedCollectionMap

