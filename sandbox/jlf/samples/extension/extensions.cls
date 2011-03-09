/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

::requires "extension/doers.cls"
::requires "extension/functionals.cls"

::extension String inherit StringDoer StringReduce StringMap StringRepeater
::extension MutableBuffer inherit MutableBufferMap
::extension Routine inherit RoutineDoer
::extension Method inherit MethodDoer
::extension Collection inherit CollectionReduce
::extension OrderedCollection inherit OrderedCollectionMap

