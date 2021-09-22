.local["NOVALUE"] = .GlobalVariables

--::options trace i

-- When a variable has no value, the interpreter sends the message "NOVALUE" to
-- the object registered in .LOCAL under the name "NOVALUE" (un-documented feature,
-- see RexxActivation::novalueHandler)..
-- The class GlobalVariables is used to manage global variables like i, infinity, indeterminate.

::class "GlobalVariables" public

::method init class
    expose values
    values = .directory~new

::method declare class
    expose values
    use strict arg name, value
    name = name~upper
    if name == value then values~remove(name)
                     else values[name] = value

::method values class
    expose values
    return values

::method novalue class
    expose values
    use strict arg name
    -- no need to convert to uppercase, already done
    value = values[name]
    if .nil <> value then return value
