.indeterminate~initialize

--::options trace i

/******************************************************************************/
::class "indeterminate" public

::attribute value class get         -- singleton
::attribute value class set private

::method initialize class -- init not supported (can't instantiate itself or subclass from init)
    self~value = self~new("Indeterminate")
    self~value~setMethod("makestring", "return 'INDETERMINATE'", "OBJECT")

::method init
    use strict arg objectName
    self~objectName = objectName

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


/******************************************************************************/
::class "IndeterminateString" mixinclass Object public

/*
Add support for theses notations:
    +indeterminate
    -indeterminate
    indeterminate <operator> ...
    ... <operator> indeterminate
*/

::method makeIndeterminate
    string = self~strip~upper
    if string == "INDETERMINATE" then return .indeterminate~value
    return .nil

-- ::method " op:right"

-- ::method "||op:right"

-- ::method "op:right" -- abuttal

::method "+op:left"
    -- For the moment, this message is sent only for the unary +
    use strict arg -- none
    left = self~request("indeterminate")
    if .nil <> left then return .indeterminate~value

::method "+op:right"
    use strict arg left, lefti = (left~request("indeterminate"))
    if .nil <> lefti then return .indeterminate~value
    righti = self~request("indeterminate")
    if .nil <> righti then return .indeterminate~value

::method "-op:left"
    -- For the moment, this message is sent only for the unary -
    use strict arg -- none
    left = self~request("indeterminate")
    if .nil <> left then return .indeterminate~value

::method "-op:right"
    use strict arg left, lefti = (left~request("indeterminate"))
    if .nil <> lefti then return .indeterminate~value
    righti = self~request("indeterminate")
    if .nil <> righti then return .indeterminate~value

::method "*op:right"
    use strict arg left, lefti = (left~request("indeterminate"))
    if .nil <> lefti then return .indeterminate~value
    righti = self~request("indeterminate")
    if .nil <> righti then return .indeterminate~value

::method "/op:right"
    use strict arg left, lefti = (left~request("indeterminate"))
    if .nil <> lefti then return .indeterminate~value
    righti = self~request("indeterminate")
    if .nil <> righti then return .indeterminate~value

::method "%op:right"
    use strict arg left, lefti = (left~request("indeterminate"))
    if .nil <> lefti then return .indeterminate~value
    righti = self~request("indeterminate")
    if .nil <> righti then return .indeterminate~value

::method "//op:right"
    use strict arg left, lefti = (left~request("indeterminate"))
    if .nil <> lefti then return .indeterminate~value
    righti = self~request("indeterminate")
    if .nil <> righti then return .indeterminate~value

::method "**op:right"
    use strict arg left, lefti = (left~request("indeterminate"))
    if .nil <> lefti then return .indeterminate~value
    righti = self~request("indeterminate")
    if .nil <> righti then return .indeterminate~value

::method "=op:right"

::method "\=op:right"

::method "<>op:right"

::method "==op:right"

::method "\==op:right"

::method "><op:right"

::method ">op:right"
    use strict arg left, lefti = (left~request("indeterminate"))
    if .nil <> lefti then return .indeterminate~value
    righti = self~request("indeterminate")
    if .nil <> righti then return .indeterminate~value

::method "<op:right"
    use strict arg left, lefti = (left~request("indeterminate"))
    if .nil <> lefti then return .indeterminate~value
    righti = self~request("indeterminate")
    if .nil <> righti then return .indeterminate~value

::method ">=op:right"
    use strict arg left, lefti = (left~request("indeterminate"))
    if .nil <> lefti then return .indeterminate~value
    righti = self~request("indeterminate")
    if .nil <> righti then return .indeterminate~value

::method "\<op:right"
    use strict arg left, lefti = (left~request("indeterminate"))
    if .nil <> lefti then return .indeterminate~value
    righti = self~request("indeterminate")
    if .nil <> righti then return .indeterminate~value

::method "<=op:right"
    use strict arg left, lefti = (left~request("indeterminate"))
    if .nil <> lefti then return .indeterminate~value
    righti = self~request("indeterminate")
    if .nil <> righti then return .indeterminate~value

::method "\>op:right"
    use strict arg left, lefti = (left~request("indeterminate"))
    if .nil <> lefti then return .indeterminate~value
    righti = self~request("indeterminate")
    if .nil <> righti then return .indeterminate~value

::method ">>op:right"
    use strict arg left, lefti = (left~request("indeterminate"))
    if .nil <> lefti then return .indeterminate~value
    righti = self~request("indeterminate")
    if .nil <> righti then return .indeterminate~value

::method "<<op:right"
    use strict arg left, lefti = (left~request("indeterminate"))
    if .nil <> lefti then return .indeterminate~value
    righti = self~request("indeterminate")
    if .nil <> righti then return .indeterminate~value

::method ">>=op:right"
    use strict arg left, lefti = (left~request("indeterminate"))
    if .nil <> lefti then return .indeterminate~value
    righti = self~request("indeterminate")
    if .nil <> righti then return .indeterminate~value

::method "\<<op:right"
    use strict arg left, lefti = (left~request("indeterminate"))
    if .nil <> lefti then return .indeterminate~value
    righti = self~request("indeterminate")
    if .nil <> righti then return .indeterminate~value

::method "<<=op:right"
    use strict arg left, lefti = (left~request("indeterminate"))
    if .nil <> lefti then return .indeterminate~value
    righti = self~request("indeterminate")
    if .nil <> righti then return .indeterminate~value

::method "\>>op:right"
    use strict arg left, lefti = (left~request("indeterminate"))
    if .nil <> lefti then return .indeterminate~value
    righti = self~request("indeterminate")
    if .nil <> righti then return .indeterminate~value

-- ::method "&op:right"

-- ::method "|op:right"

-- ::method "&&op:right"
