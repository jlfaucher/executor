/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

--::options trace i

/******************************************************************************/
-- Should find a better name...
::class "StringHelpers" mixinclass Object public

::method quoted
    use strict arg quote='"'
    return quote || self~changeStr(quote, quote||quote)  || quote


::method unquoted
    use strict arg quote='"'
    if self~left(1) == quote & self~right(1) == quote then
        return self~substr(2, self~length - 2)~changeStr(quote||quote, quote)
    else
        return self


/******************************************************************************/
::requires "extension/complex.cls"
::requires "extension/infinity.cls"

::class "OperatorDispatcher" mixinclass Object public

::method "+op:left"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method "+op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method "-op:left"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method "-op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method "*op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method "/op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method "**op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method "=op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method "\=op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method "<>op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method "==op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method "\==op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method "><op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method ">op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method "<op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method ">=op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method "\<op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method "<=op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method "\>op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method ">>op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method "<<op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method ">>=op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method "\<<op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method "<<=op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method "\>>op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method "&op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method "|op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method "&&op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method "%op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)

::method "//op:right"
    forward continue class (.complexString)
    if var("result") then return result
    forward class (.infinityString)


/******************************************************************************/
::class "EncodedString" mixinclass Object public

::method text
    expose text -- attribute added on the String instance
    if \var("text") then do -- no stored counterpart
        if arg() <> 0 then do
            use strict arg aText
            if \aText~isA(.Text) then raise syntax 93.900 array("EncodeString: the counterpart must be a Text")
            text = aText -- store the Text counterpart passed by argument
        end
        else text = .Text~new(self) -- store the Text counterpart created from itself
    end
    else do
        -- A Text counterpart is already assigned.
        -- If a Text counterpart is passed by argument then raise an error if different from the current one
        if arg() <> 0 then do
            use strict arg aText
            if aText <> text then raise syntax 93.900 array("EncodedString: a Text counterpart is already assigned")
        end
    end
    return text


/******************************************************************************/
::class "Text" public

::method init
    expose string encodings
    use strict arg string -- store its String counterpart
    encodings = .Encodings~new
    string~text(self) -- store itself as counterpart of string


/*
Don't activate this one.
I need to get the control when concatenating strings
::method makestring
    expose string
    return string
*/


::method string
    expose string
    return string


::method encoding
    expose string encodings
    if arg() == 0 then return encodings -- query
    use strict arg encodingName, bfrom=1, blength=(string~length)
    encodings~declare(string, encodingName, bfrom, blength)
    return encodings


::method convert class
    use strict arg x
    if x~isA(self) then return x
    if x~isA(.string) then return x~text
    return .nil


::method " "
    use strict arg right
    right = self~class~convert(right)
    if .nil == right then return
    s = self~string right~string
    -- todo : merge encodings info
    return s~text


::method " op:right"
    use strict arg left
    left = self~class~convert(left)
    if .nil == left then return
    s = left~string self~string
    -- todo : merge encodings info
    return s~text


::method "||"
    use strict arg right
    right = self~class~convert(right)
    if .nil == right then return
    s = self~string || right~string
    -- todo : merge encodings info
    return s~text


::method "||op:right"
    use strict arg left
    left = self~class~convert(left)
    if .nil == left then return
    s = left~string || self~string
    -- todo : merge encodings info
    return s~text


::method "" -- abuttal
    use strict arg right
    right = self~class~convert(right)
    if .nil == right then return
    s = self~string || right~string
    -- todo : merge encodings info
    return s~text


::method "op:right" -- abuttal
    use strict arg left
    left = self~class~convert(left)
    if .nil == left then return
    s = left~string || self~string
    -- todo : merge encodings info
    return s~text


/******************************************************************************/
::class "Encodings" subclass List public

::method declare
    use strict arg string, encodingName, bfrom, blength

    if bfrom <= 0 then raise syntax 93.900 array("Encoding:s 'bfrom' must be > 0")
    if blength < 0 then raise syntax 93.900 array("Encodings: 'blength' must be >= 0")
    if bfrom > string~length then return -- no need to declare an encoding
    bto = bfrom + blength - 1
    if bto > string~length then bto = string~length -- adjust if needed

    -- The list of encodings is ordered from lower slice to upper slice
    -- Todo : replace the list by an array. I will never need to insert an encoding before the last one.
    previousIndex = .nil
    currentIndex = self~first
    do while currentIndex <> .nil
        currentEncoding = self~at(currentIndex)
        if bto < currentEncoding~bfrom then leave -- insert before current encoding
        if bfrom <= currentEncoding~bto then raise syntax 93.900 array("Encodings: overlapping not allowed")
        previousIndex = currentIndex
        currentIndex = self~next(currentIndex)
    end
    encodingClass = .Encoding~factory(encodingName)
    encoding = encodingClass~new(string, bfrom, bto)
    self~insert(encoding, previousIndex)


/******************************************************************************/
::class "Encoding" public

::method factory class
    use strict arg encodingName
    if "byte"~caselessEquals(encodingName) then return .ByteEncoding
    if "utf-8"~caselessEquals(encodingName) then return .UTF8Encoding
    if "utf8"~caselessEquals(encodingName) then return .UTF8Encoding
    if "utf-16"~caselessEquals(encodingName) then return .UTF16Encoding
    if "utf16"~caselessEquals(encodingName) then return .UTF16Encoding
    raise syntax 93.900 array("Encoding: '"encodingName"' is not supported")


::attribute bfrom get
::attribute bto get


::method init
    expose bfrom bto
    use strict arg bfrom, bto


::method string
    expose bfrom bto
    return self~class~id"["bfrom".."bto"]"


/******************************************************************************/
::class "ByteEncoding" subclass Encoding public

::method init
    use strict arg string, bfrom, bto
    self~init:super(bfrom, bto)
    -- No need to check the conformity : delegate to String


/******************************************************************************/
::class "UTF8Encoding" subclass Encoding public

::method init
    use strict arg string, bfrom, bto
    self~init:super(bfrom, bto)
    -- todo : check the conformity of string


/******************************************************************************/
::class "UTF16Encoding" subclass Encoding public

::method init
    use strict arg string, bfrom, bto
    self~init:super(bfrom, bto)
    -- todo : check the conformity of string

