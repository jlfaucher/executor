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


::extension Object

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


::extension String

::method quoted
    use strict arg quote='"'
    return quote || self || quote

