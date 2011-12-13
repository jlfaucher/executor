pool = .queue~new
indexer = {::closure
    expose pool
    use strict arg value
    index = pool~index(value)
    if index == .nil then index = pool~append(value)
    return index
}

info = {::closure
    expose indexer
    use strict arg variableName, contextualSource
    rawExecutable = contextualSource~rawExecutable
    executable = contextualSource~executable
    say variableName "=" contextualSource":"indexer~(contextualSource~identityHash) "/" rawExecutable":"indexer~(rawExecutable~identityHash) "/" executable":"indexer~(executable~identityHash)
    return contextualSource
}

range = { use arg min, max ; return { ::closure expose min max ; use arg num ; return min <= num & num <= max }}
-- range's executable is already parsed
info~("range", range)
from5to8 = range~(5, 8)
info~("from5to8", from5to8)
from20to30 = range~(20, 30)
info~("from20to30", from20to30)
say from5to8~(6) -- 1       first execution : the closure is parsed
info~("from5to8", from5to8)
say from5to8~(9) -- 0       
info~("from5to8", from5to8)
say from20to30~(6) -- 0     first execution : the closure is parsed
info~("from20to30", from20to30)
say from20to30~(25) -- 1
info~("from20to30", from20to30)

say "--------------------------------------"

cs1 = {2 * arg(1)}
do i=1 to 5
    cs2 = {2 * arg(1)}
    info~("cs1", cs1)     -- same RexxContextualSource and same routine at each iteration.
    info~("cs2", cs2)     -- the RexxContextualSource is different at each iteration, but the routine is the same
    say 1 + info~('"return 2 * arg(1)"'){return 2 * arg(1)}~(i)
end


::requires "extension/extensions.cls"
