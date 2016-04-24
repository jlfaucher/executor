/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

::requires "extension/array.cls"
::requires "extension/complex.cls"
::requires "extension/infinity.cls"
::requires "extension/file.cls"
::requires "extension/string.cls"
::requires "extension/doers.cls"
::requires "extension/functionals.cls"
::requires "extension/logical.cls"
::requires "concurrency/coactivity.cls"
::requires "concurrency/generator.cls"

::extension Routine                         inherit RoutineDoer
::extension Method                          inherit MethodDoer
::extension RexxBlock                       inherit RexxBlockDoer

::extension Coactivity                      inherit CoactivityDoer CoactivityFilter                      CoactivityIterator                      CoactivityReducer    CoactivityGenerator
::extension String                          inherit StringDoer     StringFilter                          StringIterator                          StringReducer        StringGenerator        StringMapper        StringHelpers RepeaterCollector RepeaterGenerator LogicalExtension EncodedString OperatorDispatcher ComplexString InfinityString
::extension MutableBuffer                   inherit                MutableBufferFilter                   MutableBufferIterator                   MutableBufferReducer MutableBufferGenerator MutableBufferMapper StringHelpers
::extension Collection                      inherit                CollectionFilter                      CollectionIterator                      CollectionReducer    CollectionGenerator    CollectionMapper
::extension OrderedCollection               inherit                OrderedCollectionFilter
::extension Supplier                        inherit                SupplierFilter                        SupplierIterator                        SupplierReducer      SupplierGenerator
::extension CoactivitySupplierForGeneration inherit                CoactivitySupplierForGenerationFilter CoactivitySupplierForGenerationIterator

::extension Array                           inherit ArrayInitializer ArrayPrettyPrinter ArrayOperators APLArray
::extension File                            inherit FileExtension


-------------------------------------------------------------------------------
-- Object can't inherit from a mixinclass (would raise "cannot inherit from itself")
::extension Object

------------
-- Generator
------------

::method generate class
    use strict arg action={item}
    return .Generator~new(self)~action(action)

::method generateI class
    use strict arg action={item}
    return .Generator~new(self)~action(action)~returnIndex

::method generate
    use strict arg action={item}
    return .Generator~new(self)~action(action)

::method generateI
    use strict arg action={item}
    return .Generator~new(self)~action(action)~returnIndex

----------
-- Unknown
----------

-- This method is needed to avoid a stack overflow when forwarding the message "unknown".
-- Ex:
-- The class RepeaterCollector defines an "unknown" method to support the form number~number.
-- If not applicable, then it forwards the message "unknown" to the class (super): here RepeaterGenerator.
-- If RepeaterGenerator has no "unknown" method then the interpreter recalls RepeaterCollector~unknown.
::method unknown unguarded
    use arg msg, args
    raise syntax 97.1 array(self, msg)
