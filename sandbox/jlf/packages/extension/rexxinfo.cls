-- Compatibility with ooRexx 5

.environment~setentry(.RexxInfo~id, .RexxInfo)


::class RexxInfo public

::method architecture class
    parse version version
    if version~pos("32-bit") <> 0 then return 32
    if version~pos("64-bit") <> 0 then return 64
    return 0


::method internalDigits class
    if self~architecture == 32 then return 9
    else return 18
