/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

--::requires "extension/extensions.cls"
--::options trace i

/******************************************************************************/
::class "StringHelpers" mixinclass Object public

::method quoted
    use strict arg quote='"'
    return quote || self~changeStr(quote, quote||quote)  || quote
