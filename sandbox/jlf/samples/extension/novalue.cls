.local["NOVALUE"] = .novalue

-- When a variable has no value, the interpreter sends the message "NOVALUE" to this class
-- (because this class is registered in .LOCAL under the name "NOVALUE").
-- This class is used to manage special variable like i, infinity, indeterminate.
-- Each special variable is added by extension.
::class novalue public

::method novalue class
    use strict arg name
    forward message (name)

::method unknown class
    -- By default, returns nothing : delegate to the interpreter.
