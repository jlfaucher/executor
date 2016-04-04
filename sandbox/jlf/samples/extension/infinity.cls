/*
http://functions.wolfram.com/Constants/DirectedInfinity/introductions/Symbols/ShowAll.html

For the moment, supports only
direction=-1    positive infinity
direction=0     negative infinity
direction=1     complex infinity

*/

.infinity~initialize

--::options trace i

::class "infinity" public

::attribute negative class          -- singleton
::attribute positive class          -- singleton
::attribute complex class           -- singleton

::method initialize class -- init not supported (can't instantiate itself or subclass from init)
    self~negative = self~new("The negative infinity", -1)
    self~positive = self~new("The positive infinity",  1)
    self~complex =  self~new("The complex infinity",   0)
    self~negative~opposite = self~positive
    self~positive~opposite = self~negative
    self~complex~opposite = self~complex

::attribute direction   -- -1 or 0 or 1 (0 if complex)
::attribute opposite

::method init
    use strict arg objectName, direction
    self~objectName = objectName
    self~direction = direction

::method sign
    -- return self~direction~sign
    if self~direction == 1 then return 1
    if self~direction == -1 then return -1
    -- other cases : todo, applicable ?

::method isPositive
    return self~direction == 1

::method isNegative
    return self~direction == -1

::method isComplex
    return self~direction == 0

::method "+"
    if arg(1,'o') then return self
    use strict arg right
    righti = right~request("infinity")
    if .nil <> righti then do
        if self~isComplex | righti~isComplex then return    -- complexInfinity + any infinity is undefined
        if self~sign <> righti~sign then return             -- infinity + -infinity is undefined
        return self                                         -- infinity + infinity = infinity
    end
    if right~datatype("N") then return self                 -- infinity + number = infinity

::method "-"
    if arg(1,'o') then return self~opposite
    use strict arg right
    righti = right~request("infinity")
    if .nil <> righti then do
        if self~isComplex | righti~isComplex then return    -- complexInfinity - any infinity is undefined
        if self~sign == righti~sign then return             -- infinity - infinity is undefined
        return self                                         -- infinity - -infinity = infinity
    end
    if right~datatype("N") then return self                 -- infinity - number = infinity

::method "*"
    use strict arg right
    righti = right~request("infinity")
    if .nil <> righti then do
        if self~isComplex | righti~isComplex then return .infinity~complex  -- complexInfinity * any infinity is a complexInfinity
        if self~sign <> righti~sign then return .infinity~negative          -- infinity * -infinity = -infinity
        return .infinity~positive                                           -- infinity * infinity = infinity
    end
    if right~datatype("N") then do
        if right < 0 then return self~opposite              -- infinity * -n = -infinity
        if right == 0 then return                           -- infinity ** 0 is undefined
        if right > 0 then return self                       -- infinity * n = infinity
    end

::method "/"
    use strict arg right
    righti = right~request("infinity")
    if .nil <> righti then return                           -- infinity / infinity is undefined
    if right~datatype("N") then do
        if right < 0 then return self~opposite              -- infinity / -n = -infinity
        if right == 0 then return .infinity~complex         -- infinity / 0 = complexInfinity
        if right > 0 then return self                       -- infinity / n = infinity
    end

::method "**"
    use strict arg right
    righti = right~request("infinity")
    if .nil <> righti then do
        if righti~isComplex then return                     -- infinity ^ complexInfinity is undefined
        if righti~isPositive then return .infinity~complex  -- infinity ^ infinity = complexInfinity
        if righti~isNegative then return 0                  -- infinity ** -infinity = 0
    end
    if right~datatype("N") then do
        if right < 0 then return 0                          -- infinity ** -n = 1 / (infinity ** n) = 0
        if right == 0 then return                           -- infinity ** 0 is undefined
        if right > 0 then do
            if self~isComplex then return self              -- complexInfinity ** n = complexInfinity
            if self~isPositive then return self             -- +infinity ** n = +infinity
            if self~isNegative then do
                if right~datatype("W") then do
                    if right // 2 == 0 then return self~opposite    -- -infinity ** evenWholeNumber = +infinity
                    return self                             -- -infinity ** oddWholeNumber = -infinity
                end
            end
        end
    end


/******************************************************************************/
/*
Add support for theses notations:
    +infinity
    -infinity
    infinity <operator> ...
    complexInfinity <operator> ...
    ... <operator> infinity
    ... <operator> complexInfinity
    ... <operator> (an infinity)
*/

::class "InfinityString" mixinclass Object public

::method makeInfinity
    string = self~changeStr(" ", "")~upper
    if string == "INFINITY" then return .infinity~positive
    if string == "COMPLEXINFINITY" then return .infinity~complex
    return .nil

::method "+op:left"
    -- For the moment, this message is sent only for the unary +
    use strict arg -- none
    left = self~request("infinity")
    if .nil <> left then return left -- unary +

::method "+op:right"
    use strict arg left
    lefti = left~request("infinity")
    if .nil <> lefti then do
        lefti~"+"(self) -- lefti + self
        if var("result") then return result
    end
    righti = self~request("infinity")
    if .nil <> righti then do
        righti~"+"(left) -- righti + left
        if var("result") then return result
    end

::method "-op:left"
    -- For the moment, this message is sent only for the unary -
    use strict arg -- none
    left = self~request("infinity")
    if .nil <> left then do
        left~"-" -- -left
        if var("result") then return result
    end


::method "-op:right"
    use strict arg left
    lefti = left~request("infinity")
    if .nil <> lefti then do
        lefti~"-"(self) -- lefti - self
        if var("result") then return result
    end
    righti = self~request("infinity")
    if .nil <> righti then do
        righti~"-"~"+"(left) -- -righti + left
        if var("result") then return result
    end


::method "*op:right"
    use strict arg left
    lefti = left~request("infinity")
    if .nil <> lefti then do
        lefti~"*"(self) -- lefti * self
        if var("result") then return result
    end
    righti = self~request("infinity")
    if .nil <> righti then do
        righti~"*"(left) -- righti * left
        if var("result") then return result
    end


::method "/op:right"
    use strict arg left
    lefti = left~request("infinity")
    if .nil <> lefti then do
        lefti~"/"(self) -- lefti / self
        if var("result") then return result
    end
    righti = self~request("infinity")
    if .nil <> righti then do
        if left~datatype("N") then return 0     -- number / infinity = 0
    end


::method "**op:right"
    use strict arg left
    lefti = left~request("complex")
    if .nil <> lefti then return lefti~"**"(self) -- lefti ** self
    righti = self~request("infinity")
    if .nil <> righti then do
        if righti~isComplex then return                                         -- any ** complexInfinity is undefined
        if left~datatype("N") then do
            if left == 0 then do
                if right~isPositive then return 0                               -- 0 ** +infinity = 0
                if right~isNegative then return .infinity~complex               -- 0 ** -infinity = complexInfinity
            end
            else if left == 1 then return                                       -- 1 ** infinity is undefined
            else do
                if right~isNegative then return 0                               -- number ** -infinity = 0
                if right~isPositive, left > 0 then return .infinity~positive    -- +number ** +infinity = +infinity
                if right~isPositive, left < 0 then return .infinity~negative    -- -number ** +infinity = -infinity
            end
        end
    end


/*
Others operators
*/

/* Not activated
::method "="
*/

::method "=op:right"

/* Not activated
::method "\="
*/

::method "\=op:right"

::method "<>"

::method "<>op:right"

/* Not activated
::method "=="
*/

::method "==op:right"

/* Not activated
::method "\=="
*/

::method "\==op:right"

/* Not activated
::method "><"
*/

::method "><op:right"

::method "\"
    use strict arg -- none, no binary version

::method ">"

::method ">op:right"

::method "<"

::method "<op:right"

::method ">="

::method ">=op:right"

::method "\<"

::method "\<op:right"

::method "<="

::method "<=op:right"

::method "\>"

::method "\>op:right"

::method ">>"

::method ">>op:right"

::method "<<"

::method "<<op:right"

::method ">>="

::method ">>=op:right"

::method "\<<"

::method "\<<op:right"

::method "<<="

::method "<<=op:right"

::method "\>>"

::method "\>>op:right"

::method "&"

::method "&op:right"

::method "|"

::method "|op:right"

::method "&&"

::method "&&op:right"

/*
Operators not needed for infinity

::method "%"

::method "%op:right"

::method "//"

::method "//op:right"

::method " "

::method " op:right"

::method "||"

::method "||op:right"

::method "" -- abuttal

::method "op:right" -- abuttal

*/
