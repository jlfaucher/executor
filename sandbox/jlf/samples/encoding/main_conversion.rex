prompt directory off
demo on

-- .Unicode~loadDerivedName(/*action*/ "load")=    -- load all the Unicode characters
-- .Unicode~loadNameAliases(/*action*/ "load")=    -- load the name aliases


--------------------------------------------------------------------------------
-- Supported encodings
--------------------------------------------------------------------------------

.encoding~supported~pipe(.sort "byindex" | .console "index.25" ":" "item")


--------------------------------------------------------------------------------
-- from Byte
--------------------------------------------------------------------------------

t = xrange("00"x, "7F"x)~text("Byte")           -- characters from 80x to FFx can't be converted to Unicode
< include_conversion.rex
call display_cache t


--------------------------------------------------------------------------------
-- from CP1252
--------------------------------------------------------------------------------

t = xrange("00"x, "FF"x)~text("CP1252")         -- all the characters from 00x to FFx can be converted to Unicode
< include_conversion.rex
call display_cache t


--------------------------------------------------------------------------------
-- from ISO-8859-1
--------------------------------------------------------------------------------

t = xrange("20"x, "7E"x, "A0"x, "FF"x)~text("ISO-8859-1")   -- characters from 00x to 1Fx and from 7Fx to 9F can't be converted to Unicode
< include_conversion.rex
call display_cache t
