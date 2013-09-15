/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

::requires "extension/array.cls"
::requires "extension/complex.cls"
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
::extension String                          inherit StringDoer     StringFilter                          StringIterator                          StringReducer        StringGenerator        StringMapper        StringHelpers RepeaterCollector RepeaterGenerator LogicalExtension 
::extension MutableBuffer                   inherit                MutableBufferFilter                   MutableBufferIterator                   MutableBufferReducer MutableBufferGenerator MutableBufferMapper StringHelpers
::extension Collection                      inherit                CollectionFilter                      CollectionIterator                      CollectionReducer    CollectionGenerator    CollectionMapper
::extension OrderedCollection               inherit                OrderedCollectionFilter
::extension Supplier                        inherit                SupplierFilter                        SupplierIterator                        SupplierReducer      SupplierGenerator
::extension CoactivitySupplierForGeneration inherit                CoactivitySupplierForGenerationFilter CoactivitySupplierForGenerationIterator
::extension Array                           inherit ArrayInitializer ArrayPrettyPrinter
::extension File                            inherit FileExtension


-------------------------------------------------------------------------------
-- Can't inherit from a mixinclass (would raise "cannot inherit from itself")
::extension Object

-- Display and return the comment stored in the source of the method _description_, if any.
::method help class
    use strict arg display=.true, self=(self)
    if self~hasMethod("_description_") then do
        description = self~instanceMethod("_description_")
        if description <> .nil then do
            source = description~source -- an array
            items = source~items
            if items > 4 then do
                -- by necessity, the comment must have an instruction before and after, to be kept in the source (bug ?)
                -- by convention, a description is like that :
                -- nop
                -- /*
                -- description (several lines)
                -- */
                -- nop
                source = source~section(3, items - 4)
            end
            if display then say source~toString
            return source
        end
    end
    if display then say "no help"
    return .array~new

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

