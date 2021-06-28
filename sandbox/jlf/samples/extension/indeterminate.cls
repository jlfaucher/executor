.indeterminate~initialize

--::options trace i
::requires "extension/novalue.cls"


/******************************************************************************/
::class "indeterminate" public

::attribute value class get         -- singleton
::attribute value class set private

::method initialize class -- init not supported (can't instantiate itself or subclass from init)
    self~value = self~new("The indeterminate value")
    /*
    -- Don't ask me why, but when using setMethod to add makestring, the method ppString is no longer found.
    -- No problem if I use ::method makestring.
    self~value~setMethod("makestring", "return self~objectName", "OBJECT")
    */
    .GlobalVariables~declare("INDETERMINATE", self~value)

::method init
    use strict arg objectName
    self~objectName = objectName

::method makestring
    return self~objectName

-- ::method " "

-- ::method " op:right"

-- ::method "||"

-- ::method "||op:right"

-- ::method "" -- abuttal

-- ::method "op:right" -- abuttal

::method "+"
    return .indeterminate~value

::method "+op:right"
    return .indeterminate~value

::method "-"
    return .indeterminate~value

::method "-op:right"
    return .indeterminate~value

::method "*"
    return .indeterminate~value

::method "*op:right"
    return .indeterminate~value

::method "/"
    return .indeterminate~value

::method "/op:right"
    return .indeterminate~value

::method "%"
    return .indeterminate~value

::method "%op:right"
    return .indeterminate~value

::method "//"
    return .indeterminate~value

::method "//op:right"
    return .indeterminate~value

::method "**"
    return .indeterminate~value

::method "**op:right"
    return .indeterminate~value

-- ::method "="

-- ::method "=op:right"

-- ::method "\="

-- ::method "\=op:right"

-- ::method "<>"

-- ::method "<>op:right"

-- ::method "=="

-- ::method "==op:right"

-- ::method "\=="

-- ::method "\==op:right"

-- ::method "><"

-- ::method "><op:right"

-- ::method "\"

::method ">"
    return .indeterminate~value

::method ">op:right"
    return .indeterminate~value

::method "<"
    return .indeterminate~value

::method "<op:right"
    return .indeterminate~value

::method ">="
    return .indeterminate~value

::method ">=op:right"
    return .indeterminate~value

::method "\<"
    return .indeterminate~value

::method "\<op:right"
    return .indeterminate~value

::method "<="
    return .indeterminate~value

::method "<=op:right"
    return .indeterminate~value

::method "\>"
    return .indeterminate~value

::method "\>op:right"
    return .indeterminate~value

::method ">>"
    return .indeterminate~value

::method ">>op:right"
    return .indeterminate~value

::method "<<"
    return .indeterminate~value

::method "<<op:right"
    return .indeterminate~value

::method ">>="
    return .indeterminate~value

::method ">>=op:right"
    return .indeterminate~value

::method "\<<"
    return .indeterminate~value

::method "\<<op:right"
    return .indeterminate~value

::method "<<="
    return .indeterminate~value

::method "<<=op:right"
    return .indeterminate~value

::method "\>>"
    return .indeterminate~value

::method "\>>op:right"
    return .indeterminate~value

::method "&"
    return .indeterminate~value

::method "&op:right"
    return .indeterminate~value

::method "|"
    return .indeterminate~value

::method "|op:right"
    return .indeterminate~value

::method "&&"
    return .indeterminate~value

::method "&&op:right"
    return .indeterminate~value
