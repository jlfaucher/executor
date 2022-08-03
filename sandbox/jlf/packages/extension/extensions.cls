/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

::requires "concurrency/coactivity.cls"
::requires "concurrency/generator.cls"
::requires "extension/array.cls"
::requires "extension/collection.cls"
::requires "extension/complex.cls"
::requires "extension/doers.cls"
::requires "extension/file.cls"
::requires "extension/indeterminate.cls"
::requires "extension/infinity.cls"
::requires "extension/string.cls"
::requires "extension/text.cls"
::requires "extension/functionals.cls"
::requires "extension/logical.cls"
::requires "extension/rexxinfo.cls"


-- Doer
::extension Routine                         inherit RoutineDoer
::extension Method                          inherit MethodDoer
::extension RexxBlock                       inherit RexxBlockDoer
::extension Coactivity                      inherit CoactivityDoer
::extension String                          inherit StringDoer

-- Initializer
::extension MapCollection                   inherit MapCollectionInitializer
::extension Array                           inherit ArrayInitializer

-- Pretty printer
::extension Array                           inherit ArrayPrettyPrinter
::extension Collection                      inherit CollectionPrettyPrinter

-- Filter
::extension Collection                      inherit CollectionFilter
::extension OrderedCollection               inherit OrderedCollectionFilter
::extension Coactivity                      inherit CoactivityFilter
::extension Supplier                        inherit SupplierFilter
::extension CoactivitySupplierForGeneration inherit CoactivitySupplierForGenerationFilter
::extension String                          inherit StringFilter
::extension MutableBuffer                   inherit MutableBufferFilter

-- Iterator
::extension Collection                      inherit CollectionIterator
::extension Coactivity                      inherit CoactivityIterator
::extension Supplier                        inherit SupplierIterator
::extension CoactivitySupplierForGeneration inherit CoactivitySupplierForGenerationIterator
::extension String                          inherit StringIterator
::extension MutableBuffer                   inherit MutableBufferIterator

-- Reducer
::extension Collection                      inherit CollectionReducer
::extension Coactivity                      inherit CoactivityReducer
::extension Supplier                        inherit SupplierReducer
::extension String                          inherit StringReducer
::extension MutableBuffer                   inherit MutableBufferReducer

-- Generator
::extension Collection                      inherit CollectionGenerator
::extension Coactivity                      inherit CoactivityGenerator
::extension Supplier                        inherit SupplierGenerator
::extension String                          inherit StringGenerator
::extension MutableBuffer                   inherit MutableBufferGenerator

-- Mapper
::extension Collection                      inherit CollectionMapper
::extension String                          inherit StringMapper
::extension MutableBuffer                   inherit MutableBufferMapper

-- String specific
::extension String                          inherit RepeaterCollector -
                                                    RepeaterGenerator -
                                                    LogicalExtension  -
                                                    ComplexString

-- Array specific
::extension Array                           inherit ArrayOperators -
                                                    APLArray

-- File specific
::extension File                            inherit FileExtension


-------------------------------------------------------------------------------
::class "PrettyPrinter" public
::constant expandCollection 10 -- expand collections (other than array) having ~items <= this constant


-------------------------------------------------------------------------------
-- Object can't inherit from a mixinclass (would raise "cannot inherit from itself")
::extension Object

------------------------------
-- Compatibility with ooRexx 5
------------------------------

::method isNil
    return .nil == self


------------
-- User data
------------

-- I wanted to define the class StringUserData, subclass of String, to let me
-- associate a user data to a string. But ooRexx < 5 has a bug:
-- The message "==" is sent with zero argument when requesting the hashcode of a string
-- (this is a documented behavior in the sources: RexxString::hash, RexxString::strictEqual)
-- and the implementation does not support the lack of argument when sent to a subclass of String.
-- Seems to be fixed in ooRexx 5.
-- In the meantime, I use this extension (applicable to any object, not just strings).

::method setUserData
    expose userData
    use strict arg userData

::method getUserData
    expose userData
    return userData

---------------
-- Pretty Print
---------------

::method ppString class
    -- To make a distinction between a real string and other objects, surround by (...)
    return "("self~string")"


::method ppString
    -- Will be redefined by subclasses like array, string, etc...
    -- To make a distinction between a real string and other objects, surround by (...)
    return "("self~string")"


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
