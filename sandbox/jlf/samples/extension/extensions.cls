/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

::requires "extension/doers.cls"
::requires "extension/functionals.cls"
::requires "concurrency/coactivity.cls"
::requires "extension/array.cls"

::extension String inherit StringDoer StringReduce StringMap StringRepeater
::extension MutableBuffer inherit MutableBufferMap
::extension Routine inherit RoutineDoer
::extension Method inherit MethodDoer
::extension Coactivity inherit CoactivityDoer CoactivityReduce CoactivityIterator
::extension RexxContextualSource inherit RexxContextualSourceDoer
::extension Collection inherit CollectionReduce CollectionIterator
::extension OrderedCollection inherit OrderedCollectionMap
::extension Supplier inherit SupplierReduce SupplierIterator
::extension Array inherit ArrayInitializer
