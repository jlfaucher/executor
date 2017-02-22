/*
http://functions.wolfram.com/Constants/DirectedInfinity/introductions/Symbols/ShowAll.html

For the moment, supports only
direction=-1    positive infinity
direction=0     negative infinity
direction=1     complex infinity

*/

.infinity~initialize

--::options trace i
::requires "extension/indeterminate.cls"


/******************************************************************************/
::class "infinity" public

::attribute negative class get         -- singleton
::attribute negative class set private

::attribute positive class get         -- singleton
::attribute positive class set private

::attribute complex class  get         -- singleton
::attribute complex class set private

::method initialize class -- init not supported (can't instantiate itself or subclass from init)
    self~negative = self~new("The negative infinity", -1)
    self~positive = self~new("The positive infinity",  1)
    self~complex =  self~new("The complex infinity",   0)

    self~negative~opposite = self~positive
    self~positive~opposite = self~negative
    self~complex~opposite = self~complex

    /*
        The lack of method makestring & string can have a HUGE impact on performances !
        Because the exception NOSTRING is raised each time the interpreter tries to convert an infinity to a number (->numberString() in NumberStringClass.cpp).
        During the creation of the exception, the method RexxActivity::generateProgramInformation is called.
        Depending on the current call stack, the file of messages may be read to build a message.
        If that happens, there is a severe performance degradation.
        All that for nothing because this exception NOSTRING is not trapped by default...

        rexx mytest.rex                 -- no performance degradation
        oorexxshell call mytest.rex     -- severe performance degradation

        Call stack when running from ooRexxShell:
        RexxActivation::createStackFrame()  FRAME_INTERPRET
        RexxActivation::createStackFrame()  FRAME_INTERNAL_CALL
        RexxActivation::createStackFrame()  FRAME_ROUTINE
        InternalActivationFrame::createStackFrame
            RexxString *message = activity->buildMessage(Message_Translations_compiled_method_invocation, info) // this is the root cause of the performance degradation
        FRAME_PROGRAM
    */

    --return
    self~negative~setMethod("makestring", "return self~objectName", "OBJECT")
    self~positive~setMethod("makestring", "return self~objectName", "OBJECT")
    self~complex~setMethod("makestring", "return self~objectName", "OBJECT")

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

-- ::method " "

-- ::method " op:right"

-- ::method "||"

-- ::method "||op:right"

-- ::method "" -- abuttal

-- ::method "op:right" -- abuttal

::method "+"
    if arg(1,'o') then return self
    use strict arg right, righti = (right~request("infinity"))
    if .nil <> righti then do
        if self~isComplex | righti~isComplex then return .indeterminate~value   -- complexInfinity + any infinity is undefined
        if self~sign <> righti~sign then return .indeterminate~value            -- infinity + -infinity is undefined
        return self                                                             -- infinity + infinity = infinity
    end
    if right~isA(.String), right~datatype("N") then return self                 -- infinity + number = infinity

::method "+op:right"
    --use strict arg left, lefti=(left~request("infinity"))
    forward message "+"                                     -- "+" is commutative : left+self == self+left

::method "-"
    if arg(1,'o') then return self~opposite
    use strict arg right, righti = (right~request("infinity"))
    if .nil <> righti then do
        if self~isComplex | righti~isComplex then return .indeterminate~value   -- complexInfinity - any infinity is undefined
        if self~sign == righti~sign then return .indeterminate~value            -- infinity - infinity is undefined
        return self                                                             -- infinity - -infinity = infinity
    end
    if right~isA(.String), right~datatype("N") then return self                 -- infinity - number = infinity

::method "-op:right"
    --use strict arg left, lefti=(left~request("infinity"))
    forward to (self~"-") message "+"                       -- left-self == -self+left

::method "*"
    use strict arg right, righti = (right~request("infinity"))
    if .nil <> righti then do
        if self~isComplex | righti~isComplex then return .infinity~complex  -- complexInfinity * any infinity is a complexInfinity
        if self~sign <> righti~sign then return .infinity~negative          -- infinity * -infinity = -infinity
        return .infinity~positive                                           -- infinity * infinity = infinity
    end
    if right~isA(.String), right~datatype("N") then do
        if right < 0 then return self~opposite              -- infinity * -n = -infinity
        if right == 0 then return .indeterminate~value      -- infinity ** 0 is undefined
        if right > 0 then return self                       -- infinity * n = infinity
    end

::method "*op:right"
    --use strict arg left, lefti=(left~request("infinity"))
    forward message "*"                                     -- "*" is commutative : left*self == self*left

::method "/"
    use strict arg right, righti = (right~request("infinity"))
    if .nil <> righti then return .indeterminate~value      -- infinity / infinity is undefined
    if right~isA(.String), right~datatype("N") then do
        if right < 0 then return self~opposite              -- infinity / -n = -infinity
        if right == 0 then return .infinity~complex         -- infinity / 0 = complexInfinity
        if right > 0 then return self                       -- infinity / n = infinity
    end

::method "/op:right"
    use strict arg left, lefti=(left~request("infinity"))
    if .nil <> lefti then forward to (lefti) message "/" array (self)   -- lefti / self
    if left~isA(.String), left~datatype("N") then return 0  -- number / infinity = 0

-- ::method "%"

-- ::method "%op:right"

-- ::method "//"

-- ::method "//op:right"

::method "**"
    use strict arg right, righti = (right~request("infinity"))
    if .nil <> righti then do
        if righti~isComplex then return .indeterminate~value        -- infinity ^ complexInfinity is undefined
        if righti~isPositive then return .infinity~complex          -- infinity ^ infinity = complexInfinity
        if righti~isNegative then return 0                          -- infinity ** -infinity = 0
    end
    if right~isA(.String), right~datatype("N") then do
        if right < 0 then return 0                                  -- infinity ** -n = 1 / (infinity ** n) = 0
        if right == 0 then return .indeterminate~value              -- infinity ** 0 is undefined
        if right > 0 then do
            if self~isComplex then return self                      -- complexInfinity ** n = complexInfinity
            if self~isPositive then return self                     -- +infinity ** n = +infinity
            if self~isNegative then do
                if right~datatype("W") then do
                    if right // 2 == 0 then return self~opposite    -- -infinity ** evenWholeNumber = +infinity
                    return self                                     -- -infinity ** oddWholeNumber = -infinity
                end
            end
        end
    end

::method "**op:right"
    use strict arg left, lefti=(left~request("infinity"))
    if .nil <> lefti then forward to (lefti) message "**" array (self)      -- lefti ** self
    if self~isComplex then return .indeterminate~value                      -- any ** complexInfinity is undefined
    if left~isA(.String), left~datatype("N") then do
        if left == 0 then do
            if self~isPositive then return 0                                -- 0 ** +infinity = 0
            if self~isNegative then return .infinity~complex                -- 0 ** -infinity = complexInfinity
        end
        else if left == 1 then return .indeterminate~value                  -- 1 ** infinity is undefined
        else do
            if self~isNegative then return 0                                -- number ** -infinity = 0
            if self~isPositive, left > 0 then return .infinity~positive     -- +number ** +infinity = +infinity
            if self~isPositive, left < 0 then return .infinity~negative     -- -number ** +infinity = -infinity
        end
    end

-- ::method "="

-- ::method "=op:right"

-- ::method "\="

-- ::method "\=op:right"

-- ::method "<>"

-- ::method "<>op:right"

::method "=="
    use strict arg right, righti = (right~request("infinity"))
    if .nil <> righti then return self~direction == righti~direction
    return .false

-- ::method "==op:right"

::method "\=="
    use strict arg right, righti = (right~request("infinity"))
    if .nil == righti then return .true
    return self~direction <> righti~direction

-- ::method "\==op:right"

::method "><"
    use strict arg right, righti = (right~request("infinity"))
    if .nil == righti then return .true
    return self~direction <> righti~direction

-- ::method "><op:right"

-- ::method "\"

::method ">"
    use strict arg right, righti = (right~request("infinity"))
    if .nil <> righti then do
        if self~isComplex | righti~isComplex then return -- todo
        if self~isNegative then return .false
        if self~isPositive then return righti~isNegative
    end
    if right~isA(.String), right~datatype("N") then do
        if self~isNegative then return .false
        if self~isPositive then return .true
    end

::method ">op:right"
    use strict arg left, lefti=(left~request("infinity"))
    if .nil <> lefti then forward to (lefti) message ">" array (self)       -- lefti > self
    if left~isA(.String), left~datatype("N") then do
        if self~isNegative then return .true
        if self~isPositive then return .false
    end

::method "<"
    use strict arg right, righti = (right~request("infinity"))
    if .nil <> righti then do
        if self~isComplex | righti~isComplex then return -- todo
        if self~isNegative then return righti~isPositive
        if self~isPositive then return .false
    end
    if right~isA(.String), right~datatype("N") then do
        if self~isNegative then return .true
        if self~isPositive then return .false
    end

::method "<op:right"
    use strict arg left, lefti=(left~request("infinity"))
    if .nil <> lefti then forward to (lefti) message "<" array (self)       -- lefti < self
    if left~isA(.String), left~datatype("N") then do
        if self~isNegative then return .false
        if self~isPositive then return .true
    end

-- ::method ">="

-- ::method ">=op:right"

-- ::method "\<"

-- ::method "\<op:right"

-- ::method "<="

-- ::method "<=op:right"

-- ::method "\>"

-- ::method "\>op:right"

-- ::method ">>"

-- ::method ">>op:right"

-- ::method "<<"

-- ::method "<<op:right"

-- ::method ">>="

-- ::method ">>=op:right"

-- ::method "\<<"

-- ::method "\<<op:right"

-- ::method "<<="

-- ::method "<<=op:right"

-- ::method "\>>"

-- ::method "\>>op:right"

-- ::method "&"

-- ::method "&op:right"

-- ::method "|"

-- ::method "|op:right"

-- ::method "&&"

-- ::method "&&op:right"


/******************************************************************************/
::requires "extension/novalue.cls"

::extension novalue

::method infinity class
    return .infinity~positive

::method complexInfinity class
    return .infinity~complex
