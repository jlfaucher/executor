/******************************************************************************/
::class "BitKey" public -- private


::method init class
    expose powerOfTwo
    -- powerOfTwo[i] = 2 ** (i-1)
    -- 2 **       0  1  2  3  4   5   6   7    8    9
    powerOfTwo = (1, 2, 4, 8, 16, 32, 64, 128, 256, 512)
    self~init:super


::method bitPosMask class
    expose powerOfTwo
    use strict arg bitPos -- range 0 to (powerOfTwo~size - 1)
    dmask = powerOfTwo[bitpos + 1]
    return dmask~d2c -- MUST be ~d2c to let apply bitAnd, bitOr


::method bitFlagsMask class
    -- pre-condition:  each argument is 0 or not 0 or omitted
    -- post-condition: result = arg(1) + arg(2) * 2 + arg(3) * 4 + arg(4) * 8 ...
    expose powerOfTwo
    dmask = 0
    do i=1 to arg()
        if arg(i, "e") then dmask += (arg(i) \== 0) * powerOfTwo[i] -- (2 ** (i - 1))
    end
    return dmask~d2c -- MUST be ~d2c to let apply bitAnd, bitOr


/******************************************************************************/
::class "CachedStrings" mixinclass Object public -- private

/*
A same text can be transformed in several strings, each described by a set of flags.
This set of flags is used as a key to store the corresponding string in a cache
(byte encoded representation).
Example of set of flags:
    Assuming that NFC is bit 0, casefold is bit 4, stripMark is bit 6:
    NFC = 1                                     01x     00000001        key = '1'x
    NFC casefold = 1 + 16 = 17                  11x     00010001        key = '11'x
    NFC casefold stripMark = 1 + 16 + 32 = 49   31x     00110001        key = '31'x
    etc...

    Cached strings:
    stringsCache at '1'x    = NFC
    stringsCache at '11'x   = NFC casefold
    stringsCache at '31'x   = NFC casefold stripMark
*/

::attribute stringsCache get -- for tuning/display only

::method init
    expose stringsCache assignedBitFlags bitFlags

    stringsCache = .Directory~new
    -- Usage: if the flag is set then val = flag else val = -1 (see bitFlag)
    assignedBitFlags = 0~d2c
    bitFlags = 0~d2c
    self~init:super


::method bitFlag private
    -- If the bit is assigned then value = flag else value = -1

    -- bitPos            ...   7   6   5   4   3   2   1   0
    -- mask              ... 128  64  32  16   8   4   2   1
    -- assignedBitFlags     .  1   0   0   0   1   1   0   0
    -- bitFlags             .  1   0   0   0   0   1   0   0
    -- value                .  1  -1  -1  -1   0   1  -1  -1

    expose assignedBitFlags bitFlags
    use strict arg bitPos
    mask = .BitKey~bitPosMask(bitPos)
    if assignedBitFlags~bitand(mask) == mask then return bitFlags~bitand(mask) == mask
    return -1   -- unknown


::method bitFlagsAllTrue private
    -- This method return .true if all the bits selected by the mask have value 1
    expose assignedBitFlags bitFlags
    use strict arg mask -- byte encoded mask 1001...
    if assignedBitFlags~bitand(mask) == mask then return bitFlags~bitand(mask) == mask
    return .false


::method setBitFlag private
    expose assignedBitFlags bitFlags
    use strict arg bitPos
    mask = .BitKey~bitPosMask(bitPos)
    assignedBitFlags = assignedBitFlags~bitor(mask) -- this bit has a value
    bitFlags = bitFlags~bitor(mask)                 -- this bit has the value 1


::method setBitFlags private
    expose assignedBitFlags bitFlags
    use strict arg mask
    assignedBitFlags = assignedBitFlags~bitor(mask) -- all these bits have a value
    bitFlags = bitFlags~bitor(mask)                 -- all these bits have the value 1


::method getCachedString private
    expose stringsCache
    use strict arg key
    return stringsCache~at(key) -- .nil if not found


::method cacheString private
    expose stringsCache
    use strict arg key, string
    stringsCache~put(string, key)
