/*
This script needs a modified ooRexx interpreter which allows to extend predefined ooRexx classes.
*/

::requires "doers.cls"
::requires "functionals.cls"

::extension String inherit StringDoer StringReduce StringMap StringRepeater
::extension MutableBuffer inherit MutableBufferMap
::extension Routine inherit RoutineDoer
::extension Method inherit MethodDoer
::extension Collection inherit CollectionReduce
::extension OrderedCollection inherit OrderedCollectionMap

