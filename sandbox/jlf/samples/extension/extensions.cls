/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

::requires "extension/doers.cls"
::requires "extension/functionals.cls"
::requires "concurrency/coactivity.cls"
::requires "extension/array.cls"

::extension String inherit StringDoer StringReducer StringMapper StringRepeater StringIterator
::extension MutableBuffer inherit MutableBufferReducer MutableBufferMapper MutableBufferIterator
::extension Routine inherit RoutineDoer
::extension Method inherit MethodDoer
::extension Coactivity inherit CoactivityDoer CoactivityReducer CoactivityIterator
::extension RexxContextualSource inherit RexxContextualSourceDoer
::extension Collection inherit CollectionReducer CollectionMapper CollectionIterator
::extension Supplier inherit SupplierReducer SupplierIterator
::extension Array inherit ArrayInitializer
