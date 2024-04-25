/*
Some comments

Each level specializes the pretty-print.
Object
    String
    MutableBuffer
    Collection
        Array



Executor uses escape3, but you can keep and use escape2 in rgf_util2.
Your notation is better for a novice.

escape2("000102414243040506"x)      -- ["000102"x || "ABC" || "040506"x]
escape3("000102414243040506"x)      -- '[000102]ABC[040506]'




The management of ppOption is an experimentation to see how I can use a stem
to pass the options in cascade.
Not sure it's a good technique.
You can ignore ppOption, see the examples below.

Currently 2 options:
ppOptions.surroundByQuotes
ppOptions.expandCollection (not used, I remove it in the examples below)

with a special support for surroundByQuotes which can be passed as a positional
argument from rgf_util2

dump2(collection, ..., surroundItemByQuotes, surroundIndexByQuotes, ...)
call
    ppIndex2(s~index, surroundIndexByQuotes)
    call
        a1~ppString(surroundByQuotes)

    pp2(s~item, surroundItemByQuotes)
    call
        a1~ppString(surroundByQuotes)

I don't display the hash-codes, maybe you could add an option hashCode.



2 places in rgf_util2 where a routine ppString should be called:
pp2
ppIndex2

  if a1~hasMethod("ppString") then return a1~ppString(surroundByQuotes)
  return ppString(a1, surroundByQuotes)

*/


/******************************************************************************/
-- Possible implementation with routines (untested)
/******************************************************************************/

::routine ppString
    use strict arg object,  surroundByQuotes=.true

    if object~isA(.Array)               then return Array_ppString(object, surroundByQuotes)
    else if object~isA(.Collection)     then return Collection_ppString(object, surroundByQuotes)
    else if object~isA(.MutableBuffer)  then return MutableBuffer_ppString(object, surroundByQuotes)
    else if object~isA(.String)         then return String_ppString(object, surroundByQuotes)
    return Object_ppString(object, surroundByQuotes)


::routine Object_ppString
    use strict arg object, surroundByQuotes=.true
    -- To make a distinction between a real string and other objects, surround by (...)
    return "("object~string")"


::routine String_ppString
    use strict arg string, surroundByQuotes=.true
    -- strings are surrounded by quotes, except string numbers.
    if string~dataType("N") then do
        if string < 0 then return string -- the first character is the minus sign
        if string~matchChar(1, " +") then return string -- the first character is already a space or a plus
        return " "string               -- the first character is a space (could also display a plus sign)
    end
    pp = string
    if surroundByQuotes then pp = enquote2(pp, "'")
    return escape2(pp) -- Use 0xXX notation for escaped characters


::routine MutableBuffer_ppString
    use strict arg mutableBuffer, surroundByQuotes=.true
    -- Mutable buffers are prefixed with "M"
    pp = "M'"mutableBuffer~string"'"
    -- Use 0xXX notation for escaped character
    return escape2(pp)


::routine Collection_ppString
    use strict arg collection, surroundByQuotes=.true, expandCollection=10

    -- This option is not applicable to arrays, hence this location of the test.
    -- For the moment, I don't activate by default the display of items for the
    -- other collections because that gives long lists when displaying .environment
    -- from ooRexxShell.
    if expandCollection == 0 then return collection~objectName
    if collection~items > expandCollection then return collection~objectName

    -- todo ? add a parameter maxItems to ~allItems
    -- same logic in array~ppRepresentation
    if collection~isA(.OrderedCollection) then do
        return collection~class~id || Array_ppRepresentation(collection~allItems, surroundByQuotes, expandCollection)
    end
    else do
        return collection~class~id || Array_ppRepresentation(collection~allItems~sortWith(.StringNumericComparator~new))
    end


::routine Array_ppString
    use strict arg array, maxItems=(-1), sparse="..", ellipsis="...", separator=",", val=(array), referencesTable=.nil, counter=0, trace=.false

    /*
        not so easy...

        About this ugly code (not sure what I had in mind):
            use strict arg ..., counter=({n=0; {expose n; n+=1; n}}~())
            ...
            reference~id = counter~()

        It can (should, must) be replaced by
            use strict arg ..., counter=0
            ...
            counter += 1
            reference~id = counter

        The notation for self-referencing arrays is inspired by the notation of
        infinite trees in Prolog 2 (Colmerauer).
            https://www.prolog-heritage.org/en/ph20.html
            https://www.softwarepreservation.org/projects/prolog/marseille/doc/Colmerauer-InfTree-1982.pdf
        I tried very hard to find a practical use for it, but I couldn't.
        At least, the display doesn't produce a stack overflow...

    */













/******************************************************************************/
-- Executor implementation
/******************************************************************************/


::extension String          inherit StringPrettyPrinter
::extension MutableBuffer   inherit MutableBufferPrettyPrinter
::extension Collection      inherit CollectionPrettyPrinter
::extension Array           inherit ArrayPrettyPrinter


/******************************************************************************/
-- object.cls
/******************************************************************************/

-- Object can't inherit from a mixinclass (would raise "cannot inherit from itself")
::extension Object

::method ppString class
    -- To make a distinction between a real string and other objects, surround by (...)
    return "("self~string")"


::method ppString
    -- Will be redefined by subclasses like array, string, etc...
    -- To make a distinction between a real string and other objects, surround by (...)
    return "("self~string")"



/******************************************************************************/
-- string.cls
/******************************************************************************/

::class "StringPrettyPrinter" mixinclass Object public

::method ppString
    use arg surroundByQuotes=.true -- keep it for the moment, still needed from rgf_util2
    use named arg ppOptions. = (.Stem~new), ppOptions.surroundByQuotes = (surroundByQuotes)
    -- strings are surrounded by quotes, except string numbers.
    if self~dataType("N") then do
        if self < 0 then return self -- the first character is the minus sign
        if self~matchChar(1, " +") then return self -- the first character is already a space or a plus
        return " "self               -- the first character is a space (could also display a plus sign)
    end
    pp = self
    if ppOptions.surroundByQuotes then pp = pp~quoted("'")
    return escape3(pp) -- Use 0xXX notation for escaped characters


/******************************************************************************/
::class "MutableBufferPrettyPrinter" mixinclass Object public

::method ppString
    use arg surroundByQuotes=.true -- keep it for the moment, still needed from rgf_util2
    -- Mutable buffers are prefixed with "M"
    pp = "M'"self~string"'"
    -- Use 0xXX notation for escaped character
    return escape3(pp)


/******************************************************************************/
-- Copied from rgf_util2
-- Escape non-printable chars by printing them between square brackets [].
::routine escape3 public
  parse arg a1

  --non_printable=xrange("00"x,"1F"x)||"FF"x
  non_printable="00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F FF"x
  res=""

  do while a1\==""
     pos1=verify(a1, non_printable, "M")
     if pos1>0 then
     do
        pos2=verify(a1, non_printable, "N" , pos1)

        if pos2=0 then
           pos2=length(a1)+1

        if pos1=1 then
        do
           parse var a1 char +(pos2-pos1) a1
           bef=""
        end
        else
           parse var a1 bef +(pos1-1) char +(pos2-pos1) a1

        if res=="" then
        do
           if bef \=="" then res=bef -- res=enquote2(bef) '|| '
        end
        else
        do
           res=res||bef -- res=res '||' enquote2(bef) '|| '
        end

        res=res || '['char~c2x']'
     end
     else
     do
        if res<>""  then
           res=res||a1 -- res=res '||' enquote2(a1)
        else
           res=a1

        a1=""
     end
  end
  return res










/******************************************************************************/
-- collection.cls
/******************************************************************************/

/*
Remember:
In CoreClasses.orx, the class CircularQueue has a method string.
.CircularQueue~of(1,2,3)~string=     -- "1,2,3"

The method ppString defined at Object level delegates to string,
that's why I see (1,2,3) when pretty printing an array which contains
this CircularQueue.

The class Queue has no method string, and is displayed (a Queue)
by the method ppRepresentation.

I would like the same display for Queue and CircularQueue.
That's why I define the method ppString on the class Collection.
All the collections will benefit from this display.

See output of concurrency/generator-test.rex
*/


::class "CollectionPrettyPrinter" mixinclass Object public

::constant expandCollection 10 -- expand collections (other than array) having ~items <= this constant

::method ppString
    use named arg ppOptions. = (.Stem~new), ppOptions.expandCollection = (.CollectionPrettyPrinter~expandCollection)

    /*
       Workaround, the method ~ppString defined in array.cls is not called
       ((1,2,3),(4,5,6))== is display with "Array" in front of each line:
            an Array (shape [2], 2 items)
             1 : Array[ 1, 2, 3]
             2 : Array[ 4, 5, 6]
    */
    if self~isa(.array) then return self~ppRepresentation

    -- This option is not applicable to arrays, hence this location of the test.
    -- For the moment, I don't activate by default the display of items for the
    -- other collections because that gives long lists when displaying .environment
    -- from ooRexxShell.
    if ppOptions.expandCollection == 0 then return self~objectName
    if self~items > ppOptions.expandCollection then return self~objectName

    -- todo ? add a parameter maxItems to ~allItems
    -- same logic in array~ppRepresentation
    if self~isA(.OrderedCollection) then do
        return self~class~id || self~allItems~ppRepresentation(ppOptions. : ppOptions.)
    end
    else do
        return self~class~id || self~allItems~sortWith(.StringNumericComparator~new)~ppRepresentation(ppOptions. : ppOptions.)
    end










/******************************************************************************/
-- array.cls
/******************************************************************************/

::class "ArrayPrettyPrinter" mixinclass Object public

::method ppString
    use named arg ppOptions. = (.Stem~new)
    return self~ppRepresentation(ppOptions.: ppOptions.)


::method ppRepresentation
    /*
    Return a condensed string representation of the array.
    Ex :
    .array~of(1,"two", .array~of(1, "two", 3), .array~of(1, "two"))~ppRepresentation -- [ 1,'two',[ 1,'two', 3],[ 1,'two']]
    Recursive arrays are supported. A reference *R is inserted in the representation,
    where R is the reference of the part already displayed.
    Ex :
    a = .array~of("string1", "string2")
    b = .array~of("string2")
    b~append(a)
    a~append(b)
    a~append(a)

           +<------------------------------------+<--------+
           |                                     ^         ^
           V                                     |         |
        +---------+---------+-----+--+--+        |         |
     a1=| string1 | string2 |  .  |  .  |        |         |
        +---------+---------+--|--+--|--+        |         |
                               |     |           |         |
                               |     +---------->+         |    Reference array already displayed : *a1
                               V                           |
                           +---------+-----+               |
                           | string2 |  .  |               |
                           +---------+--|--+               |
                                        |                  |
                                        +----------------->+    Reference array already displayed : *a1

    say a~ppRepresentation
        a1=['string1','string2',['string2',*a1],*a1]

    a~pipe(.console "dataflow")
        source:1,'string1'
        source:2,'string2'
        source:3,a1=[v1='string2',a2=['string1',*v1,*a1,*a2]]
        source:4,a1=['string1',v1='string2',[*v1,*a1],*a1]

    a~pipe(.inject "iterateBefore" {item} "recursive.0.memorize" | .console "dataflow")
        source:1,v1='string1' | inject:1,*v1
        source:2,v1='string2' | inject:2,*v1
        source:3,a1=[v1='string2',a2=['string1',*v1,*a1,*a2]] | inject:1,*v1
        source:3,a1=[v1='string2',a2=['string1',*v1,*a1,*a2]] | inject:2,*a2
        source:4,a1=[v1='string1',v2='string2',[*v2,*a1],*a1] | inject:1,*v1
        source:4,a1=['string1',v1='string2',[*v1,*a1],*a1] | inject:2,*v1
        source:4,a1=['string1',v1='string2',a2=[*v1,*a1],*a1] | inject:3,*a2
        source:4,a1=['string1',v1='string2',[*v1,*a1],*a1] | inject:4,*a1
    */
    use strict arg maxItems=(-1), sparse="..", ellipsis="...", separator=",", val=(self), referencesTable=.nil, counter=({n=0; {expose n; n+=1; n}}~())
    use named arg trace=.false, ppOptions. = (.Stem~new), ppOptions.expandCollection=(.CollectionPrettyPrinter~expandCollection)
    if trace then .traceOutput~say("       >I> Method .ArrayPrettyPrinter~ppRepresentation")
    if trace then trace i
    -- Remember : this code has been duplicated in pipe.cls, routine dataflow_representation.
    if .nil == referencesTable then referencesTable = val~collectReferences(maxItems) -- do it before pretty printing, to display the reference identifiers only when needed
    if val~isA(.enclosedArray) then do
        -- Remember : would be better to have a method ppRepresentation on class EnclosedArray, but I prefer to remain close to dataflow_representation.
        reference = referencesTable[val]
        if reference~selfReference, reference~displayed then return "*e" || reference~id -- pointer to the enclosed array already displayed
        reference~displayed = .true
        valstr = ""
        if reference~selfReference then do
            reference~id = counter~() -- id assigned at first display, to have a natural progression
            valstr = "e" || reference~id || "="
        end
        return valstr || "<"val~ppRepresentation(maxItems, sparse, ellipsis, separator, val~disclose, referencesTable, counter, trace: trace)">"
    end
    else if val~isA(.array), val~dimension == 1 then do
        reference = referencesTable[val]
        if reference~selfReference, reference~displayed then return "*a" || reference~id -- pointer to the array already displayed
        reference~displayed = .true
        if reference~selfReference then do
            reference~id = counter~() -- id assigned at first display, to have a natural progression
            valstr = "a" || reference~id || "=" || "["
        end
        else valstr = "["
        -- each item of the array is inserted.
        items = 0 -- Not global. Each item being an array will have maxItems items inserted.
                  -- Maybe a global count could be useful... Will see on usage.
        sep = ""
        if maxItems >= 0 then s = val~supplier(maxItems+1) -- +1 to let display the ellipsis
        else s = val~supplier
        i = 1 -- current index, will let detect sparse sections
        do while s~available
            item = s~item
            index = s~index
            if maxItems >= 0, items >= maxItems then do
                valstr ||= sep || ellipsis
                leave
            end
            if i <> index then do
                valstr ||= sep || sparse
                sep = separator
            end
            valstr ||= sep || val~ppRepresentation(maxItems, sparse, ellipsis, separator, item, referencesTable, counter, trace: trace)
            sep = separator
            items += 1
            i = index + 1 -- next index
            s~next -- skip sparse section, if any
        end
        if maxItems >= 0, items >= maxItems then nop -- truncated, ellipsis already added, don't add sparse
        else do -- if not truncated
            if i <= val~size then do
                valstr ||= sep || sparse
            end
        end
        valstr ||= "]"
        return valstr
    end
    else if val~isA(.array) then do
        -- for the arrays with dimension <> 1, indicate their shape and item number
        valstr = val~string
        return "("valstr shape(val, ", ") || val~items "items)"
    end
    /*
    -- same logic in CollectionPrettyPrinter~ppstring, but here pass more parameters
    else if val~isA(.OrderedCollection) then do
        if ppOptions.expandCollection > 0, val~items <= ppOptions.expandCollection then do
            valAsArray = val~allItems
            return val~class~id || valAsArray~ppRepresentation(maxItems, sparse, ellipsis, separator, valAsArray, referencesTable, counter, trace: trace, ppOptions. : ppOptions.)
        end
        else do
            return val~string
        end
    end
    -- same logic in CollectionPrettyPrinter~ppstring, but here pass more parameters
    else if val~isA(.Collection) then do
        if ppOptions.expandCollection > 0, val~items <= ppOptions.expandCollection then do
            valAsArray = val~allItems~sortWith(.StringNumericComparator~new)
            return val~class~id || valAsArray~ppRepresentation(maxItems, sparse, ellipsis, separator, valAsArray, referencesTable, counter, trace: trace, ppOptions. : ppOptions.)
        end
        else do
            return val~string
        end
    end
    */
    else return val~ppString(ppOptions. : ppOptions.)


::method collectReferences private
    -- Collect all the references to array or enclosedArray.
    -- Same code organization as ppRepresentation, to make easier joint updates.
    -- Use the same logic as ppRepresentation to limit the number of items to analyze.
    -- When a referenced array is seen more than once, then the reference is marked as selfReference, to stop the infinite recursion.
    use strict arg maxItems=(-1), val=(self), referencesTable=(.identityTable~new)
    if val~isA(.enclosedArray) then do
        reference = referencesTable[val]
        if .nil <> reference then do
            reference~selfReference = .true
            return referencesTable
        end
        referencesTable[val] = .reference~new
        val~collectReferences(maxItems, val~disclose, referencesTable)
        return referencesTable
    end
    else if val~isA(.array), val~dimension == 1 then do
        reference = referencesTable[val]
        if .nil <> reference then do
            reference~selfReference = .true
            return referencesTable
        end
        referencesTable[val] = .reference~new
        -- each item of the array is analyzed.
        items = 0 -- Not global. Each item being an array will have maxItems items inserted.
                  -- Maybe a global count could be useful... Will see on usage.
        if maxItems >= 0 then s = val~supplier(maxItems+1) -- +1 to follow the logic of ppRepresentation
        else s = val~supplier
        do while s~available
            item = s~item
            index = s~index
            if maxItems >= 0, items >= maxItems then return referencesTable
            val~collectReferences(maxItems, item, referencesTable)
            items += 1
            s~next -- skip sparse section, if any
        end
        return referencesTable
    end
    return referencesTable


/******************************************************************************/

::class reference private

::attribute selfReference   -- indicator of self reference
::attribute id              -- unique identifier, used for display of references by ppRepresentation
::attribute displayed       -- will be set to .true by the pretty-printer when displaying the referenced for the first time

::method init
    self~selfReference = .false
    self~id = 0
    self~displayed = .false


