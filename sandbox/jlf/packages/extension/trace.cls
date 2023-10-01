::extension RexxText        inherit RexxTextPrettyPrinter

::requires "extension/string.cls"   -- for escape3


/******************************************************************************/
::class "RexxTextPrettyPrinter" mixinclass Object private

-- TODO: Should honor .Encoding~defaultOutputEncoding
::method ppString
    use arg surroundByQuotes=.true -- keep it for the moment, still needed from rgf_util2
    use named arg ppOptions. = (.Stem~new), ppOptions.surroundByQuotes = (surroundByQuotes)

    pp = self~string
    if ppOptions.surroundByQuotes then pp = pp~quoted("'")

    -- Texts are prefixed with "T"
    pp = "T"pp
    -- Use 0xXX notation for escaped character
    return escape3(pp)


-- To see the string value instead of "a RexxText" in trace
-- Remember: defining defaultName had no effect
-- Remember: moved outside of text.cls to not trace these methods when tracing the package text.cls
::method objectName
    use strict arg -- none
    return self~ppString
