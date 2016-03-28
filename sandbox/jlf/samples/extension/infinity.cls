::class infinity public

::attribute negative class -- singleton
::attribute positive class -- singleton

::method init class
    self~negative = self~new
    self~positive = self~new

::method "+"
    if arg(1,'o') then return self
    use strict arg right
    right = right~requestInfinity
    if right == .nil then return self -- infinity + not infinity = infinity
    if self <> right then return -- infinity + -infinity is undefined
    return self

::method opposite
    if self == self~negative then return self~positive
    if self == self~positive then return self~negative

::method "-"
    if arg(1,'o') then return self~opposite
    use strict arg right
    right = right~requestInfinity
    if right == .nil then return self -- infinity + not infinity = infinity
    if self <> right then return -- infinity + -infinity is undefined
    return self

::method "*"
    use strict arg right
    return self

::method "/"
    use strict arg right
    if right~requestInfinity <> .nil then return -- infinity / infinity is undefined
    return self


::extension string
::method makeInfinity
if self~caselessEquals("infinity") then return .infinity~new
return .nil
